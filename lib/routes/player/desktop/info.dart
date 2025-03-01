import "dart:async";
import "dart:math";
import "dart:ui";

import "package:animations/animations.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:media_kit/media_kit.dart" as mk;
import "package:media_kit_video/media_kit_video.dart";

import "../../../consts.dart";
import "../../../extensions.dart";
import "../../../provider/player.dart";
import "../../../provider/preferences.dart";
import "../../../services/cache_manager.dart";
import "../../../services/logger.dart";
import "../../../utils.dart";
import "../../../widgets/audio_player.dart";
import "../../../widgets/audio_track.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/fallback_audio_photo.dart";
import "../../../widgets/loading_button.dart";
import "../../../widgets/responsive_slider.dart";
import "../../../widgets/wavy_slider.dart";
import "../desktop.dart";

/// Отображает информацию по длительности трека.
class _ProgressSlider extends HookConsumerWidget {
  const _ProgressSlider();

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
        (player.duration != Duration.zero ? player.duration.inSeconds : null) ??
            player.audio?.duration;

    final durationString = useMemoized(
      () => secondsAsString(duration ?? 0),
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
            if (!context.mounted) return;

            // Эта задержка нужна, что бы событие изменения позиции обрабатывалось слегка позже,
            // чем обработчики события currentIndexStream или seekStateStream.
            await Future.delayed(
              const Duration(
                milliseconds: 1,
              ),
            );

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
        final safeDuration = duration ?? 0;
        final safePosition = seekPosition.value ?? positionAnimation.value;
        final positionSeconds = (safeDuration * safePosition).toInt();

        // Если нам нужно показывать количество оставшегося времени, то показываем его.
        if (showRemainingTime) {
          final remainingSeconds = safeDuration - positionSeconds;

          return secondsAsString(remainingSeconds);
        }

        return secondsAsString(positionSeconds);
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

    final scheme = Theme.of(context).colorScheme;

    return Row(
      spacing: 8,
      children: [
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

/// Отображает информацию по текущему треку, а так же кнопки "лайк" и "дизлайк".
class _Info extends ConsumerWidget {
  const _Info();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);

    final scheme =
        Theme.of(context).colorScheme; // TODO: Использовать тему трека.

    final audio = player.audio;
    final playlist = player.playlist;

    Future<void> onLikeTap() async {
      if (!networkRequiredDialog(ref, context)) return;

      final preferences = ref.read(preferencesProvider);

      if (!audio!.isLiked && preferences.checkBeforeFavorite) {
        if (!await audio.checkForDuplicates(ref, context)) return;
      }
      if (!context.mounted) return;

      await audio.likeDislikeRestoreSafe(
        context,
        player.ref,
        sourcePlaylist: playlist,
      );
    }

    Future<void> onDislikeTap() async {
      if (!networkRequiredDialog(ref, context)) return;

      await player.audio!.dislike(player.ref);

      await player.next();
    }

    return Row(
      children: [
        LoadingIconButton(
          icon: Icon(
            audio?.isLiked == true ? Icons.favorite : Icons.favorite_outline,
            color: scheme.onPrimaryContainer,
          ),
          color: scheme.onPrimaryContainer,
          onPressed: onLikeTap,
        ),
        Expanded(
          child: PageTransitionSwitcher(
            duration: DesktopPlayerWidget.transitionDuration,
            transitionBuilder: (
              Widget child,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal,
                fillColor: Colors.transparent,
                child: child,
              );
            },
            child: Column(
              key: ValueKey(
                audio?.id,
              ),
              children: [
                TrackTitleWithSubtitle(
                  title: audio?.title ?? "Unknown",
                  subtitle: audio?.subtitle,
                  textColor: scheme.onPrimaryContainer,
                  isExplicit: audio?.isExplicit ?? false,
                  explicitColor:
                      scheme.onPrimaryContainer.withValues(alpha: 0.75),
                ),
                Text(
                  audio?.artist ?? "Unknown",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
        LoadingIconButton(
          icon: Icon(
            Icons.thumb_down_outlined,
            color: scheme.onPrimaryContainer,
          ),
          color: scheme.onPrimaryContainer,
          onPressed: onDislikeTap,
        ),
      ],
    );
  }
}

/// Виджет, отображаемый изображение текущего трека.
class _Image extends HookConsumerWidget {
  static final AppLogger logger = getLogger("Player/_Image");

  /// Радиус скругления изображений.
  static const double borderRadius = 16;

  /// Длительность анимации перехода между изображениями.
  static const Duration animationDuration = Duration(seconds: 1);

  /// Сила размытия изображения для эффекта "свечения".
  static const double blur = 30;

  /// Размер изображения.
  final double size;

  const _Image({
    required this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);

    final audio = player.audio;

    final imageUrl = audio?.maxThumbnail;

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
        final thumbs = audio?.appleMusicThumbs;
        if (thumbs == null || thumbs.isEmpty) return null;

        thumbs.sort(
          (a, b) => a.resolution.compareTo(b.resolution),
        );

        final index = thumbs.indexWhere(
          (thumb) => thumb.resolution >= size,
        );
        return thumbs[min(index + 1, thumbs.length - 1)].url;
      },
      [audio?.appleMusicThumbs],
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

    return AnimatedSwitcher(
      duration: animationDuration,
      child: Stack(
        key: ValueKey(
          imageUrl,
        ),
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Фоновое изображение для тени.
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blur,
              sigmaY: blur,
              tileMode: TileMode.decal,
            ),
            child: CachedNetworkImage(
              imageUrl: audio!.smallestThumbnail!,
              cacheKey: "${audio.mediaKey}small",
              cacheManager: CachedAlbumImagesManager.instance,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholderFadeInDuration: Duration.zero,
              fit: BoxFit.fill,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Изображение трека.
          ClipRRect(
            borderRadius: BorderRadius.circular(
              borderRadius,
            ),
            child: CachedNetworkImage(
              imageUrl: audio.maxThumbnail!,
              cacheKey: "${audio.mediaKey}max",
              placeholder: (BuildContext context, String string) {
                return const FallbackAudioAvatar();
              },
              cacheManager: CachedAlbumImagesManager.instance,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholderFadeInDuration: Duration.zero,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Анимированное изображение трека.
          if (animatedThumbUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(
                borderRadius,
              ),
              child: Video(
                controller: controller,
                controls: NoVideoControls,
                wakelock: false,
                fill: Colors.transparent,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}

/// Отображает блок с информацией по тому треку, который воспроизводится.
class CurrentAudioBlock extends StatelessWidget {
  /// Размер этого блока.
  final Size size;

  const CurrentAudioBlock({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = clampDouble(
      min(
        size.width - 100,
        size.height - 200,
      ),
      100,
      800,
    );

    return SizedBox(
      width: size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 20,
        children: [
          SizedBox(
            width: imageSize,
            height: imageSize,
            child: _Image(
              size: imageSize,
            ),
          ),
          SizedBox(
            width: imageSize,
            child: const _Info(),
          ),
          SizedBox(
            width: imageSize,
            child: const _ProgressSlider(),
          ),
          SizedBox(
            width: imageSize,
            child: const PlayerControlsWidget(),
          ),
        ],
      ),
    );
  }
}
