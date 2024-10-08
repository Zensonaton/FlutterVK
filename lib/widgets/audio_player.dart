import "dart:ui";

import "package:animations/animations.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:just_audio/just_audio.dart";

import "../api/vk/shared.dart";
import "../consts.dart";
import "../enums.dart";
import "../extensions.dart";
import "../main.dart";
import "../provider/color.dart";
import "../provider/l18n.dart";
import "../provider/player_events.dart";
import "../provider/preferences.dart";
import "../provider/user.dart";
import "../routes/fullscreen_player.dart";
import "../routes/home/music.dart";
import "../services/image_to_color_scheme.dart";
import "../services/logger.dart";
import "../utils.dart";
import "audio_track.dart";
import "dialogs.dart";
import "fallback_audio_photo.dart";
import "isolated_cached_network_image.dart";
import "loading_button.dart";
import "responsive_slider.dart";
import "scrollable_slider.dart";
import "wavy_slider.dart";

/// Виджет, являющийся частью [MusicPlayerWidget] и [AudioTrackTile], который либо использует [Text], либо [RichText] в зависимости от того, указан [subtitle] или нет.
class TrackTitleWithSubtitle extends StatelessWidget {
  /// Название трека.
  final String title;

  /// Подпись трека. Может отсутствовать.
  final String? subtitle;

  /// Цвет текста.
  final Color color;

  const TrackTitleWithSubtitle({
    super.key,
    required this.title,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = TextStyle(
      fontWeight: FontWeight.w500,
      color: color,
    );

    // Если есть subtitle, то делаем RichText.
    if (subtitle != null) {
      return RichText(
        text: TextSpan(
          text: title,
          style: titleStyle,
          children: [
            TextSpan(
              text: " ($subtitle)",
              style: TextStyle(
                fontWeight: FontWeight.w300,
                color: color.withOpacity(0.75),
              ),
            ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      title,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
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
        // Информация по названию трека и прочей информацией.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Название трека, а так же subtitle, при наличии.
            Flexible(
              child: TrackTitleWithSubtitle(
                title: title,
                subtitle: subtitle,
                color: scheme.onPrimaryContainer,
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

/// Виджет для [_MusicLeftSide], отображающий миниатюру текущего трека.
class _LeftSideThumbnail extends ConsumerWidget {
  /// Трек, который играет в данный момент, и миниатюра которого будет показана.
  final ExtendedAudio? audio;

  const _LeftSideThumbnail({
    this.audio,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobileLayout = isMobileLayout(context);

    final schemeInfo = ref.watch(trackSchemeInfoProvider);

    final thumbnailUrl = audio?.smallestThumbnail;
    final cacheKey = "${audio?.mediaKey}small";
    final thumbnailSize = mobileLayout
        ? _MusicLeftSide.mobileThumbnailSize
        : _MusicLeftSide.desktopThumbnailSize;
    final memCacheSize =
        (thumbnailSize * MediaQuery.of(context).devicePixelRatio).toInt();

    final isPlaying = player.playing;
    final isBuffering = player.buffering;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: mobileLayout ? null : () => openFullscreenPlayer(context),
        child: AnimatedContainer(
          duration: MusicPlayerWidget.switchAnimationDuration,
          curve: Curves.ease,
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
                    sigmaX: isBuffering ? 3 : 0,
                    sigmaY: isBuffering ? 3 : 0,
                    tileMode: TileMode.decal,
                  ),
                  child: AnimatedSwitcher(
                    duration: MusicPlayerWidget.switchAnimationDuration,
                    child: thumbnailUrl != null
                        ? IsolatedCachedImage(
                            key: ValueKey(thumbnailUrl),
                            cacheKey: cacheKey,
                            imageUrl: thumbnailUrl,
                            width: thumbnailSize,
                            height: thumbnailSize,
                            memCacheHeight: memCacheSize,
                            memCacheWidth: memCacheSize,
                            fit: BoxFit.cover,
                            placeholder: FallbackAudioAvatar(
                              width: thumbnailSize,
                              height: thumbnailSize,
                            ),
                          )
                        : FallbackAudioAvatar(
                            key: const ValueKey(null),
                            width: thumbnailSize,
                            height: thumbnailSize,
                          ),
                  ),
                ),

                // Анимация загрузки поверх.
                if (isBuffering)
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
    ref.watch(playerPlaylistModificationsProvider);
    ref.watch(playerCurrentIndexProvider);
    ref.watch(playerPlayingStateProvider);
    ref.watch(playerStateProvider);

    final mobileLayout = isMobileLayout(context);

    final lastAudio = useState<ExtendedAudio?>(player.smartCurrentAudio);
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
      assert(
        progress >= -1.0 && progress <= 1.0,
        "Progress must be between -1.0 and 1.0, but got $progress instead",
      );
      if (forceFullDuration) {
        assert(
          progress == 1.0 || progress == -1.0,
          "Progress must be 1.0 or -1.0 if forceFullDuration is set, but got $progress instead",
        );
      }

      switchAnimation.stop();
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
      fromTransition.value = null;
      toTransition.value = null;
    }

    useEffect(
      () {
        // Запускаем анимацию перехода между треками, если предыдущий трек нам известны.
        if (player.smartCurrentAudio != null &&
            lastAudio.value?.id != player.smartCurrentAudio?.id) {
          seekToPrevAudio.value = lastAudio.value == null ||
              lastAudio.value?.id == player.smartNextAudio?.id;
          final firedViaSwipe = switchingViaSwipe.value;
          final progress = firedViaSwipe
              ? switchAnimation.value
              : seekToPrevAudio.value
                  ? 1.0
                  : -1.0;

          final from = lastAudio.value ??
              (seekToPrevAudio.value
                  ? player.smartNextAudio
                  : player.smartPreviousAudio);
          final to = player.smartCurrentAudio;

          if (from != null && to != null) {
            audioSwitchTransition(
              from,
              to,
              progress: progress,
              forceFullDuration: !firedViaSwipe,
            );
          }
        }

        if (player.smartCurrentAudio != null) {
          lastAudio.value = player.smartCurrentAudio;
        }
        switchingViaSwipe.value = false;

        return null;
      },
      [player.currentAudio],
    );

    final prevAudio = player.smartPreviousAudio;
    final audio = lastAudio.value;
    final nextAudio = player.smartNextAudio;

    final playlist = player.currentPlaylist;
    final isLiked = audio?.isLiked ?? false;
    final isRecommendation = playlist?.isRecommendationTypePlaylist ?? false;

    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints consts) {
        final gapSize = mobileLayout ? gapSizeMobile : gapSizeDesktop;
        final draggableSize = consts.maxWidth - mobileThumbnailSize - gapSize;

        return SizedBox(
          height: double.infinity,
          child: ScrollableWidget(
            onChanged: (double diff) {
              if (!mobileLayout || isMobile) return null;

              return player.setVolume(
                clampDouble(
                  player.volume + diff / 10,
                  0.0,
                  1.0,
                ),
              );
            },
            child: MouseRegion(
              cursor: mobileLayout
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap:
                    mobileLayout ? () => openFullscreenPlayer(context) : null,
                onHorizontalDragStart: mobileLayout
                    ? (DragStartDetails details) {
                        switchAnimation.stop();
                        didVibration.value = false;
                        switchingViaSwipe.value = true;
                      }
                    : null,
                onHorizontalDragUpdate: mobileLayout
                    ? (DragUpdateDetails details) {
                        switchAnimation.value = clampDouble(
                          switchAnimation.value +
                              details.primaryDelta! / draggableSize,
                          -1.0,
                          1.0,
                        );

                        if (!didVibration.value &&
                            switchAnimation.value.abs() >= 0.5) {
                          didVibration.value = true;
                          HapticFeedback.heavyImpact();
                        } else if (didVibration.value &&
                            switchAnimation.value.abs() <= 0.5) {
                          didVibration.value = false;
                        }
                      }
                    : null,
                onHorizontalDragEnd: mobileLayout
                    ? (DragEndDetails details) async {
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
                    : null,
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
                              child: TrackTitleAndArtist(
                                title: audio?.title ?? "Unknown",
                                artist: audio?.artist ?? "Unknown",
                                subtitle: audio?.subtitle,
                                explicit: audio?.isExplicit ?? false,
                              ),
                            ),
                            Gap(gapSize),

                            // Кнопка дизлайка, если это рекомендованный плейлист.
                            if (isRecommendation) ...[
                              LoadingIconButton(
                                onPressed: onDislike,
                                icon: Icon(
                                  Icons.thumb_down_outlined,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                              const Gap(4),
                            ],

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
class _MiddleControls extends ConsumerWidget {
  const _MiddleControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesNotifier = ref.read(preferencesProvider.notifier);

    ref.watch(playerShuffleModeEnabledProvider);
    ref.watch(playerLoopModeProvider);

    final scheme = Theme.of(context).colorScheme;

    final isShuffling = player.shuffleModeEnabled;
    final isLooping = player.loopMode == LoopMode.one;
    final playlist = player.currentPlaylist;
    final isAudioMix = playlist?.type == PlaylistType.audioMix;

    void onShuffleToggle() async {
      assert(
        !isAudioMix,
        "Attempted to enable shuffle for audio mix",
      );

      await player.toggleShuffle();

      preferencesNotifier.setShuffleEnabled(player.shuffleModeEnabled);
    }

    void onRepeatToggle() async {
      await player.toggleLoopMode();

      preferencesNotifier.setLoopModeEnabled(player.loopMode == LoopMode.one);
    }

    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Shuffle.
        IconButton(
          onPressed: isAudioMix ? null : onShuffleToggle,
          icon: Icon(
            isAudioMix
                ? Icons.close
                : isShuffling
                    ? Icons.shuffle_on_outlined
                    : Icons.shuffle,
            color: isAudioMix ? null : scheme.onPrimaryContainer,
          ),
        ),

        // Кнопка предыдущего трека.
        IconButton(
          onPressed: () => player.smartPrevious(),
          icon: Icon(
            Icons.skip_previous,
            color: scheme.onPrimaryContainer,
          ),
        ),

        // Кнопка воспроизведения/паузы.
        GestureDetector(
          onLongPress: () => player.stop(),
          child: FilledButton(
            onPressed: () => player.togglePlay(),
            child: const PlayPauseAnimatedIcon(),
          ),
        ),

        // Кнопка следующего трека.
        IconButton(
          onPressed: () => player.next(),
          icon: Icon(
            Icons.skip_next,
            color: scheme.onPrimaryContainer,
          ),
        ),

        // Повтор текущего трека.
        IconButton(
          onPressed: onRepeatToggle,
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
    assert(
      !isMobileLayout(context),
      "This widget is only for Desktop Layout",
    );

    ref.watch(playerShuffleModeEnabledProvider);
    ref.watch(playerCurrentIndexProvider);
    ref.watch(playerLoopModeProvider);
    ref.watch(playerPositionProvider);

    final animation = useAnimationController(
      duration: MusicPlayerWidget.switchAnimationDuration,
    );
    useValueListenable(animation);

    final show = player.progress >= nextPlayingTextProgress;
    useEffect(
      () {
        if (show) {
          animation.forward();
        } else {
          animation.reverse();
        }

        return null;
      },
      [show],
    );

    if (animation.value == 0.0) {
      return const SizedBox();
    }

    final audio = useState(player.smartNextAudio);
    useEffect(
      () {
        if (player.smartNextAudio != null && animation.value == 0.0) {
          audio.value = player.smartNextAudio;
        }

        return null;
      },
      [animation.value, player.smartNextAudio],
    );

    final position =
        MusicPlayerWidget.desktopMiniPlayerHeight - 5.0 + animation.value * 15;
    final opacity = animation.value;
    final audioString = useMemoized(
      () {
        final currentAudio = audio.value;
        if (currentAudio == null) {
          return "Unknown";
        }

        if (currentAudio.subtitle == null) {
          return "${audio.value?.artist} • ${audio.value?.title}";
        }

        return "${audio.value?.artist} (${currentAudio.subtitle}) • ${audio.value?.title}";
      },
      [audio.value],
    );

    final scheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: position,
      child: Opacity(
        opacity: opacity,
        child: AnimatedSwitcher(
          duration: MusicPlayerWidget.switchAnimationDuration,
          child: Row(
            key: ValueKey(
              audio.value?.id,
            ),
            mainAxisSize: MainAxisSize.min,
            children: [
              // Иконка.
              Icon(
                Icons.music_note,
                color: scheme.primary,
              ),
              const Gap(8),

              // Название следующего трека.
              Text(
                audioString,
                style: TextStyle(
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет для [_MusicContents], отображающий содержимое части плеера по середине.
///
/// В такой части отображаются кнопки для управления воспроизведением, а так же прогресс-бар для текущего трека. Отображается только при Desktop Layout'е.
class _MusicMiddleSide extends HookConsumerWidget {
  const _MusicMiddleSide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      !isMobileLayout(context),
      "This widget is only for Desktop Layout",
    );

    ref.watch(playerPlayingStateProvider);
    ref.watch(playerPositionProvider);

    final preferences = ref.watch(preferencesProvider);
    final alternateSlider = preferences.alternateDesktopMiniplayerSlider;
    final showRemainingTime = preferences.showRemainingTime;

    final scheme = Theme.of(context).colorScheme;

    final isBuffering = player.buffering;
    final isPlaying = player.playing;
    final progress = player.progress;
    final position = player.position.inSeconds;
    final duration = player.duration?.inSeconds;

    final waveAnimation = useAnimationController(
      duration: MusicPlayerWidget.switchAnimationDuration,
      initialValue: isPlaying ? 1.0 : 0.0,
    );
    useValueListenable(waveAnimation);
    useEffect(
      () {
        waveAnimation.animateTo(isPlaying ? 1.0 : 0.0);

        return null;
      },
      [isPlaying],
    );

    final seekProgress = useState<double?>(null);
    final positionString = useMemoized(
      () {
        final positionSeconds = seekProgress.value == null
            ? position
            : ((duration ?? 0) * seekProgress.value!).toInt();

        // Если нам нужно показывать количество оставшегося времени, то показываем его.
        if (showRemainingTime) {
          final remainingSeconds = (duration ?? 0) - positionSeconds;

          return secondsAsString(remainingSeconds);
        }

        return secondsAsString(positionSeconds);
      },
      [position, seekProgress.value, showRemainingTime],
    );
    final durationString = useMemoized(
      () => secondsAsString(duration ?? 0),
      [duration],
    );

    void onPositionTextTap() => ref
        .read(preferencesProvider.notifier)
        .setShowRemainingTime(!showRemainingTime);

    return SizedBox(
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Slider для отображения прогресса воспроизведения трека,
          // либо индикатор загрузки, если идёт буферизация.
          if (!alternateSlider)
            if (!isBuffering)
              SliderTheme(
                data: SliderThemeData(
                  trackShape: WavyTrackShape(
                    waveHeightPercent: waveAnimation.value,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: scheme.onPrimaryContainer,
                  thumbColor: scheme.onPrimaryContainer,
                  inactiveTrackColor:
                      scheme.onPrimaryContainer.withOpacity(0.5),
                ),
                child: ResponsiveSlider(
                  value: progress,
                  onChange: (double progress) => seekProgress.value = progress,
                  onChangeEnd: (double progress) {
                    player.seekNormalized(progress);

                    seekProgress.value = null;
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(
                    globalBorderRadius,
                  ),
                  backgroundColor: scheme.onPrimaryContainer.withOpacity(0.5),
                ),
              ),

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
                              .withOpacity(isPlaying ? 1.0 : 0.75),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (alternateSlider) const Gap(16),

              // Кнопки управления воспроизведением.
              const _MiddleControls(),
              if (alternateSlider) const Gap(16),

              // Полная длительность трека.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    durationString,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer
                          .withOpacity(isPlaying ? 1.0 : 0.75),
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

/// Виджет, отображающий анимированную иконку для кнопки воспроизведения/паузы.
class PlayPauseAnimatedIcon extends HookConsumerWidget {
  /// Цвет иконки.
  final Color? color;

  const PlayPauseAnimatedIcon({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(playerPlayingStateProvider);

    final isPlaying = player.playing;
    final playPauseAnimation = useAnimationController(
      duration: MusicPlayerWidget.switchAnimationDuration,
      initialValue: isPlaying ? 1.0 : 0.0,
    );
    useEffect(
      () {
        if (isPlaying) {
          playPauseAnimation.forward();
        } else {
          playPauseAnimation.reverse();
        }

        return null;
      },
      [isPlaying],
    );

    return AnimatedIcon(
      icon: AnimatedIcons.play_pause,
      progress: playPauseAnimation,
      color: color,
    );
  }
}

/// Виджет для [_MusicContents], отображающий содержимое правой части плеера.
///
/// В такой части отображаются дополнительне кнопки для управления воспроизведением в Desktop Layout, либо ряд из некоторых простых кнопок (лайк, пауза) для Mobile Layout.
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

    ref.watch(playerPlaylistModificationsProvider);
    ref.watch(playerCurrentIndexProvider);
    ref.watch(playerPlayingStateProvider);
    if (!mobileLayout) {
      ref.watch(playerVolumeProvider);
    }

    final playlist = player.currentPlaylist;
    final audio = useState<ExtendedAudio?>(player.smartCurrentAudio);
    useEffect(
      () {
        if (player.smartCurrentAudio != null) {
          audio.value = player.smartCurrentAudio;
        }

        return null;
      },
      [player.currentAudio],
    );

    final volume = player.volume;

    final isLiked = audio.value?.isLiked ?? false;
    final isRecommendation = playlist?.isRecommendationTypePlaylist ?? false;

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
              onLongPress: () => player.stop(),
              child: IconButton(
                onPressed: () => player.togglePlay(),
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
          Flexible(
            child: SizedBox(
              width: 150,
              child: ScrollableSlider(
                value: volume,
                activeColor: scheme.onPrimaryContainer,
                inactiveColor: scheme.onPrimaryContainer.withOpacity(0.5),
                onChanged: (double newVolume) {
                  if (isMobile) return;

                  player.setVolume(newVolume);
                },
              ),
            ),
          ),
          const Gap(10),

          // Кнопка для перехода в мини-плеер.
          IconButton(
            onPressed: () => openMiniPlayer(context),
            icon: Icon(
              Icons.picture_in_picture_alt,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const Gap(2),

          // Кнопка для перехода в полноэкранный режим.
          if (isDesktop)
            IconButton(
              onPressed: () => openFullscreenPlayer(context),
              icon: Icon(
                Icons.fullscreen,
                color: scheme.onPrimaryContainer,
              ),
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
    final preferences = ref.watch(preferencesProvider);
    ref.watch(playerCurrentIndexProvider);
    ref.watch(playerPlayingStateProvider);
    ref.watch(playerPositionProvider);

    final isPlaying = player.playing;

    final scheme = Theme.of(context).colorScheme;
    final mobileLayout = isMobileLayout(context);

    final audio = player.smartNextAudio;
    final progress = player.progress;
    final clampedProgress = preferences.spoilerNextTrack
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

    final backgroundColor = useMemoized(
      () {
        Color baseColor = scheme.primaryContainer;

        // Затемняем, если трек не воспроизводится.
        if (!isPlaying) {
          baseColor = baseColor.darken(0.15);
        }

        // Если вот-вот начнётся воспроизведение следующего трека, то плавно переходим к его цвету.
        if (clampedProgress > 0.0) {
          baseColor = Color.lerp(
            baseColor,
            nextScheme?.primaryContainer ?? baseColor,
            clampedProgress,
          )!;
        }

        return baseColor;
      },
      [isPlaying, clampedProgress, scheme, nextScheme],
    );

    return AnimatedContainer(
      duration: MusicPlayerWidget.switchAnimationDuration,
      curve: Curves.ease,
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

/// Виджет для [_MusicContents], отображающий прогресс-бар внизу плеера. В случае, если идёт буферизация, то вместо прогресс-бара отображается индикатор загрузки.
class BottomMusicProgressBar extends ConsumerWidget {
  const BottomMusicProgressBar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(playerStateProvider).value;
    ref.watch(playerPositionProvider);

    final isBuffering = player.buffering;
    final isPlaying = player.playing;
    final progress = player.progress;

    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onPrimaryContainer.withOpacity(
      isPlaying ? 1 : 0.5,
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
          value: isBuffering ? null : progress,
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
  static final AppLogger logger = getLogger("MusicPlayerContentsWidget");

  /// Внутренний padding для содержимого плеера при Mobile Layout.
  static const double mobilePadding = 8;

  /// Внутренний padding для содержимого плеера при Desktop Layout.
  static const double desktopPadding = 12;

  const _MusicContents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);
    ref.watch(playerCurrentPlaylistProvider);

    final mobileLayout = isMobileLayout(context);

    final playlist = player.currentPlaylist;
    final isRecommendation = playlist?.isRecommendationTypePlaylist ?? false;

    final padding = (mobileLayout) ? mobilePadding : desktopPadding;
    final freeSpace = MediaQuery.of(context).size.width -
        (mobileLayout ? MusicPlayerWidget.mobilePadding * 2 : 0) -
        padding * 2;

    double leftBlockSize = 0;
    double? middleBlockSize;
    double rightBlockSize = 0;

    if (mobileLayout) {
      int buttonsCount = isRecommendation ? 3 : 2;

      rightBlockSize = buttonsCount * 48;
      leftBlockSize = freeSpace - rightBlockSize;
    } else {
      middleBlockSize = clampDouble(
        freeSpace / 2,
        100,
        650,
      );
      leftBlockSize = rightBlockSize = (freeSpace - middleBlockSize) / 2;
    }

    Future<void> onLikeTap() async {
      if (!networkRequiredDialog(ref, context)) return;

      final l18n = ref.read(l18nProvider);
      final preferences = ref.read(preferencesProvider);

      if (!player.currentAudio!.isLiked && preferences.checkBeforeFavorite) {
        if (!await checkForDuplicates(
          ref,
          context,
          player.currentAudio!,
        )) return;
      }

      try {
        await toggleTrackLike(
          player.ref,
          player.currentAudio!,
          !player.currentAudio!.isLiked,
          sourcePlaylist: player.currentPlaylist,
        );
      } on VKAPIException catch (error, stackTrace) {
        if (!context.mounted) return;

        if (error.errorCode == 15) {
          showErrorDialog(
            context,
            description: l18n.music_likeRestoreTooLate,
          );

          return;
        }

        showLogErrorDialog(
          "Error while restoring audio:",
          error,
          stackTrace,
          logger,
          context,
        );
      }
    }

    Future<void> onDislikeTap() async {
      if (!networkRequiredDialog(ref, context)) return;

      await dislikeTrack(
        player.ref,
        player.currentAudio!,
      );

      await player.next();
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Спойлер следующего трека.
        if (preferences.spoilerNextTrack && !mobileLayout)
          const NextTrackSpoilerWidget(),

        // Фон плеера, который может плавно менять цвет в зависимости от текущего трека.
        const MusicPlayerBackgroundWidget(),

        // Содержимое плеера.
        Padding(
          padding: EdgeInsets.all(
            padding,
          ),
          child: Row(
            children: [
              RepaintBoundary(
                child: SizedBox(
                  width: leftBlockSize,
                  child: _MusicLeftSide(
                    onLike: onLikeTap,
                    onDislike: onDislikeTap,
                  ),
                ),
              ),
              if (!mobileLayout)
                RepaintBoundary(
                  child: SizedBox(
                    width: middleBlockSize!,
                    child: const _MusicMiddleSide(),
                  ),
                ),
              RepaintBoundary(
                child: SizedBox(
                  width: rightBlockSize,
                  child: _MusicRightSide(
                    onLike: onLikeTap,
                    onDislike: onDislikeTap,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Прогресс-бар.
        if (mobileLayout ||
            (!mobileLayout && preferences.alternateDesktopMiniplayerSlider))
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
///   - [_MusicLeftSide]
///     - [_LeftSideThumbnail]
///   - [_MusicMiddleSide]
///     - [_MiddleControls]
///   - [_MusicRightSide]
class MusicPlayerWidget extends HookConsumerWidget {
  static final AppLogger logger = getLogger("MusicPlayer");

  /// Padding для этого виджета при Mobile Layout.
  static const double mobilePadding = 8;

  /// Размер мини-плеера для Mobile Layout без учёта padding'а.
  static const double mobileHeight = 66;

  /// Размер мини-плеера для Mobile Layout'а с учётом padding'ов.
  static const double mobileHeightWithPadding = mobileHeight + mobilePadding;

  /// Размер мини-плеера для Desktop Layout.
  static const double desktopMiniPlayerHeight = 88;

  /// Длительность анимации переключения треков, а так же кнопки паузы/воспроизведения.
  static const Duration switchAnimationDuration = Duration(milliseconds: 400);

  const MusicPlayerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobileLayout = isMobileLayout(context);

    final trackSchemeInfo = ref.watch(trackSchemeInfoProvider);
    final preferences = ref.watch(preferencesProvider);
    final bool isPlaying = ref.watch(playerPlayingStateProvider).value ?? false;

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
        height: mobileLayout ? mobileHeight : desktopMiniPlayerHeight,
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
