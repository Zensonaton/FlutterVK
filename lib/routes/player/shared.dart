import "dart:async";
import "dart:math";
import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:media_kit/media_kit.dart" as mk;
import "package:media_kit_video/media_kit_video.dart";
import "package:scroll_to_index/scroll_to_index.dart";

import "../../api/vk/audio/get_lyrics.dart";
import "../../consts.dart";
import "../../provider/player.dart";
import "../../provider/preferences.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/audio_track.dart";
import "../../widgets/fallback_audio_photo.dart";
import "../../widgets/responsive_slider.dart";
import "../../widgets/wavy_slider.dart";

/// Отображает отдельную строчку в тексте песни.
class LyricWidget extends StatelessWidget {
  /// Длительность перехода между строчками.
  static const Duration transitionDuration = Duration(milliseconds: 250);

  /// Curve для перехода между строчками.
  static const Curve transitionCurve = Curves.ease;

  /// Возвращает значение прозрачности (alpha) для строчки с указанным расстоянием.
  static double getDistanceAlpha(int distance) {
    const maxDistance = 5;
    const minAlpha = 0.1;
    const maxAlpha = 1.0;

    final normalizedDistance = (distance.abs() / maxDistance).clamp(0.0, 1.0);
    return maxAlpha - (normalizedDistance * (maxAlpha - minAlpha));
  }

  /// Текст строчки.
  ///
  /// Если не указан, то будет использоваться иконка ноты.
  final String? line;

  /// Указывает, что эта строчка воспроизводится в данный момент.
  ///
  /// У такой строчки текст будет увеличен.
  final bool isActive;

  /// Расстояние от активной строчки (т.е., той, которая воспроизводится в данный момент) от этой строчки.
  ///
  /// Если число отрицательное, то считается, что это старая строчка, если положительное - то строчка ещё не была воспроизведена.
  final int distance;

  /// Действие, вызываемое при нажатии на эту строчку.
  ///
  /// Если не указано, то нажатие будет проигнорировано, а так же текст не будет располагаться по центру.
  final void Function()? onTap;

  const LyricWidget({
    super.key,
    this.line,
    this.isActive = false,
    this.distance = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.of(context);

    final isSynchronized = onTap != null;
    final isInterlide = line == null;
    final alignment = isSynchronized ? Alignment.center : Alignment.centerLeft;
    final textAlign = isSynchronized ? TextAlign.center : TextAlign.start;
    final fontWeight = isSynchronized ? FontWeight.w500 : FontWeight.w400;
    final color = scheme.primary.withValues(
      alpha: getDistanceAlpha(distance),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 50,
          ),
          child: AnimatedScale(
            duration: transitionDuration,
            curve: transitionCurve,
            scale: isActive ? 1.2 : 1,
            child: isInterlide
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                    ),
                    child: Align(
                      alignment: alignment,
                      child: Icon(
                        Icons.music_note,
                        size: 20,
                        color: color,
                      ),
                    ),
                  )
                : Text(
                    line!,
                    textAlign: textAlign,
                    style: TextStyle(
                      fontSize: 20,
                      color: color,
                      fontWeight: fontWeight,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Виджет, отображаемый для блоков "воспроизведение плейлиста" и "источник текста песни", который отображает нужную иконку, а при наведении заменяет её крестиком.
class CategoryIconWidget extends HookConsumerWidget {
  /// Длительность анимации смены иконки.
  static const Duration animationDuration = Duration(milliseconds: 200);

  /// Иконка.
  final IconData icon;

  /// Действие, вызваемое при нажатии на кнопку закрытия этого блока.
  ///
  /// Если не указано, то кнопка закрытия не будет отображена.
  final VoidCallback? onClose;

  const CategoryIconWidget({
    super.key,
    required this.icon,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);

    final scheme = ColorScheme.of(context);

    final showCloseIcon = onClose != null && isHovered.value;

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: InkWell(
        onTap: onClose,
        child: AnimatedSwitcher(
          duration: animationDuration,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Icon(
            key: ValueKey(
              showCloseIcon,
            ),
            showCloseIcon ? Icons.close : icon,
            color: showCloseIcon ? scheme.error : scheme.onPrimaryContainer,
            size: 50,
          ),
        ),
      ),
    );
  }
}

/// Виджет, отображающий текст, находящийся сверху блоков.
class CategoryTextWidget extends StatelessWidget {
  /// Иконка, отображаемая слева либо справа, в зависимости от [isLeft].
  final IconData icon;

  /// Верхний текст.
  final String header;

  /// Текст ниже.
  final String text;

  /// Указывает, что данный блок расположен слева.
  final bool isLeft;

  /// Действие, вызваемое при нажатии на кнопку закрытия этого блока.
  ///
  /// Если не указано, то кнопка закрытия не будет отображена.
  final VoidCallback? onClose;

  const CategoryTextWidget({
    super.key,
    required this.icon,
    required this.header,
    required this.text,
    required this.isLeft,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final categoryIcon = CategoryIconWidget(
      icon: icon,
      onClose: onClose,
    );
    final align = isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final textAlign = isLeft ? TextAlign.start : TextAlign.end;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        if (isLeft) categoryIcon,
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: align,
            children: [
              Text(
                header,
                textAlign: textAlign,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                text,
                textAlign: textAlign,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        if (!isLeft) categoryIcon,
      ],
    );
  }
}

/// Виджет, отображающий blurred-изображение переданного трека, используемый для эффекта "свечения".
///
/// Возвращает [SizedBox.shrink], если обложка не была найдена.
class BackgroundGlowImageWidget extends StatelessWidget {
  /// Сила размытия изображения для эффекта "свечения".
  static const double blur = 30;

  /// Трек, изображение которого будет использовано.
  final ExtendedAudio audio;

  const BackgroundGlowImageWidget({
    super.key,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    if (audio.smallestThumbnail == null) {
      return const SizedBox.shrink(
        key: ValueKey(null),
      );
    }

    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blur,
        sigmaY: blur,
        tileMode: TileMode.decal,
      ),
      child: CachedNetworkImage(
        imageUrl: audio.smallestThumbnail!,
        cacheKey: "${audio.mediaKey}small",
        cacheManager: CachedAlbumImagesManager.instance,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        fit: BoxFit.fill,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}

/// Виджет, отображающий большое изображение трека.
///
/// Возвращает [FallbackAudioAvatar], если обложка не была найдена.
class AudioImageWidget extends StatelessWidget {
  /// Трек, изображение которого будет использовано.
  final ExtendedAudio? audio;

  /// Размер изображения.
  final double size;

  /// Радиус скругления углов.
  final double borderRadius;

  const AudioImageWidget({
    super.key,
    this.audio,
    required this.size,
    this.borderRadius = globalBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (audio?.maxThumbnail == null) {
      return FallbackAudioAvatar(
        key: const ValueKey(null),
        borderRadius: borderRadius,
        size: size,
      );
    }

    return ClipRRect(
      key: ValueKey(
        audio!.maxThumbnail,
      ),
      borderRadius: BorderRadius.circular(
        borderRadius,
      ),
      child: CachedNetworkImage(
        imageUrl: audio!.maxThumbnail!,
        cacheKey: "${audio!.mediaKey}max",
        placeholder: (BuildContext context, String string) {
          return const FallbackAudioAvatar();
        },
        cacheManager: CachedAlbumImagesManager.instance,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        width: size,
        height: size,
        placeholderFadeInDuration: Duration.zero,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Виджет, отображающий анимированную обложку трека, полученную с Apple Music.
///
/// Возвращает [SizedBox.shrink], если обложка не была найдена.
class AudioAnimatedImageWidget extends HookConsumerWidget {
  static final AppLogger logger = getLogger("AudioAnimatedImageWidget");

  /// Трек, изображение которого будет использовано.
  final ExtendedAudio audio;

  /// Размер изображения.
  final double size;

  /// Радиус скругления углов.
  final double borderRadius;

  const AudioAnimatedImageWidget({
    super.key,
    required this.audio,
    required this.size,
    this.borderRadius = globalBorderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (audio.appleMusicThumbs == null) {
      return const SizedBox.shrink(
        key: ValueKey(null),
      );
    }

    final animatedPlayerPlaying = useState(false);
    final animatedPlayer = useMemoized(
      () {
        final player = mk.Player(
          configuration: const mk.PlayerConfiguration(
            muted: true,
          ),
        );
        player.setPlaylistMode(mk.PlaylistMode.single);

        return player;
      },
    );
    final controller = useMemoized(
      () => VideoController(animatedPlayer),
    );
    useEffect(
      () {
        final subscriptions = [
          animatedPlayer.stream.buffering.listen((isBuffering) {
            animatedPlayerPlaying.value = !isBuffering;

            logger.d(
              "Is playing: ${animatedPlayerPlaying.value}, buffer: ${animatedPlayer.state.buffer}",
            );
          }),
        ];

        return () {
          for (final subscription in subscriptions) {
            subscription.cancel();
          }
        };
      },
      [],
    );

    final animatedThumbUrl = useMemoized(
      () {
        final thumbs = audio.appleMusicThumbs;
        if (thumbs == null || thumbs.isEmpty) return null;

        thumbs.sort(
          (a, b) => a.resolution.compareTo(b.resolution),
        );

        final index = thumbs.indexWhere(
          (thumb) => thumb.resolution >= size,
        );
        return thumbs[min(index + 1, thumbs.length - 1)].url;
      },
      [audio.appleMusicThumbs],
    );
    useEffect(
      () {
        if (animatedThumbUrl == null) {
          animatedPlayer.stop();

          return null;
        }

        logger.d(
          "Will play animated thumb: $animatedThumbUrl for size ${size.round()}",
        );
        animatedPlayer.open(
          mk.Media(animatedThumbUrl),
        );
        return null;
      },
      [animatedThumbUrl],
    );
    useEffect(
      () {
        return () {
          logger.d("Disposing");

          animatedPlayer.dispose();
        };
      },
      [],
    );

    return ClipRRect(
      key: ValueKey(
        animatedThumbUrl,
      ),
      borderRadius: BorderRadius.circular(
        borderRadius,
      ),
      child: Video(
        controller: controller,
        controls: NoVideoControls,
        wakelock: false,
        fill: Colors.transparent,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Виджет, отображающий анимированный [Slider], а так же [Text]'ы, отображающие прогресс воспроизведения, а так же длительность трека.
class SliderWithProgressWidget extends HookConsumerWidget {
  /// Указывает, будут ли отображены [Text]'ы для показа оставшегося времени.
  final bool showTime;

  const SliderWithProgressWidget({
    super.key,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerPositionProvider);

    final showRemainingTime = ref.watch(
      preferencesProvider.select((value) {
        return value.showRemainingTime;
      }),
    );

    final isPlaying = player.isPlaying;
    final position = player.position.inSeconds;
    final duration =
        (player.duration != Duration.zero ? player.duration : null) ??
            player.audio?.duration;

    final durationString = useMemoized(
      () => durationAsString(duration ?? Duration.zero),
      [duration],
    );

    final sliderWaveAnimation = useAnimationController(
      duration: MusicPlayerWidget.sliderWaveAnimationDuration,
      initialValue: isPlaying ? 1.0 : 0.0,
    );
    useValueListenable(sliderWaveAnimation);
    useEffect(
      () {
        if (!context.mounted) return;
        sliderWaveAnimation.animateTo(
          isPlaying ? 1.0 : 0.0,
          curve: Curves.easeInOutCubicEmphasized,
        );

        return null;
      },
      [isPlaying],
    );

    final sliderWaveOffsetAnimation = useAnimationController(
      duration: MusicPlayerWidget.sliderWaveOffsetAnimationDuration,
    );
    useValueListenable(sliderWaveOffsetAnimation);
    useEffect(
      () {
        if (!context.mounted) return;
        if (isPlaying) {
          sliderWaveOffsetAnimation.repeat();
        } else {
          sliderWaveOffsetAnimation.stop();
        }

        return null;
      },
      [isPlaying],
    );

    final positionAnimation = useAnimationController(
      duration: MusicPlayerWidget.sliderAnimationDuration,
      initialValue: player.progress,
    );
    void runSeekAnimation({double? progress}) {
      positionAnimation.animateTo(
        progress ?? player.progress,
        curve: Curves.easeInOutCubicEmphasized,
      );
    }

    final seekPosition = useState<double?>(null);

    useEffect(
      () {
        final List<StreamSubscription> subscriptions = [
          player.audioStream.listen((_) {
            runSeekAnimation(progress: 0.0);
          }),
          player.seekStream.listen((_) {
            runSeekAnimation();
          }),
          player.positionStream.listen((_) async {
            // Эта задержка нужна, что бы событие изменения позиции обрабатывалось слегка позже,
            // чем обработчики события audioStream или seekStream.
            await Future.delayed(
              const Duration(
                milliseconds: 1,
              ),
            );

            if (!context.mounted) return;

            // Если анимация Slider'а переключения идёт, то ничего не меняем.
            // Единственное, когда нам разрешено менять значение, это когда
            // текущее значение меньше, чем значение воспроизведения.
            if (positionAnimation.isAnimating &&
                positionAnimation.value > player.progress) {
              return;
            }

            // Если анимация уже идёт, то останавливаем её.
            if (positionAnimation.isAnimating) {
              positionAnimation.stop();
            }

            positionAnimation.value = player.progress;
          }),
        ];

        return () {
          for (StreamSubscription subscription in subscriptions) {
            subscription.cancel();
          }
        };
      },
      [],
    );
    final progress = useValueListenable(positionAnimation);

    final positionString = useMemoized(
      () {
        final safeDuration = duration ?? Duration.zero;
        final safePosition = seekPosition.value ?? positionAnimation.value;
        final positionSeconds = safeDuration * safePosition;

        // Если нам нужно показывать количество оставшегося времени, то показываем его.
        if (showRemainingTime) {
          final remainingSeconds = safeDuration - positionSeconds;

          return durationAsString(remainingSeconds);
        }

        return durationAsString(positionSeconds);
      },
      [
        position,
        seekPosition.value,
        positionAnimation.value,
        showRemainingTime,
      ],
    );

    void onPositionTextTap() => ref
        .read(preferencesProvider.notifier)
        .setShowRemainingTime(!showRemainingTime);

    final scheme = ColorScheme.of(context);

    return Row(
      spacing: 8,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTime)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPositionTextTap,
                borderRadius: BorderRadius.circular(
                  globalBorderRadius,
                ),
                child: Text(
                  positionString,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: SizedBox(
            height: 30,
            child: SliderTheme(
              data: SliderThemeData(
                trackShape: WavyTrackShape(
                  waveHeightPercent: sliderWaveAnimation.value,
                  waveOffsetPercent: sliderWaveOffsetAnimation.value,
                ),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: scheme.onPrimaryContainer,
                thumbShape: MaterialYouThumbShape(),
                thumbColor: scheme.onPrimaryContainer,
                inactiveTrackColor:
                    scheme.onPrimaryContainer.withValues(alpha: 0.5),
              ),
              child: ResponsiveSlider(
                value: progress,
                onChange: (double progress) => seekPosition.value = progress,
                onChangeEnd: (double progress) {
                  positionAnimation.value = progress;
                  seekPosition.value = null;

                  return player.seekNormalized(progress);
                },
              ),
            ),
          ),
        ),
        if (showTime)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              durationString,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}

/// Виджет, отображающий в себе [ListView], который автоматически скроллит до текущего момента в тексте песни.
class AudioLyricsListView extends HookConsumerWidget {
  /// Время, через которое после ручного скроллинга пользователем, автоскролл будет включен.
  static const Duration autoScrollDelay = Duration(seconds: 3);

  /// Расстояние между строчками.
  static const double lineSpacing = 12;

  /// Объект [Lyrics], содержащий в себе текст песни.
  final Lyrics lyrics;

  const AudioLyricsListView({
    super.key,
    required this.lyrics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);

    final controller = useMemoized(
      () => AutoScrollController(),
    );

    final autoScrollStopped = useState(false);
    final autoScrollStopTimer = useRef<Timer?>(null);

    final texts = lyrics.text;
    final timestamps = lyrics.timestamps;
    final isSynchronized = timestamps != null;
    final textOrTimestamps = useMemoized(
      () {
        if (timestamps != null) return timestamps;
        if (texts == null) return null;

        return texts
            .map(
              (line) => LyricTimestamp(
                line: line.isNotEmpty ? line : null,
              ),
            )
            .toList();
      },
      [texts, lyrics],
    );
    final lyricIndex = useState<int?>(null);

    int? getCurrentIndex() {
      final audio = player.audio;
      if (audio == null || audio.lyrics?.timestamps == null) return null;

      final position = player.position.inMilliseconds;
      final timestamps = audio.lyrics!.timestamps!;

      for (int i = timestamps.length - 1; i >= 0; i--) {
        final timestamp = timestamps[i];

        if (timestamp.begin! <= position) {
          return i;
        }
      }

      return null;
    }

    void scrollToCurrent() {
      controller.scrollToIndex(
        lyricIndex.value ?? 0,
        preferPosition: AutoScrollPosition.middle,
      );
    }

    void onPositionUpdate(_) {
      final index = getCurrentIndex();
      if (index == lyricIndex.value) return;

      lyricIndex.value = index;

      if (!isSynchronized || autoScrollStopped.value || !isLifecycleActive()) {
        return;
      }

      scrollToCurrent();
    }

    void onLyricTap(LyricTimestamp timestamp) {
      if (!isSynchronized) return;

      autoScrollStopped.value = false;
      autoScrollStopTimer.value?.cancel();

      player.seek(
        Duration(
          milliseconds: timestamp.begin!,
        ),
        play: true,
      );
    }

    useEffect(
      () {
        onPositionUpdate(null);

        final subscriptions = [
          player.positionStream.listen(onPositionUpdate),
          player.seekStream.listen(onPositionUpdate),
        ];

        return () {
          for (final subscription in subscriptions) {
            subscription.cancel();
          }
        };
      },
      [],
    );

    return NotificationListener(
      onNotification: (Notification notification) {
        if (controller.isAutoScrolling) return false;

        if (notification is ScrollStartNotification) {
          autoScrollStopTimer.value?.cancel();

          autoScrollStopped.value = true;
        } else if (notification is ScrollEndNotification) {
          autoScrollStopTimer.value = Timer(
            autoScrollDelay,
            () {
              if (!context.mounted) return;

              autoScrollStopped.value = false;
            },
          );
        }

        return false;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: ListView.separated(
          controller: controller,
          itemCount: textOrTimestamps!.length,
          separatorBuilder: (BuildContext context, int index) {
            return const Gap(lineSpacing);
          },
          itemBuilder: (BuildContext context, int index) {
            final timestamp = textOrTimestamps[index];

            return AutoScrollTag(
              key: ValueKey(
                index,
              ),
              controller: controller,
              index: index,
              child: LyricWidget(
                line: timestamp.line,
                isActive: isSynchronized && index == lyricIndex.value,
                distance: (!autoScrollStopped.value && lyricIndex.value != null)
                    ? index - lyricIndex.value!
                    : 0,
                onTap: isSynchronized ? () => onLyricTap(timestamp) : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Виджет, отображающий в себе [ListView], показывающий очередь из воспроизведения, который автоматически скроллит до текущего трека в очереди.
class PlayerQueueListView extends HookConsumerWidget {
  /// Длительность анимации скроллинга до текущего трека.
  static const Duration scrollDuration = Duration(seconds: 1);

  /// Curve для анимации скроллинга до текущего трека.
  static const Curve scrollCurve = Curves.ease;

  const PlayerQueueListView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerQueueProvider);
    ref.watch(playerAudioProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerIsBufferingProvider);

    final queue = player.queue;

    final controller = useScrollController();

    double currentTrackScrollPosition() {
      final int index = queue!.indexWhere(
        (audio) => audio.id == player.audio?.id,
      );
      if (index == -1) return 0;

      const itemHeight = AudioTrackTile.height + trackTileSpacing;

      return index * itemHeight -
          (controller.position.viewportDimension / 2) +
          (itemHeight / 2);
    }

    void scrollToCurrent(bool jump) {
      final offset = currentTrackScrollPosition();

      if (jump) {
        controller.jumpTo(offset);

        return;
      }

      controller.animateTo(
        duration: scrollDuration,
        curve: scrollCurve,
        offset,
      );
    }

    final lastAudioIndex = useRef<int?>(null);
    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!controller.hasClients) return;

          // Изменение трека.
          if (lastAudioIndex.value != player.index) {
            scrollToCurrent(lastAudioIndex.value == null);
            lastAudioIndex.value = player.index;

            return;
          }

          // Изменение размера экрана.
          scrollToCurrent(true);
        });

        return null;
      },
      [player.index, MediaQuery.sizeOf(context).height],
    );

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        overscroll: false,
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: ListView.builder(
        controller: controller,
        itemCount: queue!.length,
        itemExtent: AudioTrackTile.height + trackTileSpacing,
        itemBuilder: (BuildContext context, int index) {
          final audio = queue[index];
          final isPlaying = player.isPlaying;
          final isBuffering = player.isBuffering;
          final isSelected = audio.id == player.audio?.id;

          return Padding(
            padding: const EdgeInsets.only(
              bottom: trackTileSpacing,
            ),
            child: AudioTrackTile(
              audio: audio,
              isSelected: isSelected,
              isPlaying: isPlaying,
              isLoading: isSelected && isBuffering,
              glowIfSelected: true,
              showDuration: false,
              showStatusIcons: false,
              onPlayToggle: () {
                if (isSelected) {
                  player.togglePlay();

                  return;
                }

                player.jumpToAudio(audio);
              },
            ),
          );
        },
      ),
    );
  }
}
