import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../api/shared.dart";
import "../consts.dart";
import "../utils.dart";
import "fallback_audio_photo.dart";
import "swipe_detector.dart";
import "wip_dialog.dart";

/// Виджет, располагаемый в левой части [BottomMusicPlayer], показывая информацию по текущему треку.
class TrackNameInfoWidget extends StatelessWidget {
  const TrackNameInfoWidget({
    super.key,
    required this.width,
    this.image,
    required this.scheme,
    this.useBigLayout = false,
    this.audio,
    this.onPlayStateToggle,
    this.onFavoriteStateToggle,
    this.onNextTrack,
    this.onPreviousTrack,
    this.onShuffleToggle,
    this.onRepeatToggle,
    this.onFullscreen,
    this.onDismiss,
    required this.playbackState,
    required this.favoriteState,
  });

  /// Ширина для данного блока.
  final double width;

  /// [ImageProvider], отображаемый как изображение данного трека.
  final ImageProvider? image;

  /// Цветовая схема класса [ColorScheme].
  final ColorScheme scheme;

  /// Текущий трек.
  final Audio? audio;

  /// Указывает, что в данный момент трек воспроизводится.
  final bool playbackState;

  /// Указывает, что трек в данный момент лайкнут.
  final bool favoriteState;

  /// Метод, вызываемый при переключении состояния паузы.
  final ValueSetter<bool>? onPlayStateToggle;

  /// Метод, вызываемый при изменения состояния "лайка" трека.
  final ValueSetter<bool>? onFavoriteStateToggle;

  /// Метод, вызываемый при попытке запустить следующий трек (свайп влево).
  final VoidCallback? onNextTrack;

  /// Метод, вызываемый при попытке запустить предыдущий трек (свайп вправо).
  final VoidCallback? onPreviousTrack;

  /// Метод, вызываемый при переключении режима случайного выбора треков.
  final ValueSetter<bool>? onShuffleToggle;

  /// Метод, вызываемый при переключении повтора трека.
  final ValueSetter<bool>? onRepeatToggle;

  /// Метод, вызываемый при попытке открыть полноэкранный плеер свайпов вверх.
  final VoidCallback? onFullscreen;

  /// Метод, вызываемый при попытке закрыть плеер свайпом вниз.
  final VoidCallback? onDismiss;

  /// Если [true], то тогда будет использоваться альтернативный вид плеера, который предназначен для desktop-интерфейса.
  final bool useBigLayout;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          useBigLayout ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: SwipeDetector(
        behavior: HitTestBehavior.translucent,
        onTap: !useBigLayout
            ? () => showWipDialog(
                  context,
                  title: "Плеер на всё окно",
                )
            : null,
        onDoubleTap: !useBigLayout
            ? () => onPlayStateToggle?.call(!playbackState)
            : null,
        onSwipeUp: !useBigLayout
            ? () => showWipDialog(
                  context,
                  title: "Плеер на всё окно",
                )
            : null,
        onSwipeDown: !useBigLayout ? onDismiss : null,
        onSwipeLeft: !useBigLayout ? onNextTrack : null,
        onSwipeRight: !useBigLayout ? onPreviousTrack : null,
        child: SizedBox(
          width: useBigLayout ? width : double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  child: SizedBox(
                    width: useBigLayout ? 60 : 50,
                    height: useBigLayout ? 60 : 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        globalBorderRadius,
                      ),
                      child: image != null
                          ? Image(
                              image: image!,
                            )
                          : const FallbackAudioAvatar(),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: useBigLayout ? 14 : 8,
              ),
              Flexible(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        audio?.title ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: scheme.onBackground,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        audio?.artist ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onBackground.withOpacity(
                            0.9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (useBigLayout)
                const Flexible(
                  child: SizedBox(
                    width: 12,
                  ),
                ),
              if (useBigLayout)
                Flexible(
                  child: IconButton(
                    onPressed: () =>
                        onFavoriteStateToggle?.call(!favoriteState),
                    icon: Icon(
                      favoriteState ? Icons.favorite : Icons.favorite_outline,
                      color: scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет, расположенный поверх нижней части [BottomMusicPlayer], показывая прогресс прослушивания текущего трека.
class BottomMusicProgressBar extends StatelessWidget {
  const BottomMusicProgressBar({
    super.key,
    required this.scheme,
    this.useBigLayout = false,
    this.isBuffering = false,
    this.playbackState = false,
    this.progress = 0.0,
  });

  /// Цветовая схема класса [ColorScheme].
  final ColorScheme scheme;

  /// Если [true], то тогда будет использоваться альтернативный вид плеера, который предназначен для desktop-интерфейса.
  final bool useBigLayout;

  /// Указывает, что в данный момент происходит буферизация.
  final bool isBuffering;

  /// Указывает, что в данный момент трек воспроизводится.
  final bool playbackState;

  /// Указывает прогресс прослушивания трека.
  ///
  /// В данном поле указано число от 0.0 до 1.0.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: useBigLayout ? 0 : 16,
        ),
        child: isBuffering
            ? LinearProgressIndicator(
                minHeight: 2,
                color: scheme.primary.withOpacity(
                  playbackState ? 1 : 0.5,
                ),
              )
            : FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 2,
                  color: scheme.primary.withOpacity(
                    playbackState ? 1 : 0.5,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Виджет, располагаемый выше центра [BottomMusicPlayer], показывая надпись с названием следующего трека.
class NextTrackInfoWidget extends StatelessWidget {
  const NextTrackInfoWidget({
    super.key,
    this.displayNextTrack = false,
    required this.scheme,
    required this.nextAudio,
  });

  /// Указывает, что должен показаться данный виджет.
  ///
  /// Поле должно быть равно true только перед окончанием текущего трека ([Audio.auration] * 0.9).
  final bool displayNextTrack;

  /// Цветовая схема класса [ColorScheme].
  final ColorScheme scheme;

  /// Объект [Audio], олицетворяющий следующий трек в плейлисте.
  final Audio nextAudio;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.ease,
      top: displayNextTrack ? -(70 / 2 + 25) : -(70 / 2),
      child: AnimatedOpacity(
        duration: const Duration(
          milliseconds: 200,
        ),
        curve: Curves.ease,
        opacity: displayNextTrack ? 1.0 : 0.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note,
              color: scheme.primary,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              "${nextAudio.artist} • ${nextAudio.title}",
              style: TextStyle(
                color: scheme.primary,
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Виджет плеера, отображаемый внизу экрана, отображающий информацию по текущему треку [audio], а так же дающий возможность делать базовые действия с плеером и треком.
class BottomMusicPlayer extends StatefulWidget {
  /// Объект [Audio], который играет в данный момент.
  final Audio? audio;

  /// Объект [Audio], олицетворяющий предыдущий трек в плейлисте, на который плеер сможет переключиться.
  final Audio? previousAudio;

  /// Объект [Audio], олицетворяющий следующий трек в плейлисте.
  ///
  /// Если данное поле оставить как null, то надпись, показывающая следующий трек перед завершением текущего (при [useBigLayout] = true) отображаться не будет.
  final Audio? nextAudio;

  /// Указывает, что в данный момент трек воспроизводится.
  final bool playbackState;

  /// Указывает, что трек в данный момент лайкнут.
  final bool favoriteState;

  /// Указывает прогресс прослушивания трека.
  ///
  /// В данном поле указано число от 0.0 до 1.0.
  final double progress;

  /// Указывает, что в данный момент происходит буферизация.
  final bool isBuffering;

  /// Указывает, что у плеера включён режим случайного перемешивания треков.
  final bool isShuffleEnabled;

  /// Указывает, что у плеера включён режим повтора текущего трека.
  final bool isRepeatEnabled;

  /// Указывает, что настройка "Пауза при отключении громкости" включена.
  final bool pauseOnMuteEnabled;

  /// Указывает громкость у проигрывателя.
  ///
  /// В данном поле указано число от 0.0 до 1.0.
  final double volume;

  /// Метод, вызываемый при переключении состояния паузы.
  final ValueSetter<bool>? onPlayStateToggle;

  /// Метод, вызываемый при изменения состояния "лайка" трека.
  final ValueSetter<bool>? onFavoriteStateToggle;

  /// Метод, вызываемый при попытке запустить следующий трек (свайп влево).
  final VoidCallback? onNextTrack;

  /// Метод, вызываемый при попытке запустить предыдущий трек (свайп вправо).
  final VoidCallback? onPreviousTrack;

  /// Метод, вызываемый при переключении режима случайного выбора треков.
  final ValueSetter<bool>? onShuffleToggle;

  /// Метод, вызываемый при переключении повтора трека.
  final ValueSetter<bool>? onRepeatToggle;

  /// Метод, вызываемый при попытке открыть полноэкранный плеер свайпов вверх.
  final VoidCallback? onFullscreen;

  /// Метод, вызываемый при попытке закрыть плеер свайпом вниз.
  final VoidCallback? onDismiss;

  /// Метод, вызываемый при изменении громкости.
  ///
  /// Выводом данного Callback'а является число от 0.0 до 1.0.
  final Function(double)? onVolumeChange;

  /// Если [true], то тогда будет использоваться альтернативный вид плеера, который предназначен для desktop-интерфейса.
  final bool useBigLayout;

  const BottomMusicPlayer({
    super.key,
    this.audio,
    this.previousAudio,
    this.nextAudio,
    this.playbackState = false,
    this.favoriteState = false,
    this.isBuffering = false,
    this.isShuffleEnabled = false,
    this.isRepeatEnabled = false,
    this.pauseOnMuteEnabled = false,
    this.volume = 1,
    this.progress = 0,
    this.onPlayStateToggle,
    this.onFavoriteStateToggle,
    this.onNextTrack,
    this.onPreviousTrack,
    this.onShuffleToggle,
    this.onRepeatToggle,
    this.onFullscreen,
    this.onDismiss,
    this.onVolumeChange,
    this.useBigLayout = false,
  });

  @override
  State<BottomMusicPlayer> createState() => _BottomMusicPlayerState();
}

class _BottomMusicPlayerState extends State<BottomMusicPlayer> {
  /// Последняя известная цветовая схема для данного плеера.
  ///
  /// Используется как fallback в тот момент, пока актуальный [ColorScheme] ещё не был создан.
  ColorScheme? scheme;

  @override
  Widget build(BuildContext context) {
    // Если fallback-цветовая схема плеера не была сохранена, то нам нужно её сохранить.
    scheme ??= Theme.of(context).colorScheme;

    /// Url изображения данного трека.
    final String? imageUrl = widget.audio?.album?.thumb?.photo68;

    /// Размеры блоков слева и справа (блок с названием и блок с управлением громкостью.)
    ///
    /// Данные блоки обязаны иметь одинаковый размер, поскольку в [Row] используется [MainAxisAlignment.spaceBetween].
    final double sideBlocksSize = clampDouble(
      MediaQuery.of(context).size.width / 2,
      150,
      1500,
    );

    /// Определяет по оставшейся длине трека то, стоит ли показывать надпись со следующим треком.
    final bool displayNextTrack =
        (widget.audio != null && widget.nextAudio != null)
            ? (widget.progress >= 0.9)
            : false;

    // Запускаем процесс получения ColorScheme для данного трека.
    if (imageUrl != null && widget.audio != null) {
      colorSchemeFromUrl(
        imageUrl,
        MediaQuery.of(context).platformBrightness,
        widget.audio!.mediaKey,
      ).then((ColorScheme newScheme) {
        if (scheme == newScheme) return;

        scheme = newScheme;
      });
    }

    final Widget playPauseButton = widget.useBigLayout
        ? IconButton.filled(
            onPressed: () =>
                widget.onPlayStateToggle?.call(!widget.playbackState),
            icon: Icon(
              widget.playbackState ? Icons.pause : Icons.play_arrow,
              color: scheme!.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: scheme!.onSecondary,
            ),
          )
        : IconButton(
            onPressed: () =>
                widget.onPlayStateToggle?.call(!widget.playbackState),
            icon: Icon(
              widget.playbackState ? Icons.pause : Icons.play_arrow,
              color: scheme!.primary,
            ),
          );
    final Widget shuffleButton = IconButton(
      onPressed: () => widget.onShuffleToggle?.call(!widget.isShuffleEnabled),
      icon: Icon(
        widget.isShuffleEnabled ? Icons.shuffle_on_outlined : Icons.shuffle,
        color: scheme!.primary,
      ),
    );

    return AnimatedContainer(
      height: widget.useBigLayout ? 90 : 70,
      duration: const Duration(
        milliseconds: 250,
      ),
      decoration: BoxDecoration(
        color: darkenColor(
          scheme!.primaryContainer,
          widget.playbackState ? 0 : 15,
        ),
        borderRadius: widget.useBigLayout
            ? null
            : BorderRadius.circular(globalBorderRadius),
        boxShadow: [
          BoxShadow(
            color: scheme!.secondaryContainer,
            blurRadius: widget.playbackState ? 50 : 0,
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Плеер.
          SizedBox(
            height: double.infinity,
            child: Padding(
              padding: EdgeInsets.all(
                widget.useBigLayout ? 14 : 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Блок с информацией о треке, его изображении, названия.
                  Flexible(
                    flex: 2,
                    fit: FlexFit.tight,
                    child: TrackNameInfoWidget(
                      width: sideBlocksSize,
                      scheme: scheme!,
                      audio: widget.audio,
                      image: imageUrl != null
                          ? CachedNetworkImageProvider(
                              imageUrl,
                              cacheKey: widget.audio!.mediaKey,
                            )
                          : null,
                      useBigLayout: widget.useBigLayout,
                      playbackState: widget.playbackState,
                      favoriteState: widget.favoriteState,
                      onPlayStateToggle: widget.onPlayStateToggle,
                      onFavoriteStateToggle: widget.onFavoriteStateToggle,
                      onNextTrack: widget.onNextTrack,
                      onPreviousTrack: widget.onPreviousTrack,
                      onShuffleToggle: widget.onShuffleToggle,
                      onRepeatToggle: widget.onRepeatToggle,
                      onFullscreen: widget.onFullscreen,
                      onDismiss: widget.onDismiss,
                    ),
                  ),

                  // Кнопки управления по центру в desktop-layout'е.
                  if (widget.useBigLayout)
                    Flexible(
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Надпись "Играет следующим". Если включён повтор текущего трека, то отображаем текущий трек вместо следующего.
                          if (widget.useBigLayout &&
                              (widget.isRepeatEnabled
                                  ? widget.audio != null
                                  : widget.nextAudio != null))
                            NextTrackInfoWidget(
                              displayNextTrack: displayNextTrack,
                              scheme: scheme!,
                              nextAudio: widget.isRepeatEnabled
                                  ? widget.audio!
                                  : widget.nextAudio!,
                            ),

                          // Ряд из кнопок управления.
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: shuffleButton,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Flexible(
                                child: IconButton(
                                  onPressed: widget.onPreviousTrack,
                                  icon: Icon(
                                    Icons.skip_previous,
                                    color: scheme!.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Flexible(
                                child: playPauseButton,
                              ),
                              const SizedBox(
                                width: 8,
                              ),

                              // Кнопка для запуска следующего трека.
                              Flexible(
                                child: IconButton(
                                  onPressed: widget.onNextTrack,
                                  icon: Icon(
                                    Icons.skip_next,
                                    color: scheme!.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),

                              // Кнопка повтора.
                              Flexible(
                                child: IconButton(
                                  onPressed: () => widget.onRepeatToggle
                                      ?.call(!widget.isRepeatEnabled),
                                  icon: Icon(
                                    widget.isRepeatEnabled
                                        ? Icons.repeat_on_outlined
                                        : Icons.repeat,
                                    color: scheme!.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Кнопки управления громкости и прочей мелочи справа в desktop-layout'е.
                  if (widget.useBigLayout)
                    Flexible(
                      flex: 2,
                      fit: FlexFit.tight,
                      child: SizedBox(
                        width: sideBlocksSize,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: SizedBox(
                                width: 150,
                                child: Listener(
                                  onPointerSignal: (PointerSignalEvent event) {
                                    if (event is! PointerScrollEvent) {
                                      return;
                                    }

                                    // Flutter возвращает количество как числа, кратные 100.
                                    //
                                    // Поскольку мы храним громкость как число от 0.0 до 1.0, мы должны разделить "шаг скроллинга" на 1000.
                                    // Так же, нельзя забывать, что логика здесь немного инвертирована.
                                    final double scrollAmount =
                                        (-event.scrollDelta.dy) / 1000;

                                    // Вычисляем новое значение громкости.
                                    final double newVolume = clampDouble(
                                      widget.volume + scrollAmount,
                                      0,
                                      1,
                                    );

                                    widget.onVolumeChange?.call(
                                      newVolume,
                                    );

                                    // Если пользователь установил минимальную громкость, а так же настройка "Пауза при отключении громкости" включена, то ставим плеер на паузу.
                                    if (newVolume == 0 &&
                                        widget.pauseOnMuteEnabled) {
                                      widget.onPlayStateToggle?.call(false);
                                    }
                                  },
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      overlayShape:
                                          SliderComponentShape.noThumb,
                                    ),
                                    child: Slider(
                                      value: widget.volume,
                                      onChanged: (double volume) =>
                                          widget.onVolumeChange?.call(
                                        volume,
                                      ),
                                      thumbColor: scheme!.primary,
                                      activeColor: scheme!.primary,
                                      inactiveColor: scheme!.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),

                            // Кнопка для перехода в полноэкранный режим.
                            Flexible(
                              child: FittedBox(
                                child: IconButton(
                                  onPressed: () => showWipDialog(
                                    context,
                                    title: "Плеер на весь экран (F11)",
                                  ),
                                  icon: Icon(
                                    Icons.fullscreen,
                                    color: scheme!.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Кнопки управления треком (shuffle, лайк, пауза/возобновление) справа в mobile-layout'е.
                  if (!widget.useBigLayout)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Кнопка shuffle.
                        shuffleButton,

                        // Кнопка лайка.
                        IconButton(
                          onPressed: () =>
                              widget.onFavoriteStateToggle ??
                              (!widget.favoriteState),
                          icon: Icon(
                            widget.favoriteState
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color: scheme!.primary,
                          ),
                        ),

                        // Кнопка паузы/возобновления.
                        playPauseButton,
                      ],
                    )
                ],
              ),
            ),
          ),

          // Полоска внизу для отображения прогресса трека.
          BottomMusicProgressBar(
            scheme: scheme!,
            isBuffering: widget.isBuffering,
            playbackState: widget.playbackState,
            progress: widget.progress,
            useBigLayout: widget.useBigLayout,
          )
        ],
      ),
    );
  }
}
