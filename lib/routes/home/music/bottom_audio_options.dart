import "dart:io";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:url_launcher/url_launcher_string.dart";

import "../../../api/vk/shared.dart";
import "../../../main.dart";
import "../../../provider/download_manager.dart";
import "../../../provider/l18n.dart";
import "../../../provider/playlists.dart";
import "../../../provider/preferences.dart";
import "../../../provider/user.dart";
import "../../../services/audio_player.dart";
import "../../../services/download_manager.dart";
import "../../../services/logger.dart";
import "../../../widgets/audio_track.dart";
import "../../../widgets/dialogs.dart";
import "../music.dart";
import "bottom_dialogs/deezer_thumbs.dart";
import "bottom_dialogs/info_edit.dart";

/// Виджет для [BottomAudioOptionsDialog], отображающий [CircularProgressIndicator] во время загрузки.
class _LoadingProgressIndicator extends StatelessWidget {
  const _LoadingProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator.adaptive(
        strokeWidth: 2.5,
      ),
    );
  }
}

/// Диалог, появляющийся снизу экрана, дающий пользователю действия над выбранным треком.
///
/// Пример использования:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (BuildContext context) => const BottomAudioOptionsDialog(...),
/// ),
/// ```
class BottomAudioOptionsDialog extends HookConsumerWidget {
  static final AppLogger logger = getLogger("BottomAudioOptionsDialog");

  /// Трек типа [ExtendedAudio], над которым производится манипуляция.
  final ExtendedAudio audio;

  /// Плейлист, в котором находится данный трек.
  final ExtendedPlaylist playlist;

  const BottomAudioOptionsDialog({
    super.key,
    required this.audio,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newPlaylist =
        ref.watch(getPlaylistProvider(playlist.ownerID, playlist.id));
    ExtendedAudio newAudio = newPlaylist?.audios?.firstWhereOrNull(
          (element) =>
              element.ownerID == audio.ownerID && element.id == audio.id,
        ) ??
        audio;

    final l18n = ref.watch(l18nProvider);

    final geniusUrl = useMemoized(
      () {
        final titleAndArtist = "${newAudio.artist}-${newAudio.title}"
            .replaceAll(RegExp(r"[^\w\s-]"), "")
            .replaceAll(RegExp(r"\s+"), "-")
            .toLowerCase();

        return Uri.encodeFull(
          "https://genius.com/$titleAndArtist-lyrics",
        );
      },
    );
    final hasGeniusInfo = useState<bool?>(null);
    useEffect(
      () {
        if (!connectivityManager.hasConnection) return;

        dio.head(geniusUrl).then(
          (response) {
            if (!context.mounted) return;

            hasGeniusInfo.value = response.statusCode == 200;
          },
        );

        return null;
      },
      [],
    );

    final isTogglingLikeState = useState(false);

    void onDetailsEditTap() {
      if (!networkRequiredDialog(ref, context)) return;

      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (BuildContext context) => TrackInfoEditDialog(
          audio: newAudio,
          playlist: playlist,
        ),
      );
    }

    void onAddAsFavoritesTap() async {
      if (!networkRequiredDialog(ref, context)) return;

      isTogglingLikeState.value = true;
      try {
        await toggleTrackLike(
          player.ref,
          newAudio,
        );
      } on VKAPIException catch (error, stackTrace) {
        if (!context.mounted) return;

        if (error.errorCode == 15) {
          showErrorDialog(
            context,
            description: l18n.music_likeRestoreTooLate,
          );

          return;
        }

        showLogErrorDialog(
          "Error while restoring audio:",
          error,
          stackTrace,
          logger,
          context,
        );
      } catch (error, stackTrace) {
        showLogErrorDialog(
          "Error while toggling like state:",
          error,
          stackTrace,
          logger,
          // ignore: use_build_context_synchronously
          context,
        );
      } finally {}

      if (!context.mounted) return;

      isTogglingLikeState.value = false;
    }

    void addToPlaylistTap() {
      if (!networkRequiredDialog(ref, context)) return;

      showWipDialog(context);
    }

    void onAddToQueueTap() async {
      // FIXME: Этот метод не работает, если включён shuffle, и это косяк на стороне just_audio.
      await player.addNextToQueue(newAudio);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l18n.general_addedToQueue,
          ),
          duration: const Duration(
            seconds: 3,
          ),
        ),
      );

      context.pop();
    }

    void onGeniusSearchTap() async {
      if (hasGeniusInfo.value == null) {
        throw Exception("Genius info isn't loaded yet");
      }

      Navigator.of(context).pop();

      await launchUrlString(geniusUrl);
    }

    void onCacheTrackTap() async {
      if (!networkRequiredDialog(ref, context)) return;

      final preferences = ref.read(preferencesProvider);
      final playlists = ref.read(playlistsProvider.notifier);
      Navigator.of(context).pop();

      try {
        newAudio = await PlaylistCacheDownloadItem.downloadWithMetadata(
              ref.read(downloadManagerProvider.notifier).ref,
              playlist,
              newAudio,
              deezerThumbnails: preferences.deezerThumbnails,
              lrcLibLyricsEnabled: preferences.lrcLibEnabled,
            ) ??
            newAudio;

        await playlists.updatePlaylist(
          playlist.basicCopyWith(
            audiosToUpdate: [newAudio],
          ),
          saveInDB: true,
        );
      } catch (error, stackTrace) {
        showLogErrorDialog(
          "Manual media caching error: ",
          error,
          stackTrace,
          logger,
          // ignore: use_build_context_synchronously
          context,
        );

        return;
      }

      if (!context.mounted) return;
    }

    void onDeezerThumbsTap() {
      if (!networkRequiredDialog(ref, context)) return;

      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return TrackThumbnailEditDialog(
            audio: newAudio,
            playlist: playlist,
          );
        },
      );
    }

    void onReplaceFromYoutubeTap() {
      if (!networkRequiredDialog(ref, context)) return;

      showWipDialog(context);
    }

    void onTrackDetailsTap() {
      if (!networkRequiredDialog(ref, context)) return;

      showWipDialog(context);
    }

    return DraggableScrollableSheet(
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return Container(
          width: 500,
          height: 300,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          child: ListView(
            controller: controller,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 4,
                  right: 4,
                  top: 16,
                ),
                child: Column(
                  children: [
                    // Трек.
                    AudioTrackTile(
                      audio: newAudio,
                      allowTextSelection: true,
                    ),
                    const Gap(8),

                    // Разделитель.
                    const Divider(),
                    const Gap(8),
                  ],
                ),
              ),

              // Редактировать данные трека.
              ListTile(
                leading: const Icon(
                  Icons.edit,
                ),
                title: Text(
                  l18n.music_detailsEditTitle,
                ),
                onTap: onDetailsEditTap,
              ),

              // Добавить или удалить как "любимый" трек.
              ListTile(
                leading: isTogglingLikeState.value
                    ? const _LoadingProgressIndicator()
                    : Icon(
                        newAudio.isLiked
                            ? Icons.favorite
                            : Icons.favorite_outline,
                      ),
                enabled: !isTogglingLikeState.value,
                title: Text(
                  newAudio.isLiked
                      ? l18n.music_detailsRemoveFromFavoritesTitle
                      : l18n.music_detailsAddAsFavoritesTitle,
                ),
                onTap: onAddAsFavoritesTap,
              ),

              // TODO: Добавить в плейлист...
              if (kDebugMode)
                ListTile(
                  leading: const Icon(
                    Icons.playlist_add,
                  ),
                  title: Text(
                    l18n.music_detailsAddToPlaylistTitle,
                  ),
                  onTap: addToPlaylistTap,
                ),

              // TODO: Добавить в очередь.
              if (kDebugMode)
                ListTile(
                  leading: const Icon(
                    Icons.queue_music,
                  ),
                  title: Text(
                    l18n.music_detailsPlayNextTitle,
                  ),
                  enabled: newAudio.canPlay,
                  onTap: onAddToQueueTap,
                ),

              // Поиск по Genius.
              ListTile(
                leading: hasGeniusInfo.value == null
                    ? const _LoadingProgressIndicator()
                    : const Icon(
                        Icons.lyrics_outlined,
                      ),
                title: Text(
                  l18n.music_detailsGeniusSearchTitle,
                ),
                subtitle: Text(
                  l18n.music_detailsGeniusSearchDescription,
                ),
                enabled: hasGeniusInfo.value ?? false,
                onTap: onGeniusSearchTap,
              ),

              // Кэшировать этот трек.
              ListTile(
                leading: const Icon(
                  Icons.download,
                ),
                title: Text(
                  l18n.music_detailsCacheTrackTitle,
                ),
                subtitle: Text(
                  l18n.music_detailsCacheTrackDescription,
                ),
                enabled:
                    !newAudio.isRestricted && !(newAudio.isCached ?? false),
                onTap: onCacheTrackTap,
              ),

              // Заменить обложку.
              ListTile(
                leading: const Icon(
                  Icons.image_search,
                ),
                title: Text(
                  l18n.music_detailsSetThumbnailTitle,
                ),
                subtitle: Text(
                  l18n.music_detailsSetThumbnailDescription,
                ),
                onTap: onDeezerThumbsTap,
              ),

              // TODO: Перезалить с Youtube.
              if (kDebugMode)
                ListTile(
                  leading: const Icon(
                    Icons.rotate_left,
                  ),
                  title: Text(
                    l18n.music_detailsReuploadFromYoutubeTitle,
                  ),
                  subtitle: Text(
                    l18n.music_detailsReuploadFromYoutubeDescription,
                  ),
                  onTap: onReplaceFromYoutubeTap,
                ),

              // TODO: Детали трека.
              if (kDebugMode)
                ListTile(
                  leading: const Icon(
                    Icons.info,
                  ),
                  title: Text(
                    l18n.music_detailsTrackDetailsTitle,
                  ),
                  onTap: onTrackDetailsTap,
                ),

              // Debug-опции.
              if (kDebugMode) ...[
                // Скопировать ID трека.
                ListTile(
                  leading: const Icon(
                    Icons.link,
                  ),
                  title: const Text(
                    "Copy mediaKey",
                  ),
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: newAudio.mediaKey,
                      ),
                    );

                    Navigator.of(context).pop();
                  },
                ),

                // Открыть папку с треком.
                if (Platform.isWindows)
                  ListTile(
                    leading: const Icon(
                      Icons.folder_open,
                    ),
                    title: const Text(
                      "Open folder with audio",
                    ),
                    enabled: newAudio.isCached ?? false,
                    onTap: () async {
                      Navigator.of(context).pop();

                      final File path =
                          await CachedStreamAudioSource.getCachedAudioByKey(
                        newAudio.mediaKey,
                      );
                      await Process.run(
                        "explorer.exe",
                        ["/select,", path.path],
                      );
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
