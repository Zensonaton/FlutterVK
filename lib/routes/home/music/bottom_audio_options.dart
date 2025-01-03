import "dart:io";

import "package:file_picker/file_picker.dart";
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

/// Виджет для [ListTile], отображающий [CircularProgressIndicator] во время загрузки.
class ListTileLoadingProgressIndicator extends StatelessWidget {
  const ListTileLoadingProgressIndicator({
    super.key,
  });

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
    ExtendedAudio newAudio = newPlaylist!.audios!.firstWhere(
      (element) => element.ownerID == audio.ownerID && element.id == audio.id,
    );

    final l18n = ref.watch(l18nProvider);

    final isCached = newAudio.isCached ?? false;
    final isRestricted = newAudio.isRestricted;
    final isReplacedLocally = newAudio.replacedLocally ?? false;

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

    void onGoToAlbumTap() {
      if (newAudio.album == null) {
        throw Exception("This audio doesn't have an album");
      }

      if (!networkRequiredDialog(ref, context)) return;

      showWipDialog(context);
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

    void onReplaceWithLocalAudioTap() async {
      final messenger = ScaffoldMessenger.of(context);
      final playlists = ref.read(playlistsProvider.notifier);
      Navigator.of(context).pop();

      // Если трек уже заменён локально, то предлагаем удалить его.
      if (isReplacedLocally) {
        // Если трек недоступен, то уточняем у пользователя, уверен ли он в том что хочет удалить его.
        if (isRestricted) {
          final result = await showYesNoDialog(
            context,
            title:
                l18n.music_detailsReplaceWithLocalAudioRestoreRestrictedTitle,
            description: l18n
                .music_detailsReplaceWithLocalAudioRestoreRestrictedDescription,
            icon: Icons.music_off,
          );

          if (result != true) return;
        }

        try {
          // Удаляем локальную версию трека.
          final cacheFile =
              await CachedStreamAudioSource.getCachedAudioByKey(audio.mediaKey);
          await cacheFile.delete();

          newAudio = newAudio.copyWith(
            cachedSize: 0,
            replacedLocally: false,
          );
          await playlists.updatePlaylist(
            playlist.basicCopyWith(
              audiosToUpdate: [newAudio],
            ),
            saveInDB: true,
          );

          // Показываем уведомление.
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                l18n.music_replaceWithLocalRestoreSuccess,
              ),
            ),
          );
        } catch (error, stackTrace) {
          showLogErrorDialog(
            "Error while removing local audio:",
            error,
            stackTrace,
            logger,
            // ignore: use_build_context_synchronously
            context,
          );
        }

        return;
      }

      // Просим пользователя выбрать файл.
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          dialogTitle: l18n.music_replaceWithLocalFilepickerDialogTitle,
          type: FileType.custom,
          allowedExtensions: ["mp3"],
          lockParentWindow: true,
        );
        if (result == null) return;

        // Узнаём параметры переданного трека.
        final passedAudio = File(result.files.single.path!);
        final passedAudioLength = await passedAudio.length();

        if (passedAudioLength <=
            CachedStreamAudioSource.corruptedFileSizeBytes) {
          throw Exception(
            "File is too small to be a valid audio file.",
          );
        }

        // Вставляем кэшированный файл.
        final cacheFile =
            await CachedStreamAudioSource.getCachedAudioByKey(audio.mediaKey);
        await passedAudio.copy(cacheFile.path);

        // Помечаем трек как кэшированный.
        newAudio = newAudio.copyWith(
          cachedSize: passedAudioLength,
          replacedLocally: true,
        );
        await playlists.updatePlaylist(
          playlist.basicCopyWith(
            audiosToUpdate: [newAudio],
          ),
          saveInDB: true,
        );

        // Показываем уведомление.
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l18n.music_replaceWithLocalSuccess,
            ),
          ),
        );
      } catch (error, stackTrace) {
        showLogErrorDialog(
          "Error while replacing audio with local file:",
          error,
          stackTrace,
          logger,
          // ignore: use_build_context_synchronously
          context,
        );
      }
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
        return SizedBox(
          width: 500,
          height: 300,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                listTileTheme: const ListTileThemeData(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 36,
                  ),
                ),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.only(
                  top: 24,
                ),
                children: [
                  // Изображение трека.
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                    ),
                    child: AudioTrackTile(
                      audio: newAudio,
                      allowTextSelection: true,
                      showAlbumName: true,
                    ),
                  ),
                  const Gap(6),

                  // Разделитель.
                  const Divider(
                    indent: 24,
                    endIndent: 24,
                  ),
                  const Gap(6),

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
                        ? const ListTileLoadingProgressIndicator()
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

                  // TODO: Добавить в плейлист.
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

                  // TODO: Перейти к альбому.
                  if (kDebugMode)
                    ListTile(
                      leading: const Icon(
                        Icons.album,
                      ),
                      title: Text(
                        l18n.music_detailsGoToAlbumTitle,
                      ),
                      subtitle: newAudio.album != null
                          ? Text(
                              l18n.music_detailsGoToAlbumDescription(
                                newAudio.album!.title,
                              ),
                            )
                          : null,
                      enabled: newAudio.album != null,
                      onTap: onGoToAlbumTap,
                    ),

                  // Поиск по Genius.
                  ListTile(
                    leading: hasGeniusInfo.value == null
                        ? const ListTileLoadingProgressIndicator()
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
                    enabled: !isRestricted && !isCached,
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

                  // Заменить трек локально, либо удалить локальную версию.
                  ListTile(
                    leading: Icon(
                      isReplacedLocally ? Icons.music_off : Icons.sd_card,
                    ),
                    title: Text(
                      isReplacedLocally
                          ? l18n.music_detailsReplaceWithLocalAudioRestoreTitle
                          : l18n.music_detailsReplaceWithLocalAudioTitle,
                    ),
                    subtitle: !isReplacedLocally
                        ? Text(
                            l18n.music_detailsReplaceWithLocalAudioDescription,
                          )
                        : null,
                    onTap: onReplaceWithLocalAudioTap,
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
                        enabled: isCached,
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

                  // Для нижнего Padding'а.
                  Gap(
                    MediaQuery.paddingOf(context).bottom,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
