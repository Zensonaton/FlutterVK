import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../consts.dart";
import "../extensions.dart";
import "../provider/color.dart";
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
            // Иконка ноты.
            Icon(
              Icons.music_note,
              color: scheme.primary,
            ),
            const Gap(8),

            // Название для следующего трека.
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

  /// Подпись трека.
  final String? subtitle;

  /// Указывает, что это Explicit-трек.
  final bool explicit;

  /// Цветовая схема.
  final ColorScheme scheme;

  const TrackTitleAndArtist({
    super.key,
    required this.title,
    required this.artist,
    this.subtitle,
    this.explicit = false,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Информация по названию трека и прочей информацией.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Название трека.
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),

            // Плашка "Explicit".
            if (explicit)
              Padding(
                padding: const EdgeInsets.only(
                  left: 4,
                ),
                child: Icon(
                  Icons.explicit,
                  color: scheme.onPrimaryContainer.withOpacity(0.5),
                  size: 14,
                ),
              ),

            // Подпись трека.
            if (subtitle != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 6,
                  ),
                  child: Text(
                    subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onPrimaryContainer.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Исполнитель.
        Text(
          artist,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onPrimaryContainer.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

/// Виджет плеера, отображаемый внизу экрана, отображающий информацию по текущему треку [audio], а так же дающий возможность делать базовые действия с плеером и треком.
class BottomMusicPlayer extends HookConsumerWidget {
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

  /// Метод, вызываемый при нажатии кнопки "дизлайка" у трека.
  final VoidCallback? onDislike;

  /// Метод, вызываемый при попытке запустить следующий трек (свайп влево).
  final VoidCallback? onNextTrack;

  /// Метод, вызываемый при попытке запустить предыдущий трек (свайп вправо).
  final VoidCallback? onPreviousTrack;

  /// Метод, вызываемый при переключении режима случайного выбора треков.
  ///
  /// Если не указать, то кнопка будет неактивна.
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
    this.onDislike,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final schemeInfo = ref.watch(trackSchemeInfoProvider);

    final dragProgress = useState(0.0);

    // Размер Padding'а для всех блоков внутри Stack'а.
    final double padding = useBigLayout ? 14 : 8;

    // Ширина проигрывателя.
    final double width = MediaQuery.of(context).size.width - padding * 2 - 16;

    // Размер центрального блока, в котором производится управление музыкой в Desktop Layout'е.
    final double centerBlockSize = clampDouble(
      width / 2.5,
      100,
      600,
    );

    /// Размер блоков слева.
    final double leftAndRightBlocksSize = useBigLayout
        ? (width - centerBlockSize) / 2
        : width - (onDislike != null ? 146 : 96);

    /// Url на изображение трека.
    final String? imageUrl = audio?.smallestThumbnail;

    /// Размер изображения трека.
    final double imageSize = useBigLayout ? 60 : 50;

    /// Чувствительность для скроллинга.
    const scrollSensetivity = 200.0;

    /// Ширина блока для скроллинга. При увеличении данного значения, предыдущий/следующий треки будут появляться на большем расстоянии.
    const scrollWidth = 150.0;

    /// Определяет по оставшейся длине трека то, стоит ли показывать надпись со следующим треком.
    final bool displayNextTrack = (audio != null && nextAudio != null)
        ? (progress >= nextPlayingTextProgress)
        : false;

    /// Кнопка для паузы и/ли воспроизведения музыки.
    final Widget playPauseButton = useBigLayout
        ? IconButton(
            onPressed: () => onPlayStateToggle?.call(!playbackState),
            iconSize: 48,
            padding: EdgeInsets.zero,
            icon: Icon(
              playbackState ? Icons.pause_circle : Icons.play_circle,
              color: scheme.onPrimaryContainer,
            ),
          )
        : IconButton(
            onPressed: () => onPlayStateToggle?.call(!playbackState),
            icon: Icon(
              playbackState ? Icons.pause : Icons.play_arrow,
              color: scheme.onPrimaryContainer,
            ),
          );

    /// Указывает, что кнопка для переключения shuffle работает.
    final bool canToggleShuffle = onShuffleToggle != null;

    /// [Widget] для отображения изображения этого трека.
    final Widget trackImageWidget = imageUrl != null
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            cacheKey: "${audio!.mediaKey}small",
            cacheManager: CachedAlbumImagesManager.instance,
            placeholder: (BuildContext context, String url) {
              return const FallbackAudioAvatar();
            },
            fit: BoxFit.contain,
          )
        : const FallbackAudioAvatar();

    return AnimatedContainer(
      height: useBigLayout ? 88 : 66,
      duration: const Duration(
        milliseconds: 400,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.darken(
          playbackState ? 0 : 0.15,
        ),
        borderRadius: useBigLayout
            ? null
            : BorderRadius.circular(
                globalBorderRadius,
              ),
        boxShadow: [
          if (playbackState)
            BoxShadow(
              color: scheme.secondaryContainer,
              blurRadius: playbackState ? 50 : 0,
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
                child: ScrollableWidget(
                  onChanged: (double diff) {
                    if (useBigLayout || isMobile) return;

                    return onVolumeChange?.call(
                      clampDouble(volume + diff / 10, 0.0, 1.0),
                    );
                  },
                  child: MouseRegion(
                    cursor: useBigLayout
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap:
                          useBigLayout ? null : () => onFullscreen?.call(false),
                      onHorizontalDragUpdate: useBigLayout
                          ? null
                          : (DragUpdateDetails details) =>
                              dragProgress.value = clampDouble(
                                dragProgress.value -
                                    details.primaryDelta! / scrollSensetivity,
                                -1.0,
                                1.0,
                              ),
                      onHorizontalDragEnd: useBigLayout
                          ? null
                          : (DragEndDetails details) {
                              if (dragProgress.value > 0.5) {
                                // Запуск следующего трека.

                                onNextTrack?.call();
                              } else if (dragProgress.value < -0.5) {
                                // Запуск предыдущего трека.

                                onPreviousTrack?.call();
                              }

                              dragProgress.value = 0.0;
                            },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Изображение трека.
                          SizedBox(
                            width: imageSize,
                            height: imageSize,
                            child: InkWell(
                              onTap: () => onFullscreen?.call(false),
                              child: Hero(
                                tag: audio?.mediaKey ?? "",
                                child: AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds: 200,
                                  ),
                                  curve: Curves.ease,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      if (playbackState)
                                        BoxShadow(
                                          blurRadius: 10,
                                          spreadRadius: -3,
                                          color: (audio?.thumbnail != null
                                                  ? schemeInfo?.frequentColor
                                                  : null) ??
                                              Colors.blueGrey,
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
                                              ? audio!.mediaKey
                                              : null,
                                        ),
                                        width: imageSize,
                                        height: imageSize,
                                        child: trackImageWidget,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Gap(useBigLayout ? 14 : 8),

                          // Название и исполнитель трека.
                          Flexible(
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Текущий трек.
                                ClipRRect(
                                  child: Transform.translate(
                                    offset: Offset(
                                      dragProgress.value * -scrollWidth,
                                      0.0,
                                    ),
                                    child: Opacity(
                                      opacity: 1.0 - dragProgress.value.abs(),
                                      child: SizedBox(
                                        width: useBigLayout
                                            ? null
                                            : double.infinity,
                                        child: TrackTitleAndArtist(
                                          title: audio?.title ?? "",
                                          artist: audio?.artist ?? "",
                                          subtitle: audio?.subtitle,
                                          explicit: audio?.isExplicit ?? false,
                                          scheme: scheme,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Другой трек.
                                if (dragProgress.value != 0.0)
                                  ClipRRect(
                                    child: Transform.translate(
                                      offset: Offset(
                                        (dragProgress.value > 0.0
                                                ? scrollWidth
                                                : -scrollWidth) -
                                            dragProgress.value * scrollWidth,
                                        0.0,
                                      ),
                                      child: Opacity(
                                        opacity: dragProgress.value.abs(),
                                        child: SizedBox(
                                          width: useBigLayout
                                              ? null
                                              : double.infinity,
                                          child: dragProgress.value > 0.0
                                              ? TrackTitleAndArtist(
                                                  title: nextAudio?.title ?? "",
                                                  artist:
                                                      nextAudio?.artist ?? "",
                                                  subtitle: nextAudio?.subtitle,
                                                  explicit:
                                                      nextAudio?.isExplicit ??
                                                          false,
                                                  scheme: scheme,
                                                )
                                              : TrackTitleAndArtist(
                                                  title: previousAudio?.title ??
                                                      "",
                                                  artist:
                                                      previousAudio?.artist ??
                                                          "",
                                                  subtitle:
                                                      previousAudio?.subtitle,
                                                  explicit: previousAudio
                                                          ?.isExplicit ??
                                                      false,
                                                  scheme: scheme,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (useBigLayout) const Gap(8),

                          // Кнопка для лайка (в Desktop Layout'е).
                          if (useBigLayout)
                            IconButton(
                              onPressed: () =>
                                  onFavoriteStateToggle?.call(!favoriteState),
                              icon: Icon(
                                favoriteState
                                    ? Icons.favorite
                                    : Icons.favorite_outline,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),

                          // Кнопка для дизлайка (в Desktop Layout'е).
                          if (useBigLayout && onDislike != null)
                            IconButton(
                              onPressed: onDislike,
                              icon: Icon(
                                Icons.thumb_down_outlined,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Кнопки управления плеером по центру в Desktop Layout'е.
          if (useBigLayout)
            Align(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Надпись "Играет следующим". Если включён повтор текущего трека, то отображаем текущий трек вместо следующего.
                  if (useBigLayout &&
                      (isRepeatEnabled ? audio != null : nextAudio != null))
                    NextTrackInfoWidget(
                      displayNextTrack: displayNextTrack,
                      scheme: scheme,
                      nextAudio: isRepeatEnabled ? audio! : nextAudio!,
                    ),

                  // Ряд из кнопок управления плеером в Desktop Layout'е.
                  SizedBox(
                    width: centerBlockSize,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Индикатор буферизации.
                        if (isBuffering)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            child: LinearProgressIndicator(
                              borderRadius: BorderRadius.circular(
                                globalBorderRadius,
                              ),
                              backgroundColor:
                                  scheme.onPrimaryContainer.withOpacity(0.5),
                            ),
                          ),

                        // Slider для отображения прогресса воспроизведения трека.
                        if (!isBuffering)
                          SliderTheme(
                            data: SliderThemeData(
                              trackShape: CustomTrackShape(),
                              overlayShape: SliderComponentShape.noOverlay,
                              activeTrackColor: scheme.onPrimaryContainer,
                              thumbColor: scheme.onPrimaryContainer,
                              inactiveTrackColor:
                                  scheme.onPrimaryContainer.withOpacity(0.5),
                            ),
                            child: ResponsiveSlider(
                              value: progress,
                              onChangeEnd: onProgressChange,
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
                                    position.inSeconds,
                                  ),
                                  style: TextStyle(
                                    color: scheme.onPrimaryContainer
                                        .withOpacity(0.75),
                                  ),
                                ),
                              ),
                            ),

                            // Кнопки снизу.
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Кнопка для переключения shuffle.
                                IconButton(
                                  onPressed: canToggleShuffle
                                      ? () => onShuffleToggle
                                          ?.call(!isShuffleEnabled)
                                      : null,
                                  icon: Icon(
                                    isShuffleEnabled
                                        ? Icons.shuffle_on_outlined
                                        : Icons.shuffle,
                                    color: canToggleShuffle
                                        ? scheme.onPrimaryContainer
                                        : null,
                                  ),
                                ),

                                // Предыдущий трек.
                                IconButton(
                                  onPressed: onPreviousTrack,
                                  icon: Icon(
                                    Icons.skip_previous,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),

                                // Кнопка паузы/воспроизведения.
                                playPauseButton,

                                // Кнопка для запуска следующего трека.
                                IconButton(
                                  onPressed: onNextTrack,
                                  icon: Icon(
                                    Icons.skip_next,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),

                                // Кнопка повтора.
                                IconButton(
                                  onPressed: () =>
                                      onRepeatToggle?.call(!isRepeatEnabled),
                                  icon: Icon(
                                    isRepeatEnabled
                                        ? Icons.repeat_on_outlined
                                        : Icons.repeat,
                                    color: scheme.onPrimaryContainer,
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
                                    duration.inSeconds,
                                  ),
                                  style: TextStyle(
                                    color: scheme.onPrimaryContainer
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
          if (useBigLayout)
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
                                value: volume,
                                activeColor: scheme.onPrimaryContainer,
                                inactiveColor:
                                    scheme.onPrimaryContainer.withOpacity(0.5),
                                onChanged: (double newVolume) {
                                  if (isMobile) return;

                                  onVolumeChange?.call(newVolume);
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
                            onPressed: onMiniplayer,
                            icon: Icon(
                              Icons.picture_in_picture_alt,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),

                      // Кнопка для перехода в полноэкранный режим.
                      if (isDesktop)
                        IconButton(
                          onPressed: () => onFullscreen?.call(false),
                          icon: Icon(
                            Icons.fullscreen,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Кнопки для управления справа в Mobile Layout'е.
          if (!useBigLayout)
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
                      onPressed: () =>
                          onFavoriteStateToggle?.call(!favoriteState),
                      icon: Icon(
                        favoriteState ? Icons.favorite : Icons.favorite_outline,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),

                    // Кнопка для дизлайка.
                    if (onDislike != null)
                      IconButton(
                        onPressed: onDislike,
                        icon: Icon(
                          Icons.thumb_down_outlined,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),

                    // Кнопка паузы/возобновления.
                    playPauseButton,
                  ],
                ),
              ),
            ),

          // Полоска внизу для отображения прогресса трека в Mobile Layout'е.
          if (!useBigLayout)
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
                    scheme: scheme,
                    isBuffering: isBuffering,
                    playbackState: playbackState,
                    progress: progress,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
