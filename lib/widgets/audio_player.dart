import "dart:async";
import "dart:ui";

import "package:animations/animations.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../consts.dart";
import "../enums.dart";
import "../extensions.dart";
import "../provider/color.dart";
import "../provider/player.dart";
import "../provider/preferences.dart";
import "../provider/user.dart";
import "../services/cache_manager.dart";
import "../services/image_to_color_scheme.dart";
import "../services/logger.dart";
import "../utils.dart";
import "audio_track.dart";
import "dialogs.dart";
import "fallback_audio_photo.dart";
import "loading_button.dart";
import "play_pause_animated.dart";
import "responsive_slider.dart";
import "scrollable_slider.dart";
import "wavy_slider.dart";

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

  const TrackTitleAndArtist({
    super.key,
    required this.title,
    required this.artist,
    this.subtitle,
    this.explicit = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Информация по названию трека, subtitle, иконка Explicit.
        Flexible(
          child: TrackTitleWithSubtitle(
            title: title,
            subtitle: subtitle,
            textColor: scheme.onPrimaryContainer,
            isExplicit: explicit,
            explicitColor: scheme.onPrimaryContainer.withValues(alpha: 0.75),
            allowTextSelection: true,
          ),
        ),

        // Исполнитель.
        Text(
          artist,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

/// Виджет для [_MusicLeftSide], отображающий миниатюру текущего трека.
class _LeftSideThumbnail extends HookConsumerWidget {
  /// Трек, который играет в данный момент, и миниатюра которого будет показана.
  final ExtendedAudio? audio;

  const _LeftSideThumbnail({
    this.audio,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobileLayout = isMobileLayout(context);

    final player = ref.read(playerProvider);
    final schemeInfo = ref.watch(trackSchemeInfoProvider);

    final thumbnailUrl = audio?.smallestThumbnail;
    final cacheKey = "${audio?.mediaKey}small";
    final thumbnailSize = mobileLayout
        ? _MusicLeftSide.mobileThumbnailSize
        : _MusicLeftSide.desktopThumbnailSize;
    final memCacheSize =
        (thumbnailSize * MediaQuery.of(context).devicePixelRatio).toInt();

    final isPlaying = player.isPlaying;
    final isBuffering = player.isBuffering;
    final showLoading = useState(false);
    final bufferingTimer = useRef<Timer?>(null);

    useEffect(
      () {
        bufferingTimer.value?.cancel();

        if (isBuffering) {
          bufferingTimer.value = Timer(
            MusicPlayerWidget.bufferingIndicatorDuration,
            () {
              showLoading.value = true;
            },
          );
        } else {
          showLoading.value = false;
        }

        return bufferingTimer.value?.cancel;
      },
      [isBuffering, player.index],
    );
    final double loadingBlurSigma = showLoading.value ? 3 : 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: mobileLayout ? null : () => openPlayerRouteIfNotOpened(context),
        child: AnimatedContainer(
          duration: MusicPlayerWidget.switchAnimationDuration,
          curve: Curves.easeInOutCubicEmphasized,
          decoration: BoxDecoration(
            boxShadow: [
              if (isPlaying)
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Анимированное изображение.
                ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: loadingBlurSigma,
                    sigmaY: loadingBlurSigma,
                    tileMode: TileMode.decal,
                  ),
                  child: AnimatedSwitcher(
                    duration: MusicPlayerWidget.switchAnimationDuration,
                    child: thumbnailUrl != null
                        ? CachedNetworkImage(
                            key: ValueKey(
                              thumbnailUrl,
                            ),
                            cacheKey: cacheKey,
                            imageUrl: thumbnailUrl,
                            width: thumbnailSize,
                            height: thumbnailSize,
                            memCacheHeight: memCacheSize,
                            memCacheWidth: memCacheSize,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            placeholderFadeInDuration: Duration.zero,
                            cacheManager: CachedAlbumImagesManager.instance,
                            placeholder: (BuildContext context, String string) {
                              return FallbackAudioAvatar(
                                size: thumbnailSize,
                              );
                            },
                          )
                        : FallbackAudioAvatar(
                            key: const ValueKey(
                              null,
                            ),
                            size: thumbnailSize,
                          ),
                  ),
                ),

                // Анимация загрузки поверх.
                if (showLoading.value)
                  Container(
                    width: thumbnailSize,
                    height: thumbnailSize,
                    color: Colors.black54,
                    child: Center(
                      child: SizedBox(
                        height: thumbnailSize / 2,
                        width: thumbnailSize / 2,
                        child: CircularProgressIndicator(
                          strokeWidth: thumbnailSize / 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Виджет для [_MusicContents], отображающий содержимое левой части плеера.
///
/// В такой части отображается информация по текущему треку, и отображается она при Desktop и Mobile layout'ах.
///
/// При Mobile Layout занимает большую часть плеера, а при Desktop Layout занимает ровно такую же, какую и [_MusicRightSide]
class _MusicLeftSide extends HookConsumerWidget {
  /// Размер миниатюры трека при Mobile Layout.
  static const double mobileThumbnailSize = 50;

  /// Размер миниатюры трека при Desktop Layout.
  static const double desktopThumbnailSize = 60;

  /// Размер расстояния между миниатюрой и названием трека при Mobile Layout.
  static const double gapSizeMobile = 12;

  /// Размер расстояния между миниатюрой и названием трека при Desktop Layout.
  static const double gapSizeDesktop = 14;

  /// Callback-метод, вызываемый при нажатии на кнопку лайка.
  final AsyncCallback onLike;

  /// Callback-метод, вызываемый при нажатии на кнопку дизлайка.
  final AsyncCallback onDislike;

  const _MusicLeftSide({
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerPlaylistProvider);
    ref.watch(playerAudioProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerIsBufferingProvider);

    final mobileLayout = isMobileLayout(context);

    final lastAudio = useState<ExtendedAudio?>(player.audio);
    final fromTransition = useState<ExtendedAudio?>(null);
    final toTransition = useState<ExtendedAudio?>(null);
    final switchAnimation = useAnimationController(
      duration: MusicPlayerWidget.switchAnimationDuration,
      lowerBound: -1.0,
    );
    final switchingViaSwipe = useState(false);
    final didVibration = useState(false);
    final seekToPrevAudio = useState(false);
    useValueListenable(switchAnimation);

    Future<void> audioSwitchTransition(
      ExtendedAudio from,
      ExtendedAudio to, {
      double progress = 0.0,
      bool forceFullDuration = false,
    }) async {
      if (progress < -1.0 || progress > 1.0) {
        throw ArgumentError(
          "Progress must be between -1.0 and 1.0, but got $progress instead",
        );
      }
      if (forceFullDuration && (progress != 1.0 && progress != -1.0)) {
        throw ArgumentError(
          "Progress must be 1.0 or -1.0 if forceFullDuration is set, but got $progress instead",
        );
      }

      switchAnimation.stop();

      // Запускаем анимацию лишь в том случае, если приложение активно.
      if ([AppLifecycleState.resumed, AppLifecycleState.inactive]
          .contains(WidgetsBinding.instance.lifecycleState)) {
        fromTransition.value = to;
        toTransition.value = from;

        final maxDurationMs =
            MusicPlayerWidget.switchAnimationDuration.inMilliseconds;
        final left = forceFullDuration ? 1.0 : 1.0 - progress.abs();
        final leftReversed = -progress.sign * left;
        final durMs =
            (left * maxDurationMs).abs().clamp(0, maxDurationMs).toInt();

        switchAnimation.value = leftReversed;
        await switchAnimation.animateTo(
          0.0,
          duration: Duration(milliseconds: durMs),
        );
      }
      fromTransition.value = null;
      toTransition.value = null;
    }

    useEffect(
      () {
        final subscription = player.audioStream.listen((_) {
          // Запускаем анимацию перехода между треками, если предыдущий трек нам известны.
          if (player.audio != null && lastAudio.value?.id != player.audio?.id) {
            seekToPrevAudio.value = lastAudio.value == null ||
                lastAudio.value?.id == player.nextAudio?.id;
            final firedViaSwipe = switchingViaSwipe.value;
            final progress = firedViaSwipe
                ? switchAnimation.value
                : seekToPrevAudio.value
                    ? 1.0
                    : -1.0;

            final from = lastAudio.value ??
                (seekToPrevAudio.value
                    ? player.nextAudio
                    : player.previousAudio);
            final to = player.audio;

            if (from != null && to != null) {
              audioSwitchTransition(
                from,
                to,
                progress: progress,
                forceFullDuration: !firedViaSwipe,
              );
            }
          }

          if (player.audio != null) {
            lastAudio.value = player.audio;
          }
          switchingViaSwipe.value = false;
        });

        return subscription.cancel;
      },
      [],
    );

    final prevAudio = player.previousAudio;
    final audio = lastAudio.value;
    final nextAudio = player.nextAudio;

    final playlist = player.playlist;
    final isLiked = audio?.isLiked ?? false;
    final isRecommendation = playlist?.isRecommendationTypePlaylist ?? false;

    final scheme = Theme.of(context).colorScheme;

    void onTap() {
      openPlayerRouteIfNotOpened(context);
    }

    void onVolumeScroll(double diff) async {
      if (!mobileLayout || isMobile) return null;

      return player.setVolume(
        clampDouble(
          player.volume + diff / 10,
          0.0,
          1.0,
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints consts) {
        final gapSize = mobileLayout ? gapSizeMobile : gapSizeDesktop;
        final draggableSize = consts.maxWidth - mobileThumbnailSize - gapSize;

        void onHorizontalStart(DragStartDetails details) {
          switchAnimation.stop();
          didVibration.value = false;
          switchingViaSwipe.value = true;
        }

        void onHorizontalUpdate(DragUpdateDetails details) {
          switchAnimation.value = clampDouble(
            switchAnimation.value + details.primaryDelta! / draggableSize,
            -1.0,
            1.0,
          );

          if (!didVibration.value && switchAnimation.value.abs() >= 0.5) {
            didVibration.value = true;
            HapticFeedback.heavyImpact();
          } else if (didVibration.value && switchAnimation.value.abs() <= 0.5) {
            didVibration.value = false;
          }
        }

        void onHorizontalEnd(DragEndDetails details) async {
          final value = (switchAnimation.value +
                  details.primaryVelocity! / draggableSize / 10)
              .clamp(-1.0, 1.0);

          // Если пользователь проскроллил слишком мало, то не считаем это как переключение трека.
          if (value.abs() < 0.5) {
            switchAnimation.animateTo(0.0);

            return;
          }

          final isNext = value < 0.0;
          if (isNext) {
            player.next();
          } else {
            player.previous();
          }
        }

        return SizedBox(
          height: double.infinity,
          child: ScrollableWidget(
            onChanged: onVolumeScroll,
            child: MouseRegion(
              cursor: mobileLayout
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: mobileLayout ? onTap : null,
                onHorizontalDragStart: mobileLayout ? onHorizontalStart : null,
                onHorizontalDragUpdate:
                    mobileLayout ? onHorizontalUpdate : null,
                onHorizontalDragEnd: mobileLayout ? onHorizontalEnd : null,
                child: Row(
                  children: [
                    // Изображение трека.
                    _LeftSideThumbnail(
                      audio: audio,
                    ),
                    Gap(gapSize),

                    // Блок с названием и исполнителем трека, которое можно перетаскивать для Mobile Layout.
                    if (mobileLayout)
                      ClipRRect(
                        child: SizedBox(
                          width: draggableSize,
                          child: Stack(
                            children: [
                              // Текущий трек.
                              Transform.translate(
                                offset: Offset(
                                  switchAnimation.value * draggableSize,
                                  0.0,
                                ),
                                child: Opacity(
                                  opacity: 1.0 - switchAnimation.value.abs(),
                                  child: () {
                                    final ExtendedAudio? displayAudio =
                                        fromTransition.value ?? audio;

                                    return TrackTitleAndArtist(
                                      title: displayAudio?.title ?? "Unknown",
                                      artist: displayAudio?.artist ?? "Unknown",
                                      subtitle: displayAudio?.subtitle,
                                      explicit:
                                          displayAudio?.isExplicit ?? false,
                                    );
                                  }(),
                                ),
                              ),

                              // Следующий либо предыдущий трек.
                              if (switchAnimation.value != 0.0)
                                Transform.translate(
                                  offset: Offset(
                                    (switchAnimation.value >= 0.0
                                            ? -draggableSize
                                            : draggableSize) +
                                        switchAnimation.value * draggableSize,
                                    0.0,
                                  ),
                                  child: Opacity(
                                    opacity: switchAnimation.value.abs(),
                                    child: () {
                                      ExtendedAudio? audio =
                                          toTransition.value ??
                                              (switchAnimation.value < 0.0
                                                  ? nextAudio
                                                  : prevAudio);

                                      return TrackTitleAndArtist(
                                        title: audio?.title ?? "Unknown",
                                        artist: audio?.artist ?? "Unknown",
                                        subtitle: audio?.subtitle,
                                        explicit: audio?.isExplicit ?? false,
                                      );
                                    }(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    // Блок с названием и исполнителем трека для Desktop Layout.
                    if (!mobileLayout)
                      PageTransitionSwitcher(
                        duration: MusicPlayerWidget.switchAnimationDuration,
                        reverse: seekToPrevAudio.value,
                        layoutBuilder: (List<Widget> widgets) {
                          // Здесь мы удаляем дубликаты виджетов.
                          final Set<Key> keys = {};
                          List<Widget> newWidgets = widgets
                              .where((item) => item.key != null)
                              .toList();
                          newWidgets.retainWhere(
                            (item) => keys.add(item.key!),
                          );

                          return Expanded(
                            child: Stack(
                              children: newWidgets,
                            ),
                          );
                        },
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
                        child: Row(
                          key: ValueKey(
                            audio?.id,
                          ),
                          children: [
                            Flexible(
                              child: SelectionArea(
                                child: TrackTitleAndArtist(
                                  title: audio?.title ?? "Unknown",
                                  artist: audio?.artist ?? "Unknown",
                                  subtitle: audio?.subtitle,
                                  explicit: audio?.isExplicit ?? false,
                                ),
                              ),
                            ),
                            Gap(gapSize),

                            // Кнопка лайка.
                            LoadingIconButton(
                              onPressed: onLike,
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_outline,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),

                            // Кнопка дизлайка, если это рекомендованный плейлист.
                            if (isRecommendation) ...[
                              const Gap(4),
                              LoadingIconButton(
                                onPressed: onDislike,
                                icon: Icon(
                                  Icons.thumb_down_outlined,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Виджет для [_MusicMiddleSide], отображающий ряд из кнопок для управления воспроизведением.
class PlayerControlsWidget extends ConsumerWidget {
  /// Указывает, что будет использоваться увеличенный размер кнопок.
  final bool large;

  /// Указывает, что будет использоваться уменьшенное расстояние между кнопками.
  final bool dense;

  /// Указывает, будет ли показана кнопка для переключения случайной перемешки.
  final bool showShuffle;

  /// Указывает, будет ли показана кнопка для включения предыдущего трека.
  final bool showPrevious;

  /// Указывает, будет ли показана кнопка для включения следующего трека.
  final bool showNext;

  /// Указывает, будет ли показана кнопка для переключения повтора трека.
  final bool showRepeat;

  const PlayerControlsWidget({
    super.key,
    this.large = false,
    this.dense = false,
    this.showShuffle = true,
    this.showPrevious = true,
    this.showNext = true,
    this.showRepeat = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerIsShufflingProvider);
    ref.watch(playerIsRepeatingProvider);

    final scheme = Theme.of(context).colorScheme;

    final isShuffling = player.isShuffling;
    final isLooping = player.isRepeating;
    final playlist = player.playlist;
    final isAudioMix = playlist?.type == PlaylistType.audioMix;

    final size = large ? 30.0 : null;
    final alignment =
        large ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center;
    final spacing = (dense || large) ? 0.0 : 8.0;

    void onShuffleToggle() {
      HapticFeedback.lightImpact();
      if (isAudioMix) {
        throw Exception("Attempted to enable shuffle for audio mix");
      }

      player.toggleShuffle();
    }

    void onPrevious() {
      HapticFeedback.lightImpact();
      player.smartPrevious();
    }

    void onPlayPause() {
      HapticFeedback.lightImpact();
      player.togglePlay();
    }

    void onStop() {
      HapticFeedback.mediumImpact();
      player.stop();
    }

    void onNext() {
      HapticFeedback.lightImpact();
      player.next();
    }

    void onRepeatToggle() {
      HapticFeedback.lightImpact();
      player.toggleRepeat();
    }

    return Row(
      mainAxisAlignment: alignment,
      spacing: spacing,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showShuffle)
          IconButton(
            onPressed: isAudioMix ? null : onShuffleToggle,
            iconSize: size,
            icon: Icon(
              isAudioMix
                  ? Icons.close
                  : isShuffling
                      ? Icons.shuffle_on_outlined
                      : Icons.shuffle,
              color: isAudioMix ? null : scheme.onPrimaryContainer,
            ),
          ),
        if (showPrevious)
          IconButton(
            onPressed: onPrevious,
            iconSize: size,
            icon: Icon(
              Icons.skip_previous,
              color: scheme.onPrimaryContainer,
            ),
          ),
        PlayPauseAnimatedButton(
          onPressed: onPlayPause,
          onLongPress: onStop,
          backgroundColor: scheme.primary,
          color: scheme.onPrimary,
          iconSize: size,
        ),
        if (showNext)
          IconButton(
            onPressed: onNext,
            iconSize: size,
            icon: Icon(
              Icons.skip_next,
              color: scheme.onPrimaryContainer,
            ),
          ),
        if (showRepeat)
          IconButton(
            onPressed: onRepeatToggle,
            iconSize: size,
            icon: Icon(
              isLooping ? Icons.repeat_on_outlined : Icons.repeat,
              color: scheme.onPrimaryContainer,
            ),
          ),
      ],
    );
  }
}

/// Виджет для [_MusicMiddleSide], отображающий информацию по следующему треку перед окончанеим воспроизведения текущего.
class NextTrackSpoilerWidget extends HookConsumerWidget {
  const NextTrackSpoilerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMobileLayout(context)) {
      throw Exception("This widget is only for Desktop Layout");
    }

    final player = ref.read(playerProvider);
    ref.watch(playerIsShufflingProvider);
    ref.watch(playerAudioProvider);
    ref.watch(playerIsRepeatingProvider);
    ref.watch(playerPositionProvider);

    final animation = useAnimationController(
      duration: MusicPlayerWidget.switchAnimationDuration,
    );
    useValueListenable(animation);

    final show = player.progress >= nextPlayingTextProgress;
    useEffect(
      () {
        animation.animateTo(
          show ? 1.0 : 0.0,
          curve: Curves.easeInOutCubicEmphasized,
        );

        return null;
      },
      [show],
    );

    if (animation.value == 0.0) return const SizedBox();

    final audio = useState(player.nextAudio);
    final artist = audio.value?.artist;
    final title = audio.value?.title;
    final subtitle = audio.value?.subtitle;
    useEffect(
      () {
        if (player.nextAudio != null && animation.value == 0.0) {
          audio.value = player.nextAudio;
        }

        return null;
      },
      [animation.value, player.nextAudio],
    );

    final position =
        MusicPlayerWidget.desktopMiniPlayerHeightWithSafeArea(context) -
            5.0 +
            animation.value * 15;
    final opacity = animation.value;

    final scheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: position,
      child: Opacity(
        opacity: opacity,
        child: AnimatedSwitcher(
          duration: MusicPlayerWidget.switchAnimationDuration,
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: scheme.primary,
              ),
              children: [
                // Иконка.
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Icons.music_note,
                    color: scheme.primary,
                  ),
                ),

                // Исполнитель.
                TextSpan(
                  text: " ${artist ?? "Unknown"}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: " • ",
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),

                // Название трека.
                TextSpan(
                  text: title ?? "Unknown",
                ),

                // Подпись, если таковая имеется.
                if (subtitle != null)
                  TextSpan(
                    text: " ($subtitle)",
                    style: TextStyle(
                      color: scheme.primary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Виджет для [_MusicContents], отображающий содержимое части плеера по середине. Отображается только при Desktop Layout'е.
///
/// В такой части отображаются кнопки для управления воспроизведением, а так же прогресс-бар для текущего трека.
class _MusicMiddleSide extends HookConsumerWidget {
  const _MusicMiddleSide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMobileLayout(context)) {
      throw Exception("This widget is only for Desktop Layout");
    }

    final player = ref.read(playerProvider);
    final preferences = ref.watch(preferencesProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerPositionProvider);

    final alternateSlider = preferences.alternateDesktopMiniplayerSlider;
    final showRemainingTime = preferences.showRemainingTime;

    final scheme = Theme.of(context).colorScheme;

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
          // Переключение трека.
          player.audioStream.listen((_) {
            runSeekAnimation(progress: 0.0);
          }),

          // Перемотка.
          player.seekStream.listen((_) {
            runSeekAnimation();
          }),

          // Позиция трека.
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

    return SizedBox(
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Slider для отображения прогресса воспроизведения трека.
          if (!alternateSlider)
            RepaintBoundary(
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
          const Gap(4),

          // Ряд из прогресса воспроизведения, кнопками управления, длительности трека.
          Row(
            mainAxisAlignment: alternateSlider
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              // Прогресс воспроизведения.
              Flexible(
                child: FittedBox(
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
                          color: scheme.onPrimaryContainer
                              .withValues(alpha: isPlaying ? 1.0 : 0.75),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (alternateSlider) const Gap(16),

              // Кнопки управления воспроизведением.
              const PlayerControlsWidget(),
              if (alternateSlider) const Gap(16),

              // Полная длительность трека.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    durationString,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer
                          .withValues(alpha: isPlaying ? 1.0 : 0.75),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Виджет для [_MusicContents], отображающий содержимое правой части плеера.
///
/// В такой части отображаются дополнительные кнопки для управления воспроизведением в Desktop Layout, либо ряд из некоторых простых кнопок (лайк, пауза) для Mobile Layout.
class _MusicRightSide extends HookConsumerWidget {
  static const BoxConstraints buttonConstraints = BoxConstraints(
    minWidth: kMinInteractiveDimension,
    minHeight: kMinInteractiveDimension,
  );

  /// Callback-метод, вызываемый при нажатии на кнопку лайка.
  final AsyncCallback onLike;

  /// Callback-метод, вызываемый при нажатии на кнопку дизлайка.
  final AsyncCallback onDislike;

  const _MusicRightSide({
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final mobileLayout = isMobileLayout(context);

    final player = ref.read(playerProvider);
    ref.watch(playerPlaylistProvider);
    ref.watch(playerAudioProvider);
    ref.watch(playerIsPlayingProvider);
    if (!mobileLayout) {
      ref.watch(playerVolumeProvider);
    }

    final playlist = player.playlist;
    final audio = useState<ExtendedAudio?>(player.audio);
    useEffect(
      () {
        if (player.audio == null) return;
        audio.value = player.audio;

        return null;
      },
      [player.audio],
    );

    final volume = player.volume;

    final isLiked = audio.value?.isLiked ?? false;
    final isRecommendation = playlist?.isRecommendationTypePlaylist ?? false;

    void onPlayPause() {
      HapticFeedback.lightImpact();
      player.togglePlay();
    }

    void onStop() {
      HapticFeedback.mediumImpact();
      player.stop();
    }

    // Кнопки дизлайка, лайка и паузы/воспроизведения для Mobile Layout.
    if (mobileLayout) {
      return SizedBox(
        height: double.infinity,
        child: Row(
          children: [
            // Лайк.
            LoadingIconButton(
              onPressed: onLike,
              constraints: buttonConstraints,
              iconSize: 24,
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_outline,
                color: scheme.onPrimaryContainer,
              ),
            ),

            // Дизлайк.
            if (isRecommendation)
              LoadingIconButton(
                onPressed: onDislike,
                constraints: buttonConstraints,
                icon: Icon(
                  Icons.thumb_down_outlined,
                  color: scheme.onPrimaryContainer,
                ),
              ),

            // Пауза/воспроизведение.
            GestureDetector(
              onLongPress: onStop,
              child: IconButton(
                onPressed: onPlayPause,
                constraints: buttonConstraints,
                icon: PlayPauseAnimatedIcon(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Кнопки управления воспроизведением для Desktop Layout.
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Slider для управления громкостью.
          if (isWeb || isDesktop) ...[
            Flexible(
              child: SizedBox(
                width: 150,
                child: SliderTheme(
                  data: SliderThemeData(
                    thumbShape: MaterialYouThumbShape(),
                  ),
                  child: ScrollableSlider(
                    value: volume,
                    activeColor: scheme.onPrimaryContainer,
                    inactiveColor:
                        scheme.onPrimaryContainer.withValues(alpha: 0.5),
                    onChanged: (double newVolume) {
                      if (isMobile) return;

                      player.setVolume(newVolume);
                    },
                  ),
                ),
              ),
            ),
            const Gap(10),
          ],

          // TODO: Кнопка для перехода в мини-плеер.
          if (isDesktop && kDebugMode) ...[
            IconButton(
              icon: Icon(
                Icons.picture_in_picture_alt,
                color: scheme.onPrimaryContainer,
              ),
              onPressed: () {
                // TODO: Open mini player
              },
            ),
            const Gap(2),
          ],

          // Кнопка для перехода в полноэкранный режим.
          if (isWeb || isDesktop)
            IconButton(
              icon: Icon(
                Icons.fullscreen,
                color: scheme.onPrimaryContainer,
              ),
              onPressed: () => openPlayerRouteIfNotOpened(context),
            ),
        ],
      ),
    );
  }
}

/// Виджет для [_MusicContents], отображающий анимированный фон плеера, цвет которого зависит от текущего трека.
class MusicPlayerBackgroundWidget extends HookConsumerWidget {
  const MusicPlayerBackgroundWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    final preferences = ref.watch(preferencesProvider);
    ref.watch(playerAudioProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerPositionProvider);

    final isPlaying = player.isPlaying;

    final scheme = Theme.of(context).colorScheme;
    final mobileLayout = isMobileLayout(context);

    final audio = player.nextAudio;
    final progress = player.progress;
    final clampedProgress = preferences.crossfadeColors
        ? ((progress - nextPlayingTextProgress) /
                (1.0 - nextPlayingTextProgress))
            .clamp(0.0, 1.0)
        : 0.0;

    final brightness = Theme.of(context).brightness;
    final ColorScheme? nextScheme = useMemoized(
      () {
        if (audio?.colorInts == null) return null;

        final trackSchemeInfo = ImageSchemeExtractor(
          colorInts: audio!.colorInts!,
          scoredColorInts: audio.scoredColorInts!,
          frequentColorInt: audio.frequentColorInt!,
          colorCount: audio.colorCount!,
        );

        return trackSchemeInfo.createScheme(
          brightness,
          schemeVariant: preferences.dynamicSchemeType,
        );
      },
      [brightness, audio?.colorInts, preferences.dynamicSchemeType],
    );

    final baseBackgroundColor = useMemoized(
      () {
        Color baseColor = scheme.primaryContainer;

        // Затемняем, если трек не воспроизводится.
        if (!isPlaying) {
          baseColor = baseColor.darken(0.15);
        }

        // Если вот-вот начнётся воспроизведение следующего трека, то плавно переходим к его цвету.
        if (nextScheme != null && clampedProgress > 0.0) {
          baseColor = Color.lerp(
            baseColor,
            nextScheme.primaryContainer,
            clampedProgress,
          )!;
        }

        return baseColor;
      },
      [isPlaying, clampedProgress, scheme, nextScheme],
    );
    final backgroundColor = baseBackgroundColor;

    if (mobileLayout) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: Stack(
          children: [
            // Фон оригинального цвета.
            AnimatedContainer(
              duration: MusicPlayerWidget.switchAnimationDuration,
              curve: Curves.easeInOutCubicEmphasized,
              color: backgroundColor,
            ),

            // Затемнение фона, начинающееся с конца трека.
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 1.0 - progress,
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedContainer(
      duration: MusicPlayerWidget.switchAnimationDuration,
      curve: Curves.easeInOutCubicEmphasized,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: mobileLayout
            ? BorderRadius.circular(
                globalBorderRadius,
              )
            : null,
      ),
    );
  }
}

/// Виджет для [_MusicContents], отображающий прогресс-бар внизу плеера.
class BottomMusicProgressBar extends HookConsumerWidget {
  /// Длительность анимации для [Slider] во время переключения треков или перемотки.
  static const Duration sliderAnimationDuration = Durations.long2;

  const BottomMusicProgressBar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerIsPlayingProvider).value;
    ref.watch(playerPositionProvider);

    final isPlaying = player.isPlaying;
    final playerProgress = player.progress;

    final progressAnimation = useAnimationController(
      duration: sliderAnimationDuration,
      initialValue: playerProgress,
    );
    useEffect(
      () {
        progressAnimation.animateTo(
          playerProgress,
          curve: Curves.easeInOutCubicEmphasized,
        );

        return null;
      },
      [player.index],
    );
    useEffect(
      () {
        if (progressAnimation.isAnimating) return;
        progressAnimation.value = playerProgress;

        return null;
      },
      [playerProgress],
    );
    final animatedProgress = useValueListenable(progressAnimation);

    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onPrimaryContainer.withValues(
      alpha: isPlaying ? 1 : 0.5,
    );

    final mobileLayout = isMobileLayout(context);

    return Transform.translate(
      offset: Offset(
        0,
        mobileLayout ? 1 : 0,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mobileLayout ? 6 : 0,
        ),
        child: LinearProgressIndicator(
          value: animatedProgress,
          color: color,
          backgroundColor: Colors.transparent,
          minHeight: 2,
        ),
      ),
    );
  }
}

/// Виджет для [MusicPlayerWidget], отображающий содержимое плеера.
class _MusicContents extends ConsumerWidget {
  /// Минимальный размер центрального блока ([PlayerControlsWidget]) при Desktop Layout.
  static const double minMiddleBlockSize = 100;

  /// Максимальный размер центрального блока ([PlayerControlsWidget]) при Desktop Layout.
  static const double maxMiddleBlockSize = 650;

  /// Внутренний padding для содержимого плеера при Mobile Layout.
  static const double mobilePadding = 8;

  /// Внутренний padding для содержимого плеера при Desktop Layout.
  static const double desktopPadding = 14;

  /// Padding для [PlayerControlsWidget] (центральный блок), что бы он не прижимался к левой и правой части плеера, отображаемый в Desktop Layout.
  static const double gapSizeDesktop = 8;

  /// Debug-опция, чтобы отобразить различные разделы плеера в разных цветах для отладки.
  static bool debugSections = kDebugMode && false;

  const _MusicContents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    final preferences = ref.watch(preferencesProvider);
    ref.watch(playerPlaylistProvider);

    final mobileLayout = isMobileLayout(context);

    final playlist = player.playlist;
    final isRecommendation = playlist?.isRecommendationTypePlaylist ?? false;

    final height = mobileLayout
        ? MusicPlayerWidget.mobileHeight
        : MusicPlayerWidget.desktopMiniPlayerHeight;
    final padding = (mobileLayout) ? mobilePadding : desktopPadding;
    final freeSpace = MediaQuery.of(context).size.width -
        (mobileLayout ? MusicPlayerWidget.mobilePadding * 2 : 0) -
        padding * 2;
    // TODO: Реализовать "сжатую" версию плеера при Desktop Layout.

    double leftBlockSize = 0;
    double? middleBlockSize;
    double? middleBlockPadding;
    double rightBlockSize = 0;

    if (mobileLayout) {
      int buttonsCount = isRecommendation ? 3 : 2;

      rightBlockSize = buttonsCount * 48;
      leftBlockSize = freeSpace - rightBlockSize;
    } else {
      middleBlockPadding = gapSizeDesktop * 2;
      middleBlockSize = clampDouble(
        freeSpace / 2 + middleBlockPadding,
        minMiddleBlockSize,
        maxMiddleBlockSize,
      );
      leftBlockSize = rightBlockSize = (freeSpace - middleBlockSize) / 2;
    }

    Future<void> onLikeTap() async {
      HapticFeedback.lightImpact();
      if (!networkRequiredDialog(ref, context)) return;

      final preferences = ref.read(preferencesProvider);

      if (!player.audio!.isLiked && preferences.checkBeforeFavorite) {
        if (!await player.audio!.checkForDuplicates(ref, context)) return;
      }
      if (!context.mounted) return;

      await player.audio!.likeDislikeRestoreSafe(
        context,
        player.ref,
        sourcePlaylist: player.playlist,
      );
    }

    Future<void> onDislikeTap() async {
      HapticFeedback.lightImpact();
      if (!networkRequiredDialog(ref, context)) return;

      await player.audio!.dislike(player.ref);

      await player.next();
    }

    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Спойлер следующего трека.
        if (preferences.spoilerNextTrack && !mobileLayout)
          const NextTrackSpoilerWidget(),

        // Фон плеера, который может плавно менять цвет в зависимости от текущего трека.
        const MusicPlayerBackgroundWidget(),

        // Содержимое плеера.
        SizedBox(
          height: height,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: padding,
            ),
            child: Row(
              children: [
                // Левая часть.
                RepaintBoundary(
                  child: Container(
                    width: leftBlockSize,
                    color: debugSections ? Colors.red : null,
                    child: _MusicLeftSide(
                      onLike: onLikeTap,
                      onDislike: onDislikeTap,
                    ),
                  ),
                ),

                // Центральная (при Desktop Layout).
                if (!mobileLayout)
                  Container(
                    width: middleBlockSize!,
                    padding: EdgeInsets.symmetric(
                      horizontal: middleBlockPadding!,
                    ),
                    color: debugSections ? Colors.green : null,
                    child: const RepaintBoundary(
                      child: _MusicMiddleSide(),
                    ),
                  ),

                // Правая часть.
                Container(
                  width: rightBlockSize,
                  color: debugSections ? Colors.blue : null,
                  child: RepaintBoundary(
                    child: _MusicRightSide(
                      onLike: onLikeTap,
                      onDislike: onDislikeTap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Прогресс-бар.
        if (!mobileLayout && preferences.alternateDesktopMiniplayerSlider)
          Align(
            alignment:
                mobileLayout ? Alignment.bottomCenter : Alignment.topCenter,
            child: const BottomMusicProgressBar(),
          ),
      ],
    );
  }
}

/// Виджет мини-плеера, который отображается внизу экрана, показывая информацию по треку, который играет в данный момент, а так же даёт возможность по управлению воспроизведения. Данный виджет, обычно, отображается внизу экрана, поверх всех остальных элементов при помощи [Stack] или ему подобным.
///
/// При Mobile Layout'е, данный виджет должен "парить" над другими элементами (высота: [mobileHeight] либо [mobileHeightWithPadding] если учитывать padding [mobilePadding]), а при Desktop Layout'е, он должен быть прижат к нижней части экрана (высота: [desktopMiniPlayerHeight]).
///
/// Виджет разбит на множество частей:
/// [MusicPlayerWidget]
/// - [_MusicContents]
///   - [MusicPlayerBackgroundWidget] (фон)
///   - [_MusicLeftSide]
///     - [_LeftSideThumbnail]
///   - [_MusicMiddleSide]
///     - [PlayerControlsWidget]
///   - [_MusicRightSide]
class MusicPlayerWidget extends HookConsumerWidget {
  static final AppLogger logger = getLogger("MusicPlayer");

  /// Padding для этого виджета при Mobile Layout.
  static const double mobilePadding = 8;

  /// Высота мини-плеера для Mobile Layout без учёта padding'а.
  static const double mobileHeight = 66;

  /// Высота мини-плеера для Mobile Layout'а с учётом padding'ов.
  static const double mobileHeightWithPadding =
      mobileHeight + mobilePadding * 2;

  /// Высота мини-плеера для Desktop Layout.
  ///
  /// Учтите, что Padding ([MediaQuery.paddingOf]) не учитывается в данном размере. Если вам нужно учесть padding, то используйте метод [desktopMiniPlayerHeightWithSafeArea].
  static const double desktopMiniPlayerHeight = 88;

  /// Длительность анимации переключения треков, а так же кнопки паузы/воспроизведения.
  static const Duration switchAnimationDuration = Duration(milliseconds: 400);

  /// Длительность анимации для перехода из линии в волну для [Slider], который отображает прогресс воспроизведения.
  static const Duration sliderWaveAnimationDuration =
      Duration(milliseconds: 1000);

  /// Длительность анимации "движения" волны для [Slider], который отображает прогресс воспроизведения.
  static const Duration sliderWaveOffsetAnimationDuration =
      Duration(milliseconds: 3500);

  /// Длительность анимации для [Slider] во время переключения треков или перемотки.
  static const Duration sliderAnimationDuration = Durations.long2;

  /// Возвращает высоту мини-плеера для Desktop Layout с учётом [MediaQuery.paddingOf].
  static double desktopMiniPlayerHeightWithSafeArea(BuildContext context) {
    return MusicPlayerWidget.desktopMiniPlayerHeight +
        MediaQuery.paddingOf(context).bottom;
  }

  /// Длительность того, сколько [Player.isBuffering] должен быть `true`, что бы показать индикатор загрузки.
  static const Duration bufferingIndicatorDuration =
      Duration(milliseconds: 100);

  /// Длительность открытия полноэкранного плеера.
  static const Duration fullscreenOpenDuration = Duration(milliseconds: 500);

  const MusicPlayerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobileLayout = isMobileLayout(context);

    final trackSchemeInfo = ref.watch(trackSchemeInfoProvider);
    final preferences = ref.watch(preferencesProvider);
    final bool isPlaying = ref.watch(playerIsPlayingProvider).value ?? false;

    final brightness = Theme.of(context).brightness;
    final ColorScheme? trackScheme = useMemoized(
      () => trackSchemeInfo?.createScheme(
        brightness,
        schemeVariant: preferences.dynamicSchemeType,
      ),
      [brightness, trackSchemeInfo, preferences.dynamicSchemeType],
    );

    final scheme = trackScheme ?? Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(
        mobileLayout ? mobilePadding : 0,
      ),
      child: SizedBox(
        height: mobileLayout
            ? mobileHeight
            : desktopMiniPlayerHeightWithSafeArea(context),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 500,
          ),
          decoration: BoxDecoration(
            borderRadius: mobileLayout
                ? BorderRadius.circular(
                    globalBorderRadius,
                  )
                : null,
            boxShadow: [
              if (isPlaying)
                BoxShadow(
                  color: scheme.secondaryContainer,
                  blurRadius: isPlaying ? 50 : 0,
                  blurStyle: BlurStyle.outer,
                ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: scheme,
            ),
            child: const _MusicContents(),
          ),
        ),
      ),
    );
  }
}
