import "dart:async";
import "dart:io";

import "package:debounce_throttle/debounce_throttle.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../../api/deezer/search.dart";
import "../../../api/deezer/shared.dart";
import "../../../consts.dart";
import "../../../main.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player_events.dart";
import "../../../provider/user.dart";
import "../../../services/audio_player.dart";
import "../../../services/cache_manager.dart";
import "../../../services/download_manager.dart";
import "../../../services/logger.dart";
import "../../../utils.dart";
import "../../../widgets/adaptive_dialog.dart";
import "../../../widgets/dialogs.dart";
import "../music.dart";
import "track_info.dart";

/// Диалог, помогающий пользователю заменить обложку у трека.
class TrackThumbnailDialog extends StatefulHookConsumerWidget {
  /// Трек, над обложкой которого производится манипуляция.
  final ExtendedAudio audio;

  /// Плейлист, в котором находится трек.
  final ExtendedPlaylist playlist;

  /// Если true, то сразу после открытия данного диалога фокус будет на [SearchBar].
  final bool focusSearchBarOnOpen;

  const TrackThumbnailDialog({
    super.key,
    required this.audio,
    required this.playlist,
    this.focusSearchBarOnOpen = true,
  });

  @override
  ConsumerState<TrackThumbnailDialog> createState() =>
      _TrackThumbnailDialogState();
}

class _TrackThumbnailDialogState extends ConsumerState<TrackThumbnailDialog> {
  // TODO: Переписать с использованием hook'ов.

  /// Контроллер, используемый для управления введённым в поле поиска текстом.
  final controller = useTextEditingController();

  /// FocusNode для фокуса поля поиска сразу после открытия данного диалога.
  final focusNode = useFocusNode();

  /// Debouncer для поиска.
  final debouncer = Debouncer<String>(
    const Duration(
      seconds: 1,
    ),
    initialValue: "",
  );

  /// Текущий Future по поиску обложек треков через Deezer. Может отсутствовать, если ничего не было введено в поиск.
  Future<List<DeezerTrack>>? searchFuture;

  /// Выбранный пользователем [DeezerTrack], обложка которого будет использована.
  DeezerTrack? selectedTrack;

  /// Метод, который вызывается при печати в поле поиска.
  ///
  /// Данный метод вызывается с учётом debouncing'а.
  void onDebounce(String query) {
    // Если мы вышли из текущего Route, то ничего не делаем.
    if (!mounted) return;

    // Проверяем наличие интернета.
    if (!networkRequiredDialog(ref, context)) return;

    // Если ничего не введено, то делаем пустой Future.
    if (query.isEmpty) {
      if (searchFuture != null) {
        setState(
          () => searchFuture = null,
        );
      }

      return;
    }

    searchFuture = deezer_search_sorted(query, "");
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    // Обработчик печати.
    controller.addListener(
      () => debouncer.value = controller.text,
    );

    // Обработчик событий поиска, испускаемых Debouncer'ом, если пользователь остановил печать.
    debouncer.values.listen(onDebounce);

    // Если у пользователя ПК, то тогда устанавливаем фокус на поле поиска.
    if (isDesktop && widget.focusSearchBarOnOpen) focusNode.requestFocus();

    // Сразу же вставляем название трека в поле поиска.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.text = "${widget.audio.artist} - ${widget.audio.title}";
    });
  }

  @override
  Widget build(BuildContext context) {
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerStateProvider);

    final bool isMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

    return AdaptiveDialog(
      child: Container(
        padding: EdgeInsets.all(
          isMobileLayout ? 16 : 24,
        ),
        width: 650,
        child: Column(
          children: [
            Padding(
              padding: isMobileLayout
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Кнопка "Назад".
                  if (isMobileLayout)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 12,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.adaptive.arrow_back,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),

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
                        onChanged: (String query) => setState(() {}),
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
                                    onPressed: () => setState(
                                      () => controller.clear(),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Результаты поиска.
            Expanded(
              child: FutureBuilder(
                future: searchFuture,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<DeezerTrack>> snapshot,
                ) {
                  final List<DeezerTrack> tracks = snapshot.data ?? [];

                  // Пользователь ещё ничего не ввёл.
                  if (snapshot.connectionState == ConnectionState.none) {
                    return Text(
                      l18n.music_typeToSearchText,
                    );
                  }

                  // Информация по данному плейлисту ещё не была загружена.
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      snapshot.hasError ||
                      !snapshot.hasData) {
                    return ListView.builder(
                      itemCount: 50,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (BuildContext context, int index) {
                        return Skeletonizer(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8,
                            ),
                            child: AudioTrackTile(
                              audio: ExtendedAudio(
                                id: -1,
                                ownerID: -1,
                                title: fakeTrackNames[
                                    index % fakeTrackNames.length],
                                artist: fakeTrackNames[
                                    (index + 1) % fakeTrackNames.length],
                                duration: 60 * 3,
                                accessKey: "",
                                url: "",
                                date: 0,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Ничего не найдено.
                  if (snapshot.hasData && tracks.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      child: StyledText(
                        text: l18n.music_zeroSearchResults,
                        tags: {
                          "click": StyledTextActionTag(
                            (String? text, Map<String?, String?> attrs) =>
                                setState(
                              () => controller.clear(),
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        },
                      ),
                    );
                  }

                  // Отображаем данные.
                  return ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (BuildContext context, int index) {
                      final DeezerTrack track = tracks.elementAt(index);

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 8,
                        ),
                        child: AudioTrackTile(
                          audio: ExtendedAudio(
                            id: track.id,
                            ownerID: -track.id,
                            title: track.title,
                            artist: track.artist.name,
                            duration: track.duration,
                            accessKey: "",
                            url: "",
                            date: 0,
                            deezerThumbs:
                                ExtendedThumbnail.fromDeezerTrack(track),
                          ),
                          selected: selectedTrack == track,
                          onPlay: () => setState(
                            () => selectedTrack = track,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Gap(16),

            // Кнопка для сохранения.
            Align(
              alignment: Alignment.bottomRight,
              child: FilledButton.icon(
                onPressed: selectedTrack != null
                    ? () async {
                        // Заменяем обложки.
                        widget.audio.deezerThumbs = null;
                        widget.audio.vkThumbs =
                            ExtendedThumbnail.fromDeezerTrack(selectedTrack!);

                        // Удаляем кэшированные обложки.
                        CachedAlbumImagesManager.instance
                            .removeFile("${widget.audio.mediaKey}small");
                        CachedAlbumImagesManager.instance
                            .removeFile("${widget.audio.mediaKey}max");

                        // TODO: Сохраняем изменения.
                        await appStorage
                            .savePlaylist(widget.playlist.asDBPlaylist);

                        // Загружаем новые обложки.
                        // CachedStreamedAudio.downloadTrackData(
                        //   widget.audio,
                        //   widget.playlist,
                        //   user,
                        //   allowDeezer: user.settings.deezerThumbnails,
                        //   allowSpotifyLyrics: user.settings.spotifyLyrics &&
                        //       user.spDCcookie != null,
                        //   saveInDB: true,
                        // );

                        // Отображаем сообщение об успешном изменении, и выходим из диалога.
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l18n.music_setThumbnailSaveSuccessful,
                              ),
                            ),
                          );

                          context.pop();
                        }
                      }
                    : null,
                icon: const Icon(
                  Icons.image_search,
                ),
                label: Text(
                  l18n.music_setThumbnailSave,
                ),
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
    final AppLogger logger = getLogger("BottomAudioOptionsDialog");
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
                  selected: audio == player.currentAudio,
                  currentlyPlaying: player.loaded && player.playing,
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

                    context.pop();

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

                    context.pop();

                    // Загружаем трек.
                    try {
                      await CacheItem.cacheTrack(
                        audio,
                        playlist,
                        true,
                        // user,
                      );
                    } catch (error, stackTrace) {
                      showLogErrorDialog(
                        "Ошибка при принудительном кэшировании отдельного трека: ",
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

                    context.pop();

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return TrackThumbnailDialog(
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

                      context.pop();
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
                        context.pop();

                        final File path =
                            await CachedStreamedAudio.getCachedAudioByKey(
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
