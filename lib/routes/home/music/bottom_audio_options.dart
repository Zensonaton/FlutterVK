import "dart:async";
import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../../api/deezer/search.dart";
import "../../../api/deezer/shared.dart";
import "../../../consts.dart";
import "../../../main.dart";
import "../../../provider/color.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player_events.dart";
import "../../../provider/playlists.dart";
import "../../../provider/user.dart";
import "../../../services/audio_player.dart";
import "../../../services/cache_manager.dart";
import "../../../services/download_manager.dart";
import "../../../services/image_to_color_scheme.dart";
import "../../../services/logger.dart";
import "../../../utils.dart";
import "../../../widgets/adaptive_dialog.dart";
import "../../../widgets/audio_track.dart";
import "../../../widgets/dialogs.dart";
import "track_info.dart";

/// Диалог, помогающий пользователю отредактировать обложку у передаваемого трека.
class TrackThumbnailEditDialog extends HookConsumerWidget {
  static final AppLogger logger = getLogger("TrackThumbnailEditDialog");

  /// Трек, над обложкой которого производится манипуляция.
  final ExtendedAudio audio;

  /// Плейлист, в котором находится трек.
  final ExtendedPlaylist playlist;

  const TrackThumbnailEditDialog({
    super.key,
    required this.audio,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final playlists = ref.read(playlistsProvider.notifier);

    final selectedTrack = useState<DeezerTrack?>(null);
    final controller = useTextEditingController(
      text:
          "${audio.artist}${audio.subtitle != null ? " (${audio.subtitle})" : ""} - ${audio.title}",
    );
    final focusNode = useFocusNode();
    final ValueNotifier<Future<List<DeezerTrack>>?> searchFuture =
        useState(null);
    final debouncedInput = useDebounced(
      controller.text,
      const Duration(milliseconds: 500),
    );
    useValueListenable(controller);

    void onSearch() {
      if (!context.mounted && !networkRequiredDialog(ref, context)) return;

      final String query = controller.text.trim();

      Future<List<DeezerTrack>> search() async {
        final DeezerAPISearchResponse response =
            await deezer_search_query(query);

        return response.data;
      }

      // Если ничего не введено, то делаем пустой Future.
      if (query.isEmpty) {
        if (searchFuture.value != null) {
          searchFuture.value = null;
        }

        return;
      }

      // Делаем запрос по получению результатов поиска.
      searchFuture.value = search();
    }

    void onSearchClear() => controller.clear();

    void onSearchResultSelect(DeezerTrack track) => selectedTrack.value = track;

    void postThumbnailSave(ExtendedAudio newAudio) async {
      final trackSchemeInfo = ref.read(trackSchemeInfoProvider.notifier);

      // Очищаем кэш изображений в памяти.
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Удаляем старые обложки.
      final String mediaKey = audio.mediaKey;
      await CachedAlbumImagesManager.instance.removeFile("${mediaKey}small");
      await CachedAlbumImagesManager.instance.removeFile("${mediaKey}max");

      // Получаем новые цвета, если у нас есть хоть какая-то обложка.
      ImageSchemeExtractor? newColors;
      if (newAudio.smallestThumbnail != null) {
        // Загружаем новую обложку.
        await PlaylistCacheDownloadItem.downloadWithMetadata(
          playlists.ref,
          playlist,
          newAudio,
          downloadAudio: false,
          downloadLyrics: false,
        );

        newColors = await ImageSchemeExtractor.fromImageProvider(
          CachedNetworkImageProvider(
            newAudio.smallestThumbnail!,
            cacheKey: "${newAudio.mediaKey}small",
            cacheManager: CachedAlbumImagesManager.instance,
          ),
        );

        // Если играет этот же трек, то обновляем цвета по всему приложению.
        if (player.currentAudio?.id == audio.id) {
          logger.d("Updating colors for current track");

          trackSchemeInfo.fromExtractor(newColors);
        }
      }

      // Сохраняем новую версию трека.
      await playlists.updatePlaylist(
        playlist.basicCopyWith(
          audiosToUpdate: [
            newAudio.basicCopyWith(
              deezerThumbs: newAudio.deezerThumbs,
              forceDeezerThumbs: newAudio.forceDeezerThumbs,
              colorInts: newColors?.colorInts,
              scoredColorInts: newColors?.scoredColorInts,
              frequentColorInt: newColors?.frequentColor.value,
              colorCount: newColors?.colorCount,
            ),
          ],
        ),
        saveInDB: true,
      );
    }

    void onThumbnailSave() {
      assert(
        selectedTrack.value != null,
        "No track selected",
      );

      if (context.mounted) Navigator.of(context).pop();

      // Сохраняем новую обложку, передавая трек с новыми обложками.
      postThumbnailSave(
        audio.basicCopyWith(
          forceDeezerThumbs: true,
          deezerThumbs: ExtendedThumbnails.fromDeezerTrack(
            selectedTrack.value!,
          ),
        ),
      );
    }

    void onThumbnailReset() async {
      assert(
        audio.forceDeezerThumbs,
        "Deezer thumbnails aren't forced for that track",
      );

      if (context.mounted) Navigator.of(context).pop();

      // Сохраняем новую обложку, передавая трек без Deezer-обложки.
      postThumbnailSave(
        audio.basicCopyWith(
          forceDeezerThumbs: false,
        ),
      );
    }

    useEffect(
      () {
        // Если у пользователя ПК, то тогда устанавливаем фокус на поле поиска.
        if (isDesktop) focusNode.requestFocus();

        return null;
      },
      [],
    );
    useEffect(
      () {
        if (debouncedInput == null) return;
        onSearch();

        return null;
      },
      [debouncedInput],
    );

    final mobileLayout = isMobileLayout(context);

    return AdaptiveDialog(
      child: Container(
        padding: EdgeInsets.all(
          mobileLayout ? 16 : 24,
        ),
        width: 650,
        child: Column(
          children: [
            // Поиск.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Кнопка "Назад".
                if (mobileLayout) ...[
                  const BackButton(),
                  const Gap(12),
                ],

                // Поиск.
                Expanded(
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(
                        LogicalKeyboardKey.escape,
                      ): () => controller.clear(),
                    },
                    child: TextField(
                      focusNode: focusNode,
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: l18n.music_setThumbnailSearchText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            globalBorderRadius,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                        ),
                        suffixIcon: controller.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 12,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                  ),
                                  onPressed: onSearchClear,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Содержимое поиска.
            Expanded(
              child: FutureBuilder(
                future: searchFuture.value,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<DeezerTrack>> snapshot,
                ) {
                  // Содержимое поиска.
                  return ListView.separated(
                    itemCount: () {
                      // Запрос на поиск.
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return 50;
                      }

                      // Ошибка при загрузке, либо ничего не было найдено.
                      if (searchFuture.value == null ||
                          snapshot.hasError ||
                          snapshot.data == null ||
                          snapshot.data!.isEmpty) {
                        return 1;
                      }

                      return snapshot.data!.length;
                    }(),
                    separatorBuilder: (BuildContext context, int index) {
                      return const Gap(trackTileSpacing);
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final deezerTrack = snapshot.data?.elementAtOrNull(index);
                      final isSelected =
                          selectedTrack.value?.id == deezerTrack?.id;

                      // Пользователь ещё ничего не ввёл.
                      if (searchFuture.value == null) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          child: Text(
                            l18n.music_setThumbnailNoQuery,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      // Информация по данному плейлисту ещё не была загружена.
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Skeletonizer(
                          child: AudioTrackTile(
                            audio: ExtendedAudio(
                              id: -1,
                              ownerID: -1,
                              title:
                                  fakeTrackNames[index % fakeTrackNames.length],
                              artist: fakeTrackNames[
                                  (index + 1) % fakeTrackNames.length],
                              duration: 60 * 3,
                            ),
                          ),
                        );
                      }

                      // Ошибка при загрузке.
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          child: Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        );
                      }

                      // Ничего не было найдено.
                      if (snapshot.hasData && snapshot.data!.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          child: StyledText(
                            text: l18n.music_zeroSearchResults,
                            textAlign: TextAlign.center,
                            tags: {
                              "click": StyledTextActionTag(
                                (_, __) => onSearchClear(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            },
                          ),
                        );
                      }

                      // Результаты поиска.
                      return AudioTrackTile(
                        audio: ExtendedAudio(
                          id: index,
                          ownerID: 0,
                          artist: deezerTrack!.artist.name,
                          title: deezerTrack.title,
                          duration: deezerTrack.duration,
                          deezerThumbs: ExtendedThumbnails.fromDeezerTrack(
                            deezerTrack,
                          ),
                        ),
                        allowImageCache: false,
                        forceAvailable: true,
                        showDuration: false,
                        glowIfSelected: true,
                        isSelected: isSelected,
                        isPlaying: true,
                        onPlayToggle: () => onSearchResultSelect(deezerTrack),
                      );
                    },
                  );
                },
              ),
            ),
            const Gap(16),

            // Кнопки для применения либо отмены изменений.
            Align(
              alignment: Alignment.bottomRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Сбросить.
                  if (audio.forceDeezerThumbs)
                    FilledButton.tonalIcon(
                      onPressed: onThumbnailReset,
                      icon: const Icon(
                        Icons.delete,
                      ),
                      label: Text(
                        l18n.general_reset,
                      ),
                    ),

                  // Сохранить.
                  FilledButton.icon(
                    onPressed:
                        selectedTrack.value != null ? onThumbnailSave : null,
                    icon: const Icon(
                      Icons.image_search,
                    ),
                    label: Text(
                      l18n.general_save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
class BottomAudioOptionsDialog extends ConsumerWidget {
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
    final user = ref.watch(userProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerStateProvider);

    return DraggableScrollableSheet(
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return Container(
          width: 500,
          height: 300,
          padding: const EdgeInsets.all(24),
          child: SizedBox.expand(
            child: ListView(
              controller: controller,
              children: [
                // Трек.
                AudioTrackTile(
                  audio: audio,
                  isSelected: audio == player.currentAudio,
                  isPlaying: player.loaded && player.playing,
                ),
                const Gap(8),

                // Разделитель.
                const Divider(),
                const Gap(8),

                // Редактировать данные трека.
                ListTile(
                  leading: const Icon(
                    Icons.edit,
                  ),
                  title: Text(
                    l18n.music_detailsEditTitle,
                  ),
                  enabled: audio.album == null && audio.ownerID == user.id,
                  onTap: () {
                    if (!networkRequiredDialog(ref, context)) return;

                    Navigator.of(context).pop();

                    showDialog(
                      context: context,
                      builder: (BuildContext context) => TrackInfoEditDialog(
                        audio: audio,
                      ),
                    );
                  },
                ),

                // Удалить из текущего плейлиста.
                ListTile(
                  leading: const Icon(
                    Icons.playlist_remove,
                  ),
                  title: Text(
                    l18n.music_detailsDeleteTrackTitle,
                  ),
                  onTap: () {
                    if (!networkRequiredDialog(ref, context)) return;

                    showWipDialog(context);
                  },
                ),

                // Добавить в другой плейлист.
                ListTile(
                  leading: const Icon(
                    Icons.playlist_add,
                  ),
                  title: Text(
                    l18n.music_detailsAddToOtherPlaylistTitle,
                  ),
                  onTap: () {
                    if (!networkRequiredDialog(ref, context)) return;

                    showWipDialog(context);
                  },
                ),

                // Добавить в очередь.
                if (false)
                  // ignore: dead_code
                  ListTile(
                    leading: const Icon(
                      Icons.queue_music,
                    ),
                    title: Text(
                      l18n.music_detailsPlayNextTitle,
                    ),
                    enabled: audio.canPlay,
                    onTap: () async {
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
                    },
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
                  onTap: () async {
                    if (!networkRequiredDialog(ref, context)) return;

                    Navigator.of(context).pop();

                    try {
                      // TODO: Загружаем трек.
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
                  },
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
                  onTap: () {
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
                  },
                ),

                // Перезалить с Youtube.
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
                  onTap: () {
                    if (!networkRequiredDialog(ref, context)) return;

                    showWipDialog(context);
                  },
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
          ),
        );
      },
    );
  }
}
