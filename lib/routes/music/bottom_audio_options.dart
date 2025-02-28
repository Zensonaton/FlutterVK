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

import "../../extensions.dart";
import "../../main.dart";
import "../../provider/auth.dart";
import "../../provider/download_manager.dart";
import "../../provider/l18n.dart";
import "../../provider/player.dart";
import "../../provider/playlists.dart";
import "../../provider/preferences.dart";
import "../../provider/user.dart";
import "../../services/download_manager.dart";
import "../../services/logger.dart";
import "../../services/player/server.dart";
import "../../utils.dart";
import "../../widgets/audio_track.dart";
import "../../widgets/dialogs.dart";
import "deezer_thumbs.dart";
import "info_edit.dart";

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

    final player = ref.read(playerProvider);
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

        // Выключаем в демо-режиме.
        if (ref.read(isDemoProvider)) {
          hasGeniusInfo.value = false;

          return;
        }

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
      await newAudio.likeDislikeRestoreSafe(context, player.ref);
      if (!context.mounted) return;

      isTogglingLikeState.value = false;
    }

    void addToPlaylistTap() {
      if (!networkRequiredDialog(ref, context)) return;

      showWipDialog(context);
    }

    void onAddToQueueTap() async {
      await player.addNextToQueue(newAudio);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l18n.track_added_to_queue,
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
      if (!demoModeDialog(ref, context)) return;

      Navigator.of(context).pop();

      await launchUrlString(geniusUrl);
    }

    void onCacheTrackTap() async {
      if (!demoModeDialog(ref, context)) return;
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
              appleMusicThumbs: preferences.appleMusicAnimatedCovers,
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
      if (!demoModeDialog(ref, context)) return;
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
      if (!demoModeDialog(ref, context)) return;

      final messenger = ScaffoldMessenger.of(context);
      final playlists = ref.read(playlistsProvider.notifier);
      Navigator.of(context).pop();

      // Если трек уже заменён локально, то предлагаем удалить его.
      if (isReplacedLocally) {
        // Если трек недоступен, то уточняем у пользователя, уверен ли он в том что хочет удалить его.
        if (isRestricted) {
          final result = await showYesNoDialog(
            context,
            title: l18n.remove_local_track_is_restricted_title,
            description: l18n.remove_local_track_is_restricted_desc,
            icon: Icons.music_off,
          );

          if (result != true) return;
        }

        try {
          // Удаляем локальную версию трека.
          final cacheFile =
              await PlayerLocalServer.getCachedAudioByKey(audio.mediaKey);
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
                l18n.remove_local_track_success,
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
          dialogTitle: l18n.replace_track_with_local_filepicker_title,
          type: FileType.custom,
          allowedExtensions: ["mp3"],
          lockParentWindow: true,
        );
        if (result == null) return;

        // Узнаём параметры переданного трека.
        final passedAudio = File(result.files.single.path!);
        final passedAudioLength = await passedAudio.length();

        if (passedAudioLength <= PlayerLocalServer.corruptedFileSizeBytes) {
          throw Exception(
            "File is too small to be a valid audio file.",
          );
        }

        // Вставляем кэшированный файл.
        final cacheFile =
            await PlayerLocalServer.getCachedAudioByKey(audio.mediaKey);
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
              l18n.replace_track_with_local_success,
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
      if (!demoModeDialog(ref, context)) return;
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
                      l18n.general_edit,
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
                          ? l18n.remove_track_as_liked
                          : l18n.add_track_as_liked,
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
                        l18n.add_track_to_playlist,
                      ),
                      onTap: addToPlaylistTap,
                    ),

                  // Добавить в очередь.
                  ListTile(
                    leading: const Icon(
                      Icons.queue_music,
                    ),
                    title: Text(
                      l18n.play_track_next,
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
                        l18n.go_to_track_album,
                      ),
                      subtitle: newAudio.album != null
                          ? Text(
                              l18n.go_to_track_album_desc(
                                title: newAudio.album!.title,
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
                      l18n.search_track_on_genius,
                    ),
                    subtitle: Text(
                      l18n.search_track_on_genius_desc,
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
                      l18n.cache_this_track,
                    ),
                    subtitle: Text(
                      l18n.cache_this_track_desc,
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
                      l18n.change_track_thumbnail,
                    ),
                    subtitle: Text(
                      l18n.change_track_thumbnail_desc,
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
                          ? l18n.remove_local_track_version
                          : l18n.replace_track_with_local,
                    ),
                    subtitle: !isReplacedLocally
                        ? Text(
                            l18n.replace_track_with_local_desc,
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
                        l18n.reupload_track_from_youtube,
                      ),
                      subtitle: Text(
                        l18n.reupload_track_from_youtube_desc,
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
                        l18n.track_details,
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
                    if (isWindows)
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
                              await PlayerLocalServer.getCachedAudioByKey(
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
