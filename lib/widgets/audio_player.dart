import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "../consts.dart";
import "../extensions.dart";
import "../provider/user.dart";
import "../services/cache_manager.dart";
import "../utils.dart";
import "fallback_audio_photo.dart";
import "responsive_slider.dart";
import "scrollable_slider.dart";

/// Виджет, расположенный поверх нижней части [BottomMusicPlayer], показывая прогресс прослушивания текущего трека.
class BottomMusicProgressBar extends StatelessWidget {
  const BottomMusicProgressBar({
    super.key,
    required this.scheme,
    this.isBuffering = false,
    this.playbackState = false,
    this.progress = 0.0,
  });

  /// Цветовая схема класса [ColorScheme].
  final ColorScheme scheme;

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
    return isBuffering
        ? LinearProgressIndicator(
            minHeight: 2,
            color: scheme.onPrimaryContainer.withOpacity(
              playbackState ? 1 : 0.5,
            ),
          )
        : FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 2,
              color: scheme.onPrimaryContainer.withOpacity(
                playbackState ? 1 : 0.5,
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
  /// Поле должно быть равно true только перед окончанием текущего трека ([Audio.auration] * [nextPlayingTextProgress]).
  final bool displayNextTrack;

  /// Цветовая схема класса [ColorScheme].
  final ColorScheme scheme;

  /// Объект [Audio], олицетворяющий следующий трек в плейлисте.
  final ExtendedAudio nextAudio;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(
        milliseconds: 400,
      ),
      curve: Curves.ease,
      top: displayNextTrack ? -(70 / 2 + 15) : -(70 / 2),
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет, отображающий информацию по названию трека, а так же его исполнителю.
class TrackTitleAndArtist extends StatelessWidget {
  /// Название трека.
  final String title;

  /// Исполнитель трека.
  final String artist;

  /// Цветовая схема.
  final ColorScheme scheme;

  const TrackTitleAndArtist({
    super.key,
    required this.title,
    required this.artist,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Название трека.
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: scheme.onPrimaryContainer,
          ),
        ),

        // Исполнитель.
        Text(
          artist,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onPrimaryContainer.withOpacity(
              0.9,
            ),
          ),
        ),
      ],
    );
  }
}

/// Виджет плеера, отображаемый внизу экрана, отображающий информацию по текущему треку [audio], а так же дающий возможность делать базовые действия с плеером и треком.
class BottomMusicPlayer extends StatefulWidget {
  /// Объект [ExtendedAudio], который играет в данный момент.
  final ExtendedAudio? audio;

  /// Объект [ExtendedAudio], олицетворяющий предыдущий трек в плейлисте, на который плеер сможет переключиться.
  final ExtendedAudio? previousAudio;

  /// Объект [ExtendedAudio], олицетворяющий следующий трек в плейлисте.
  ///
  /// Если данное поле оставить как null, то надпись, показывающая следующий трек перед завершением текущего (при [useBigLayout] = true) отображаться не будет.
  final ExtendedAudio? nextAudio;

  /// Указывает цветовую схему для плеера.
  final ColorScheme scheme;

  /// Указывает, что в данный момент трек воспроизводится.
  final bool playbackState;

  /// Указывает, что трек в данный момент лайкнут.
  final bool favoriteState;

  /// Указывает прогресс прослушивания трека.
  ///
  /// В данном поле указано число от 0.0 до 1.0.
  final double progress;

  /// Указывает прогресс прослушанности трека.
  final Duration position;

  /// Указывает длительность трека.
  final Duration duration;

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

  /// Метод, вызываемый при открытии мини плеера.
  final VoidCallback? onMiniplayer;

  /// Метод, вызываемый при попытке открыть полноэкранный плеер свайпом вверх, либо по нажатию на плеер.
  ///
  /// Передаёт bool, обозначающий то, что плеер был открыт при помощи свайпа, а не обычного нажатия.
  final Function(bool)? onFullscreen;

  /// Метод, вызываемый при попытке закрыть плеер свайпом вниз.
  final VoidCallback? onDismiss;

  /// Метод, вызываемый при изменении позиции трека.
  ///
  /// Выводом данного Callback'а является число от 0.0 до 1.0.
  final Function(double)? onProgressChange;

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
    required this.scheme,
    this.playbackState = false,
    this.favoriteState = false,
    this.isBuffering = false,
    this.isShuffleEnabled = false,
    this.isRepeatEnabled = false,
    this.pauseOnMuteEnabled = false,
    this.volume = 1.0,
    this.progress = 0.0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.onPlayStateToggle,
    this.onFavoriteStateToggle,
    this.onNextTrack,
    this.onPreviousTrack,
    this.onShuffleToggle,
    this.onRepeatToggle,
    this.onMiniplayer,
    this.onFullscreen,
    this.onDismiss,
    this.onProgressChange,
    this.onVolumeChange,
    this.useBigLayout = false,
  });

  @override
  State<BottomMusicPlayer> createState() => _BottomMusicPlayerState();
}

class _BottomMusicPlayerState extends State<BottomMusicPlayer> {
  /// Прогресс скроллинга блока с названием трека. Имеет значение от `-1.0` до `1.0`, где `0.0` олицетворяет то, что трек ещё не скроллился, `-1.0` - пользователь доскроллил до предыдущего трека, `1.0` - пользователь доскроллил до следующего трека.
  double _dragProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    // Размер Padding'а для всех блоков внутри Stack'а.
    final double padding = widget.useBigLayout ? 14 : 8;

    // Ширина проигрывателя.
    final double width = MediaQuery.of(context).size.width - padding * 2;

    // Размер центрального блока, в котором производится управление музыкой в Desktop Layout'е.
    final double centerBlockSize = clampDouble(
      width / 2.5,
      100,
      600,
    );

    // Размер блоков слева.
    final double leftAndRightBlocksSize =
        widget.useBigLayout ? (width - centerBlockSize) / 2 : width - 112;

    /// Url на изображение трека.
    final String? imageUrl = widget.audio?.album?.thumbnails?.photo68;

    /// Размер изображения трека.
    final double imageSize = widget.useBigLayout ? 60 : 50;

    /// Чувствительность для скроллинга.
    const scrollSensetivity = 200.0;

    /// Ширина блока для скроллинга. При увеличении данного значения, предыдущий/следующий треки будут появляться на большем расстоянии.
    const scrollWidth = 150.0;

    /// Определяет по оставшейся длине трека то, стоит ли показывать надпись со следующим треком.
    final bool displayNextTrack =
        (widget.audio != null && widget.nextAudio != null)
            ? (widget.progress >= nextPlayingTextProgress)
            : false;

    /// Кнопка для паузы и/ли воспроизведения музыки.
    final Widget playPauseButton = widget.useBigLayout
        ? IconButton(
            onPressed: () =>
                widget.onPlayStateToggle?.call(!widget.playbackState),
            iconSize: 48,
            padding: EdgeInsets.zero,
            icon: Icon(
              widget.playbackState ? Icons.pause_circle : Icons.play_circle,
              color: widget.scheme.onPrimaryContainer,
            ),
          )
        : IconButton(
            onPressed: () =>
                widget.onPlayStateToggle?.call(!widget.playbackState),
            icon: Icon(
              widget.playbackState ? Icons.pause : Icons.play_arrow,
              color: widget.scheme.onPrimaryContainer,
            ),
          );

    return AnimatedContainer(
      height: widget.useBigLayout ? 88 : 66,
      duration: const Duration(
        milliseconds: 400,
      ),
      decoration: BoxDecoration(
        color: widget.scheme.primaryContainer
            .darken(widget.playbackState ? 0 : 0.15),
        borderRadius: widget.useBigLayout
            ? null
            : BorderRadius.circular(
                globalBorderRadius,
              ),
        boxShadow: [
          BoxShadow(
            color: widget.scheme.secondaryContainer,
            blurRadius: widget.playbackState ? 50 : 0,
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Блок, отображающий изображение трека и его название.
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(
                padding,
              ),
              child: SizedBox(
                width: leftAndRightBlocksSize,
                child: MouseRegion(
                  cursor: widget.useBigLayout
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.useBigLayout
                        ? null
                        : () => widget.onFullscreen?.call(false),
                    onHorizontalDragUpdate: widget.useBigLayout
                        ? null
                        : (DragUpdateDetails details) {
                            _dragProgress = clampDouble(
                              _dragProgress -
                                  details.primaryDelta! / scrollSensetivity,
                              -1.0,
                              1.0,
                            );

                            setState(() {});
                          },
                    onHorizontalDragEnd: widget.useBigLayout
                        ? null
                        : (DragEndDetails details) {
                            if (_dragProgress > 0.5) {
                              // Запуск следующего трека.

                              widget.onNextTrack?.call();
                            } else if (_dragProgress < -0.5) {
                              // Запуск предыдущего трека.

                              widget.onPreviousTrack?.call();
                            }

                            _dragProgress = 0.0;
                            setState(() {});
                          },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Изображение трека.
                        SizedBox(
                          width: imageSize,
                          height: imageSize,
                          child: InkWell(
                            onTap: () => widget.onFullscreen?.call(false),
                            child: Hero(
                              tag: widget.audio?.mediaKey ?? "",
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 10,
                                      spreadRadius: -3,
                                      color: widget.scheme.tertiary,
                                      blurStyle: BlurStyle.outer,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    globalBorderRadius,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(
                                      milliseconds: 400,
                                    ),
                                    child: SizedBox(
                                      key: ValueKey(
                                        imageUrl != null
                                            ? widget.audio!.album?.id
                                            : null,
                                      ),
                                      width: imageSize,
                                      height: imageSize,
                                      child: imageUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              cacheKey:
                                                  "${widget.audio!.album!.id}68",
                                              memCacheHeight: imageSize.toInt(),
                                              memCacheWidth: imageSize.toInt(),
                                              placeholder: (
                                                BuildContext context,
                                                String url,
                                              ) =>
                                                  const FallbackAudioAvatar(),
                                              cacheManager:
                                                  CachedAlbumImagesManager
                                                      .instance,
                                            )
                                          : const FallbackAudioAvatar(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: widget.useBigLayout ? 14 : 8,
                        ),

                        // Название и исполнитель трека.
                        Flexible(
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              // Текущий трек.
                              ClipRRect(
                                child: Transform.translate(
                                  offset: Offset(
                                    _dragProgress * -scrollWidth,
                                    0.0,
                                  ),
                                  child: Opacity(
                                    opacity: 1.0 - _dragProgress.abs(),
                                    child: SizedBox(
                                      width: widget.useBigLayout
                                          ? null
                                          : double.infinity,
                                      child: TrackTitleAndArtist(
                                        title: widget.audio?.title ?? "",
                                        artist: widget.audio?.artist ?? "",
                                        scheme: widget.scheme,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Другой трек.
                              if (_dragProgress != 0.0)
                                ClipRRect(
                                  child: Transform.translate(
                                    offset: Offset(
                                      (_dragProgress > 0.0
                                              ? scrollWidth
                                              : -scrollWidth) -
                                          _dragProgress * scrollWidth,
                                      0.0,
                                    ),
                                    child: Opacity(
                                      opacity: _dragProgress.abs(),
                                      child: SizedBox(
                                        width: widget.useBigLayout
                                            ? null
                                            : double.infinity,
                                        child: _dragProgress > 0.0
                                            ? TrackTitleAndArtist(
                                                title:
                                                    widget.nextAudio?.title ??
                                                        "",
                                                artist:
                                                    widget.nextAudio?.artist ??
                                                        "",
                                                scheme: widget.scheme,
                                              )
                                            : TrackTitleAndArtist(
                                                title: widget
                                                        .previousAudio?.title ??
                                                    "",
                                                artist: widget.previousAudio
                                                        ?.artist ??
                                                    "",
                                                scheme: widget.scheme,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (widget.useBigLayout)
                          const SizedBox(
                            width: 12,
                          ),

                        // Кнопка для лайка (в Desktop Layout'е).
                        if (widget.useBigLayout)
                          IconButton(
                            onPressed: () => widget.onFavoriteStateToggle
                                ?.call(!widget.favoriteState),
                            icon: Icon(
                              widget.favoriteState
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: widget.scheme.onPrimaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Кнопки управления плеером по центру в Desktop Layout'е.
          if (widget.useBigLayout)
            Align(
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
                      scheme: widget.scheme,
                      nextAudio: widget.isRepeatEnabled
                          ? widget.audio!
                          : widget.nextAudio!,
                    ),

                  // Ряд из кнопок управления плеером в Desktop Layout'е.
                  SizedBox(
                    width: centerBlockSize,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Индикатор буферизации.
                        if (widget.isBuffering)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            child: LinearProgressIndicator(
                              borderRadius: BorderRadius.circular(
                                globalBorderRadius,
                              ),
                              backgroundColor: widget.scheme.onPrimaryContainer
                                  .withOpacity(0.5),
                            ),
                          ),

                        // Slider для отображения прогресса воспроизведения трека.
                        if (!widget.isBuffering)
                          SliderTheme(
                            data: SliderThemeData(
                              trackShape: CustomTrackShape(),
                              overlayShape: SliderComponentShape.noOverlay,
                              activeTrackColor:
                                  widget.scheme.onPrimaryContainer,
                              thumbColor: widget.scheme.onPrimaryContainer,
                              inactiveTrackColor: widget
                                  .scheme.onPrimaryContainer
                                  .withOpacity(0.5),
                            ),
                            child: ResponsiveSlider(
                              value: widget.progress,
                              onChangeEnd: widget.onProgressChange,
                            ),
                          ),

                        // Информация о длительности трека, а так же кнопки управления снизу.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Текущая позиция трека.
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  secondsAsString(
                                    widget.position.inSeconds,
                                  ),
                                  style: TextStyle(
                                    color: widget.scheme.onPrimaryContainer
                                        .withOpacity(0.75),
                                  ),
                                ),
                              ),
                            ),

                            // Кнопки снизу.
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => widget.onShuffleToggle
                                      ?.call(!widget.isShuffleEnabled),
                                  icon: Icon(
                                    widget.isShuffleEnabled
                                        ? Icons.shuffle_on_outlined
                                        : Icons.shuffle,
                                    color: widget.scheme.onPrimaryContainer,
                                  ),
                                ),

                                // Прерыдущий трек.
                                IconButton(
                                  onPressed: widget.onPreviousTrack,
                                  icon: Icon(
                                    Icons.skip_previous,
                                    color: widget.scheme.onPrimaryContainer,
                                  ),
                                ),

                                // Кнопка паузы/воспроизведения.
                                playPauseButton,

                                // Кнопка для запуска следующего трека.
                                IconButton(
                                  onPressed: widget.onNextTrack,
                                  icon: Icon(
                                    Icons.skip_next,
                                    color: widget.scheme.onPrimaryContainer,
                                  ),
                                ),

                                // Кнопка повтора.
                                IconButton(
                                  onPressed: () => widget.onRepeatToggle
                                      ?.call(!widget.isRepeatEnabled),
                                  icon: Icon(
                                    widget.isRepeatEnabled
                                        ? Icons.repeat_on_outlined
                                        : Icons.repeat,
                                    color: widget.scheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),

                            // Полная длительность трека.
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  secondsAsString(
                                    widget.duration.inSeconds,
                                  ),
                                  style: TextStyle(
                                    color: widget.scheme.onPrimaryContainer
                                        .withOpacity(0.75),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Кнопки управления громкости и прочей мелочи справа в Desktop Layout'е.
          if (widget.useBigLayout)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(
                  padding,
                ),
                child: SizedBox(
                  width: leftAndRightBlocksSize,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Управление громкостью.
                      if (isDesktop)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 10,
                            ),
                            child: SizedBox(
                              width: 150,
                              child: ScrollableSlider(
                                value: widget.volume,
                                activeColor: widget.scheme.onPrimaryContainer,
                                inactiveColor: widget.scheme.onPrimaryContainer
                                    .withOpacity(0.5),
                                onChanged: (double newVolume) {
                                  widget.onVolumeChange?.call(newVolume);

                                  // Если пользователь установил минимальную громкость, а так же настройка "Пауза при отключении громкости" включена, то ставим плеер на паузу.
                                  if (newVolume == 0 &&
                                      widget.pauseOnMuteEnabled) {
                                    widget.onPlayStateToggle?.call(false);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),

                      // Кнопка для перехода в мини плеер.
                      if (isDesktop)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 2,
                          ),
                          child: IconButton(
                            onPressed: widget.onMiniplayer,
                            icon: Icon(
                              Icons.picture_in_picture_alt,
                              color: widget.scheme.onPrimaryContainer,
                            ),
                          ),
                        ),

                      // Кнопка для перехода в полноэкранный режим.
                      if (isDesktop)
                        IconButton(
                          onPressed: () => widget.onFullscreen?.call(false),
                          icon: Icon(
                            Icons.fullscreen,
                            color: widget.scheme.onPrimaryContainer,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Кнопки для управления справа в Mobile Layout'е.
          if (!widget.useBigLayout)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.all(
                  padding,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Кнопка лайка.
                    IconButton(
                      onPressed: () => widget.onFavoriteStateToggle
                          ?.call(!widget.favoriteState),
                      icon: Icon(
                        widget.favoriteState
                            ? Icons.favorite
                            : Icons.favorite_outline,
                        color: widget.scheme.onPrimaryContainer,
                      ),
                    ),

                    // Кнопка паузы/возобновления.
                    playPauseButton,
                  ],
                ),
              ),
            ),

          // Полоска внизу для отображения прогресса трека в Mobile Layout'е.
          if (!widget.useBigLayout)
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                child: Transform.translate(
                  offset: const Offset(
                    0,
                    0.5,
                  ),
                  child: BottomMusicProgressBar(
                    scheme: widget.scheme,
                    isBuffering: widget.isBuffering,
                    playbackState: widget.playbackState,
                    progress: widget.progress,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
