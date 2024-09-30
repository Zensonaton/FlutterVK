import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:url_launcher/url_launcher_string.dart";

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
import "bottom_dialogs/deezer_thumbs.dart";
import "bottom_dialogs/info_edit.dart";

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
    final l18n = ref.watch(l18nProvider);

    final geniusUrl = useMemoized(
      () {
        final titleAndArtist = "${audio.artist}-${audio.title}"
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

    void onDetailsEditTap() {
      if (!networkRequiredDialog(ref, context)) return;

      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (BuildContext context) => TrackInfoEditDialog(
          audio: audio,
          playlist: playlist,
        ),
      );
    }

    void onRemoveFromPlaylistTap() {
      if (!networkRequiredDialog(ref, context)) return;

      showWipDialog(context);
    }

    void onAddToOtherPlaylistTap() {
      if (!networkRequiredDialog(ref, context)) return;

      showWipDialog(context);
    }

    void onAddToQueueTap() async {
      // FIXME: Этот метод не работает, если включён shuffle, и это косяк на стороне just_audio.
      await player.addNextToQueue(
        audio,
      );

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
      assert(
        hasGeniusInfo.value != null,
        "Genius info isn't loaded yet",
      );

      Navigator.of(context).pop();

      await launchUrlString(geniusUrl);
    }

    void onCacheTrackTap() async {
      if (!networkRequiredDialog(ref, context)) return;

      final preferences = ref.read(preferencesProvider);
      final playlists = ref.read(playlistsProvider.notifier);
      Navigator.of(context).pop();

      try {
        final newAudio = await PlaylistCacheDownloadItem.downloadWithMetadata(
          ref.read(downloadManagerProvider.notifier).ref,
          playlist,
          audio,
          deezerThumbnails: preferences.deezerThumbnails,
          lrcLibLyricsEnabled: preferences.lrcLibEnabled,
        );

        if (newAudio == null) return;
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
            audio: audio,
            playlist: playlist,
          );
        },
      );
    }

    void onReplaceFromYoutubeTap() {
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
                      audio: audio,
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

              // TODO: Удалить из текущего плейлиста.
              if (kDebugMode)
                ListTile(
                  leading: const Icon(
                    Icons.playlist_remove,
                  ),
                  title: Text(
                    l18n.music_detailsDeleteTrackTitle,
                  ),
                  onTap: onRemoveFromPlaylistTap,
                ),

              // TODO: Добавить в другой плейлист.
              if (kDebugMode)
                ListTile(
                  leading: const Icon(
                    Icons.playlist_add,
                  ),
                  title: Text(
                    l18n.music_detailsAddToOtherPlaylistTitle,
                  ),
                  onTap: onAddToOtherPlaylistTap,
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
                  enabled: audio.canPlay,
                  onTap: onAddToQueueTap,
                ),

              // Поиск по Genius.
              ListTile(
                leading: const Icon(
                  Icons.lyrics_outlined,
                ),
                title: Text(
                  l18n.music_detailsGeniusSearchTitle,
                ),
                subtitle: () {
                  // Загрузка.
                  if (hasGeniusInfo.value == null) {
                    return Text(
                      l18n.general_loading,
                    );
                  }

                  // Есть информация.
                  if (hasGeniusInfo.value!) {
                    return Text(
                      l18n.music_detailsGeniusSearchDescription,
                    );
                  }

                  return null;
                }(),
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
                enabled: !audio.isRestricted && !(audio.isCached ?? false),
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
                        text: audio.mediaKey,
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
                    enabled: audio.isCached ?? false,
                    onTap: () async {
                      Navigator.of(context).pop();

                      final File path =
                          await CachedStreamAudioSource.getCachedAudioByKey(
                        audio.mediaKey,
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
