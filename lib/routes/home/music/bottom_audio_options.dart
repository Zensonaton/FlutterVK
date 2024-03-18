import "dart:async";
import "dart:io";

import "package:debounce_throttle/debounce_throttle.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../../api/deezer/search.dart";
import "../../../api/deezer/shared.dart";
import "../../../consts.dart";
import "../../../main.dart";
import "../../../provider/color.dart";
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
class TrackThumbnailDialog extends StatefulWidget {
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
  State<TrackThumbnailDialog> createState() => _TrackThumbnailDialogState();
}

class _TrackThumbnailDialogState extends State<TrackThumbnailDialog> {
  /// Контроллер, используемый для управления введённым в поле поиска текстом.
  final TextEditingController controller = TextEditingController();

  /// FocusNode для фокуса поля поиска сразу после открытия данного диалога.
  final FocusNode focusNode = FocusNode();

  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

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
    if (!networkRequiredDialog(context)) return;

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

  /// Метод, который вызывается при нажатии на клавишу клавиатуры.
  void keyboardListener(
    RawKeyEvent key,
  ) {
    // Нажатие кнопки ESC.
    if (key.isKeyPressed(LogicalKeyboardKey.escape)) {
      // Если в поле поиска есть текст, и это поле находится в фокусе, то ничего не делаем.
      // "Стирание" текста находится в TextField'е.
      if (controller.text.isNotEmpty && focusNode.hasFocus || !mounted) return;

      Navigator.of(context).pop();

      return;
    }

    // Нажатие комбинации CTRL+F.
    if (key.isControlPressed && key.isKeyPressed(LogicalKeyboardKey.keyF)) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
      focusNode.requestFocus();

      return;
    }
  }

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),
    ];

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

    // Обработчик нажатия кнопок клавиатуры.
    RawKeyboard.instance.addListener(keyboardListener);
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }

    RawKeyboard.instance.removeListener(keyboardListener);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;
    final PlayerSchemeProvider colorScheme =
        Provider.of<PlayerSchemeProvider>(context, listen: false);

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
                        bottom: 12,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.adaptive.arrow_back,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
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
                          hintText: AppLocalizations.of(context)!
                              .music_setThumbnailSearchText,
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
            const SizedBox(
              height: 16,
            ),

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
                      AppLocalizations.of(context)!.music_typeToSearchText,
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
                    return StyledText(
                      text:
                          AppLocalizations.of(context)!.music_zeroSearchResults,
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
            const SizedBox(
              height: 16,
            ),

            // Кнопка для сохранения.
            Align(
              alignment: Alignment.bottomRight,
              child: FilledButton.icon(
                onPressed: selectedTrack != null
                    ? () async {
                        final UserProvider user =
                            Provider.of<UserProvider>(context, listen: false);

                        // Заменяем обложки.
                        widget.audio.deezerThumbs = null;
                        widget.audio.vkThumbs =
                            ExtendedThumbnail.fromDeezerTrack(selectedTrack!);

                        // Удаляем кэшированные обложки.
                        CachedAlbumImagesManager.instance
                            .removeFile("${widget.audio.mediaKey}small");
                        CachedAlbumImagesManager.instance
                            .removeFile("${widget.audio.mediaKey}max");

                        // Сохраняем изменения.
                        user.markUpdated(false);
                        await appStorage
                            .savePlaylist(widget.playlist.asDBPlaylist);

                        // Загружаем новые обложки.
                        CachedStreamedAudio.downloadTrackData(
                          widget.audio,
                          widget.playlist,
                          user,
                          allowDeezer: user.settings.deezerThumbnails,
                          allowSpotifyLyrics: user.settings.spotifyLyrics &&
                              user.spDCcookie != null,
                          saveInDB: true,
                        );

                        // Отображаем сообщение об успешном изменении, и выходим из диалога.
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!
                                    .music_setThumbnailSaveSuccessful,
                              ),
                            ),
                          );

                          Navigator.of(context).pop();
                        }
                      }
                    : null,
                icon: const Icon(
                  Icons.image_search,
                ),
                label: Text(
                  AppLocalizations.of(context)!.music_setThumbnailSave,
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
class BottomAudioOptionsDialog extends StatefulWidget {
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
  State<BottomAudioOptionsDialog> createState() =>
      _BottomAudioOptionsDialogState();
}

class _BottomAudioOptionsDialogState extends State<BottomAudioOptionsDialog> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playingStream.listen(
        (bool playing) => setState(() {}),
      ),

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLogger logger = getLogger("BottomAudioOptionsDialog");
    final UserProvider user = Provider.of<UserProvider>(context);

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
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: AudioTrackTile(
                    audio: widget.audio,
                    selected: widget.audio == player.currentAudio,
                    currentlyPlaying: player.loaded && player.playing,
                  ),
                ),

                // Разделитель.
                const Padding(
                  padding: EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Divider(),
                ),

                // Редактировать данные трека.
                ListTile(
                  enabled: widget.audio.album == null &&
                      widget.audio.ownerID == user.id!,
                  onTap: () {
                    if (!networkRequiredDialog(context)) return;

                    Navigator.of(context).pop();

                    showDialog(
                      context: context,
                      builder: (BuildContext context) => TrackInfoEditDialog(
                        audio: widget.audio,
                      ),
                    );
                  },
                  leading: const Icon(
                    Icons.edit,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.music_detailsEditTitle,
                  ),
                ),

                // Удалить из текущего плейлиста.
                ListTile(
                  onTap: () {
                    if (!networkRequiredDialog(context)) return;

                    showWipDialog(context);
                  },
                  leading: const Icon(
                    Icons.playlist_remove,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.music_detailsDeleteTrackTitle,
                  ),
                ),

                // Добавить в другой плейлист.
                ListTile(
                  onTap: () {
                    if (!networkRequiredDialog(context)) return;

                    showWipDialog(context);
                  },
                  leading: const Icon(
                    Icons.playlist_add,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!
                        .music_detailsAddToOtherPlaylistTitle,
                  ),
                ),

                // Добавить в очередь.
                if (false)
                  // ignore: dead_code
                  ListTile(
                    onTap: () async {
                      await player.addNextToQueue(
                        widget.audio,
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.general_addedToQueue,
                          ),
                          duration: const Duration(
                            seconds: 3,
                          ),
                        ),
                      );

                      Navigator.of(context).pop();
                    },
                    enabled: widget.audio.canPlay,
                    leading: const Icon(
                      Icons.queue_music,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.music_detailsPlayNextTitle,
                    ),
                  ),

                // Кэшировать этот трек.
                ListTile(
                  onTap: () async {
                    if (!networkRequiredDialog(context)) return;

                    Navigator.of(context).pop();

                    // Загружаем трек.
                    try {
                      await CacheItem.cacheTrack(
                        widget.audio,
                        widget.playlist,
                        true,
                        user,
                      );
                    } catch (error, stackTrace) {
                      // ignore: use_build_context_synchronously
                      showLogErrorDialog(
                        "Ошибка при принудительном кэшировании отдельного трека: ",
                        error,
                        stackTrace,
                        logger,
                        context,
                      );

                      return;
                    }

                    if (!context.mounted) return;

                    user.markUpdated();
                  },
                  enabled: !widget.audio.isRestricted &&
                      !(widget.audio.isCached ?? false),
                  leading: const Icon(
                    Icons.download,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.music_detailsCacheTrackTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!
                        .music_detailsCacheTrackDescription,
                  ),
                ),

                // Заменить обложку.
                ListTile(
                  onTap: () {
                    if (!networkRequiredDialog(context)) return;

                    Navigator.of(context).pop();

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return TrackThumbnailDialog(
                          audio: widget.audio,
                          playlist: widget.playlist,
                        );
                      },
                    );
                  },
                  leading: const Icon(
                    Icons.image_search,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!
                        .music_detailsSetThumbnailTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!
                        .music_detailsSetThumbnailDescription,
                  ),
                ),

                // Перезалить с Youtube.
                ListTile(
                  onTap: () {
                    if (!networkRequiredDialog(context)) return;

                    showWipDialog(context);
                  },
                  leading: const Icon(
                    Icons.rotate_left,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!
                        .music_detailsReuploadFromYoutubeTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!
                        .music_detailsReuploadFromYoutubeDescription,
                  ),
                ),

                // Debug-опции.
                if (kDebugMode) ...[
                  ListTile(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: widget.audio.mediaKey,
                        ),
                      );

                      Navigator.of(context).pop();
                    },
                    leading: const Icon(
                      Icons.link,
                    ),
                    title: const Text(
                      "Скопировать ID трека",
                    ),
                    subtitle: const Text(
                      "Debug-режим",
                    ),
                  ),
                  if (Platform.isWindows)
                    ListTile(
                      onTap: () async {
                        Navigator.of(context).pop();

                        final File path =
                            await CachedStreamedAudio.getCachedAudioByKey(
                          widget.audio.mediaKey,
                        );
                        await Process.run(
                          "explorer.exe",
                          ["/select,", path.path],
                        );
                      },
                      enabled: widget.audio.isCached ?? false,
                      leading: const Icon(
                        Icons.folder_open,
                      ),
                      title: const Text(
                        "Открыть папку с треком",
                      ),
                      subtitle: const Text(
                        "Debug-режим",
                      ),
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
