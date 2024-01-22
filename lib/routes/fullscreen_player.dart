import "dart:async";
import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:fullscreen_window/fullscreen_window.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../api/audio/get_lyrics.dart";
import "../consts.dart";
import "../main.dart";
import "../provider/user.dart";
import "../services/cache_manager.dart";
import "../services/logger.dart";
import "../utils.dart";
import "../widgets/fallback_audio_photo.dart";
import "../widgets/page_route.dart";
import "../widgets/scrollable_slider.dart";

/// Метод, который открывает музыкальный плеер на всё окно, либо на весь экран, если приложение запущено на Desktop-платформе. Если [fullscreenOnDesktop] правдив, и приложение запущено на Desktop ([isDesktop]), то тогда приложение перейдёт в полноэкранный режим.
///
/// Для закрытия воспользуйтесь методом [closeFullscreenPlayer].
Future<void> openFullscreenPlayer(
  BuildContext context, {
  bool fullscreenOnDesktop = true,
}) async {
  // Если приложение запущено на Desktop, то нужно отобразить окно на весь экран.
  if (isDesktop && fullscreenOnDesktop) {
    await FullScreenWindow.setFullScreen(true);
  }

  if (context.mounted) {
    Navigator.push(
      context,
      Material3PageRoute(
        builder: (context) => const FullscreenPlayerRoute(),
      ),
    );
  }
}

/// Метод, закрывающий ранее открытый при помощи метода [openFullscreenPlayer] полноэкранный плеер.
Future<void> closeFullscreenPlayer(
  BuildContext context,
) async {
  // Если приложение запущено на Desktop, то нужно закрыть полноэкранный режим.
  if (isDesktop) {
    await FullScreenWindow.setFullScreen(false);
  }

  if (context.mounted) {
    Navigator.of(context).pop();
  }
}

/// Виджет, отображающий отдельную строчку линии в тексте трека. По нажатию по данной линии, плеер перемотается на начало данной линии.
class TrackLyric extends StatelessWidget {
  /// Текст данной строчки. Если данное поле равно null, то вместо текста будет использоваться виджет [Icon], с иконкой ноты.
  final String? line;

  /// Указывает, что данная строчка была проиграна ранее, и теперь она неактивна.
  final bool isOld;

  /// Указывает, что данная строчка сейчас активна.
  final bool isActive;

  /// Указывает, что текст должен находиться по центру.
  final bool centerText;

  /// Действие, вызываемое при нажатии на данную строчку.
  final VoidCallback? onTap;

  const TrackLyric({
    super.key,
    this.line,
    this.isOld = false,
    required this.isActive,
    this.centerText = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color = (isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary)
        .withOpacity(
      isOld
          ? 0.5
          : isActive
              ? 1.0
              : 0.5,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        globalBorderRadius,
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(
          milliseconds: 300,
        ),
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
          color: color,
          fontSize: 24,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 4,
          ),
          child: line != null
              ? Text(
                  line!,
                  textAlign: centerText ? TextAlign.center : null,
                )
              : Icon(
                  Icons.music_note,
                  color: color,
                ),
        ),
      ),
    );
  }
}

/// Виджет, отображающий текст трека.
class TrackLyricsBlock extends StatelessWidget {
  /// [ScrollController] для [ListView.builder], необходимый для автоматического перемещения до определённой строчки.
  final ScrollController controller = ScrollController();

  TrackLyricsBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    /// Хранит либо объект типа [LyricTimestamp], либо [String].
    List<dynamic> lyrics = player.currentAudio?.lyrics?.timestamps ??
        player.currentAudio?.lyrics?.text ??
        [];

    return ListView.builder(
      controller: controller,
      itemCount: lyrics.length,
      itemBuilder: (BuildContext context, int index) {
        final dynamic curLyric = lyrics[index];
        final bool isSyncedLyric = curLyric is LyricTimestamp;

        LyricTimestamp lyric =
            isSyncedLyric ? curLyric : LyricTimestamp(curLyric);

        bool isActive = isSyncedLyric
            ? player.position.inMilliseconds >= lyric.begin!
            : false;
        bool isOld = isActive && player.position.inMilliseconds >= lyric.end!;

        return TrackLyric(
          line: lyric.line,
          isActive: isActive,
          isOld: isOld,
          centerText: isSyncedLyric,
          onTap: isSyncedLyric
              ? () => player.seek(
                    Duration(
                      milliseconds: lyric.begin!,
                    ),
                    play: true,
                  )
              : null,
        );
      },
    );
  }
}

/// Route, отображающий музыкальный плеер на всё окно приложения.
class FullscreenPlayerRoute extends StatefulWidget {
  const FullscreenPlayerRoute({
    super.key,
  });

  @override
  State<FullscreenPlayerRoute> createState() => _FullscreenPlayerRouteState();
}

class _FullscreenPlayerRouteState extends State<FullscreenPlayerRoute> {
  final AppLogger logger = getLogger("FullscreenPlayerRoute");

  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  /// Список из [Audio.mediaKey] треков, текст песен которых пытается загрузиться в данный момент.
  ///
  /// Данное поле нужно, что бы при повторном вызове метода [build] не делалось множество HTTP-запросов.
  final List<String> lyricsQueue = [];

  /// Последняя известная цветовая схема для данного плеера.
  ///
  /// Используется как fallback в тот момент, пока актуальный [ColorScheme] ещё не был создан.
  ColorScheme? scheme;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Событие изменения громкости плеера.
      player.volumeStream.listen(
        (double volume) => setState(() {}),
      ),

      // Изменения состояния работы shuffle.
      player.shuffleModeEnabledStream.listen(
        (bool shuffleEnabled) => setState(() {}),
      ),

      // Изменения состояния работы повтора плейлиста.
      player.loopModeStream.listen(
        (LoopMode loopMode) => setState(() {}),
      ),

      // Событие изменение прогресса "прослушанности" трека.
      player.positionStream.listen(
        (Duration position) => setState(() {}),
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
    final UserProvider user = Provider.of<UserProvider>(context);

    // Если fallback-цветовая схема плеера не была сохранена, то нам нужно её сохранить.
    scheme ??= ColorScheme.fromSeed(
      seedColor: Colors.grey,
      brightness: Theme.of(context).brightness,
    );

    // Запускаем процесс получения ColorScheme для данного трека.
    if (player.currentAudio?.album?.thumb != null) {
      colorSchemeFromUrl(
        player.currentAudio!.album!.thumb!.photo68!,
        MediaQuery.of(context).platformBrightness,
        player.currentAudio!.mediaKey,
      ).then((ColorScheme newScheme) {
        if (scheme == newScheme) return;

        scheme = newScheme;
      });
    }

    // Если известно, что у трека есть текст песни, то пытаемся его загрузить.
    if ((player.currentAudio?.hasLyrics ?? false) &&
        player.currentAudio!.lyrics == null &&
        !lyricsQueue.contains(player.currentAudio!.mediaKey)) {
      lyricsQueue.add(player.currentAudio!.mediaKey);

      user.audioGetLyrics(player.currentAudio!.mediaKey).then(
        (APIAudioGetLyricsResponse response) {
          // Проверяем, что в ответе нет ошибок.
          if (response.error != null) {
            throw Exception(
              "API error ${response.error!.errorCode}: ${response.error!.errorMessage}",
            );
          }

          // Сохраняем текст песни.
          player.currentAudio!.lyrics = response.response!.lyrics;

          setState(() {});
        },
      ).onError(
        (error, stackTrace) {
          logger.e(
            "Ошибка при попытке получить lyrics трека с ID ${player.currentAudio!.mediaKey}: ",
            error: error,
            stackTrace: stackTrace,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Ошибка при получении текста трека: ${error.toString()}", // TODO: INTL
                ),
              ),
            );
          }
        },
      );
    }

    /// Определяет по оставшейся длине трека то, стоит ли показывать надпись со следующим треком.
    final bool displayNextTrack =
        (player.currentAudio != null && player.nextAudio != null)
            ? (player.progress >= nextPlayingTextProgress)
            : false;

    /// Размер Padding'а.
    const double padding = 56;

    /// Ширина блока текста песни.
    const double lyricsBlockWidth = 500;

    return Theme(
      data: ThemeData(
        colorScheme: scheme,
      ),
      child: Scaffold(
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(
              LogicalKeyboardKey.escape,
            ): () => closeFullscreenPlayer(context),
          },
          child: Focus(
            autofocus: true,
            canRequestFocus: true,
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 500,
              ),
              curve: Curves.ease,
              color: scheme!.primaryContainer,
              child: Stack(
                children: [
                  // Размытое фоновое изображение.
                  if (player.currentAudio?.album?.thumb != null &&
                      user.settings.playerThumbAsBackground)
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 50,
                          sigmaY: 50,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: player.currentAudio!.album!.thumb!.photo!,
                          cacheKey: "${player.currentAudio!.mediaKey}max",
                          fit: BoxFit.cover,
                          placeholder: (BuildContext context, String url) =>
                              const FallbackAudioAvatar(),
                          cacheManager: CachedNetworkImagesManager.instance,
                          color: scheme!.background.withOpacity(0.75),
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                    ),

                  // Внутреннее содержимое.
                  Padding(
                    padding: const EdgeInsets.all(padding),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Надпись "Воспроизведение музыки".
                        Align(
                          alignment: Alignment.topLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              player.playing
                                  ? Image.asset(
                                      "assets/images/audioEqualizer.gif",
                                      color: scheme!.primary,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.fill,
                                    )
                                  : Icon(
                                      Icons.music_note,
                                      color: scheme!.primary,
                                      size: 32,
                                    ),
                              const SizedBox(
                                width: 14,
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Воспроизведение музыки",
                                    style: TextStyle(
                                      color: scheme!.onBackground
                                          .withOpacity(0.75),
                                    ),
                                  ), // TODO: INTL
                                  Text(
                                    player.currentPlaylist?.title ??
                                        "Любимая музыка",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ), // TODO: INTL
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Надпись со следующим треком.
                        if (player.nextAudio != null)
                          AnimatedOpacity(
                            opacity: displayNextTrack ? 1.0 : 0.0,
                            duration: const Duration(
                              milliseconds: 500,
                            ),
                            curve: Curves.ease,
                            child: AnimatedSlide(
                              duration: const Duration(
                                milliseconds: 500,
                              ),
                              curve: Curves.ease,
                              offset: Offset(
                                displayNextTrack ? 0.0 : -0.1,
                                0.0,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  onTap: () => player.next(),
                                  borderRadius: BorderRadius.circular(
                                    globalBorderRadius,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          globalBorderRadius,
                                        ),
                                        child: player.nextAudio!.album?.thumb !=
                                                null
                                            ? CachedNetworkImage(
                                                imageUrl: player.nextAudio!
                                                    .album!.thumb!.photo68!,
                                                cacheKey:
                                                    "${player.nextAudio!.mediaKey}68",
                                                width: 32,
                                                height: 32,
                                                placeholder: (BuildContext
                                                            context,
                                                        String url) =>
                                                    const FallbackAudioAvatar(),
                                                cacheManager:
                                                    CachedNetworkImagesManager
                                                        .instance,
                                              )
                                            : const FallbackAudioAvatar(
                                                width: 32,
                                                height: 32,
                                              ),
                                      ),
                                      const SizedBox(
                                        width: 14,
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Следующим сыграет",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: scheme!.onBackground
                                                  .withOpacity(0.75),
                                            ),
                                          ), // TODO: INTL
                                          Text(
                                            "${player.nextAudio!.artist} • ${player.nextAudio!.title}",
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Текст песни, либо заглушка на случай, если текста нет.
                        Align(
                          alignment: Alignment.topRight,
                          child: SizedBox(
                            width: lyricsBlockWidth,
                            height: MediaQuery.of(context).size.height -
                                padding * 2 -
                                100,
                            child: AnimatedSwitcher(
                              duration: const Duration(
                                milliseconds: 500,
                              ),
                              child: player.currentAudio!.hasLyrics
                                  ? player.currentAudio!.lyrics != null
                                      ? TrackLyricsBlock(
                                          key: ValueKey(
                                            player.currentAudio!.mediaKey,
                                          ),
                                        )
                                      : ListView.builder(
                                          key: const ValueKey(
                                            "skeleton",
                                          ),
                                          itemCount: 50,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return Skeletonizer(
                                              child: TrackLyric(
                                                line: fakeTrackLyrics[index %
                                                    fakeTrackLyrics.length],
                                                isActive: false,
                                              ),
                                            );
                                          },
                                        )
                                  : Column(
                                      key: const ValueKey(
                                        "nolyrics",
                                      ),
                                      children: [
                                        Image.asset(
                                          "assets/images/dog.gif",
                                          width: 25 * 5,
                                          height: 12 * 5,
                                          fit: BoxFit.fill,
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        const Text(
                                          "Тс-с-с! Сегодня без караоке, собачка спит.", // TODO: INTL
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        // Информация по текущему треку и медиаплеер.
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Информация по текущему треку.
                                AnimatedSwitcher(
                                  duration: const Duration(
                                    milliseconds: 500,
                                  ),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 200,
                                    ),
                                    width: MediaQuery.of(context).size.width -
                                        padding * 2 -
                                        lyricsBlockWidth -
                                        50,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.bottomLeft,
                                      child: Row(
                                        key: ValueKey(
                                          player.currentAudio!.mediaKey,
                                        ),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Изображение трека.
                                          Hero(
                                            tag: "image",
                                            child: Container(
                                              decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                    blurRadius: 20,
                                                    spreadRadius: -1,
                                                    color: scheme!.tertiary,
                                                    blurStyle: BlurStyle.outer,
                                                  )
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  globalBorderRadius,
                                                ),
                                                child: player.currentAudio!
                                                            .album?.thumb !=
                                                        null
                                                    ? CachedNetworkImage(
                                                        imageUrl: player
                                                            .currentAudio!
                                                            .album!
                                                            .thumb!
                                                            .photo135!,
                                                        cacheKey:
                                                            "${player.currentAudio!.mediaKey}135",
                                                        width: 130,
                                                        height: 130,
                                                        fit: BoxFit.fill,
                                                        placeholder: (BuildContext
                                                                    context,
                                                                String url) =>
                                                            const FallbackAudioAvatar(),
                                                        cacheManager:
                                                            CachedNetworkImagesManager
                                                                .instance,
                                                      )
                                                    : const FallbackAudioAvatar(
                                                        width: 130,
                                                        height: 130,
                                                      ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 24,
                                          ),

                                          // Информация по названию трека и его исполнителю.
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    player.currentAudio!.title,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 36,
                                                      color: scheme!
                                                          .onPrimaryContainer,
                                                    ),
                                                  ),
                                                  if (player
                                                      .currentAudio!.isExplicit)
                                                    const SizedBox(
                                                      width: 4,
                                                    ),
                                                  if (player
                                                      .currentAudio!.isExplicit)
                                                    Icon(
                                                      Icons.explicit,
                                                      color: scheme!
                                                          .onBackground
                                                          .withOpacity(0.5),
                                                    ),
                                                ],
                                              ),
                                              Text(
                                                player.currentAudio!.artist,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  color: scheme!
                                                      .onPrimaryContainer
                                                      .withOpacity(0.75),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 18,
                                ),

                                // Slider для отображения прогресса воспроизведения трека.
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackShape: CustomTrackShape(),
                                    overlayShape:
                                        SliderComponentShape.noOverlay,
                                    inactiveTrackColor:
                                        scheme!.primary.withOpacity(0.5),
                                  ),
                                  child: Slider(
                                    value: player.progress,
                                    onChanged: (double value) {},
                                    onChangeEnd: (double newProgress) =>
                                        player.seekNormalized(newProgress),
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),

                                // Кнопки управления воспроизведением.
                                Stack(
                                  children: [
                                    // Кнопки по центру.
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: SizedBox(
                                        height: 70,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: () =>
                                                  player.setShuffle(
                                                !player.shuffleModeEnabled,
                                              ),
                                              icon: Icon(
                                                player.shuffleModeEnabled
                                                    ? Icons.shuffle_on_outlined
                                                    : Icons.shuffle,
                                                color: scheme!.primary,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            IconButton(
                                              onPressed: () => player.previous(
                                                allowSeekToBeginning: true,
                                              ),
                                              icon: Icon(
                                                Icons.skip_previous,
                                                color: scheme!.primary,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  player.togglePlay(),
                                              icon: Icon(
                                                player.playing
                                                    ? Icons.pause_circle
                                                    : Icons.play_circle,
                                                color:
                                                    scheme!.onPrimaryContainer,
                                              ),
                                              iconSize: 50,
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            IconButton(
                                              onPressed: () => player.next(),
                                              icon: Icon(
                                                Icons.skip_next,
                                                color: scheme!.primary,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            IconButton(
                                              onPressed: () => player.setLoop(
                                                player.loopMode == LoopMode.one
                                                    ? LoopMode.off
                                                    : LoopMode.one,
                                              ),
                                              icon: Icon(
                                                player.loopMode == LoopMode.one
                                                    ? Icons.repeat_on_outlined
                                                    : Icons.repeat,
                                                color: scheme!.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Остальные кнопки (выход из полноэкранного режима, ...) справа.
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: SizedBox(
                                        height: 70,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Управление громкостью.
                                            ScrollableSlider(
                                                value: player.volume,
                                                onChanged:
                                                    (double newVolume) async {
                                                  await player
                                                      .setVolume(newVolume);

                                                  // Если пользователь установил минимальную громкость, а так же настройка "Пауза при отключении громкости" включена, то ставим плеер на паузу.
                                                  if (newVolume == 0 &&
                                                      user.settings
                                                          .pauseOnMuteEnabled) {
                                                    await player.pause();
                                                  }
                                                }),
                                            const SizedBox(
                                              width: 8,
                                            ),

                                            // Выход из полноэкранного режима.
                                            IconButton(
                                              onPressed: () =>
                                                  closeFullscreenPlayer(
                                                      context),
                                              icon: Icon(
                                                Icons.fullscreen_exit,
                                                color: scheme!.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
