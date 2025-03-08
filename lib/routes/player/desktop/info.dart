import "dart:async";
import "dart:math";
import "dart:ui";

import "package:animations/animations.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../extensions.dart";
import "../../../provider/player.dart";
import "../../../provider/preferences.dart";
import "../../../utils.dart";
import "../../../widgets/audio_player.dart";
import "../../../widgets/audio_track.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/loading_button.dart";
import "../../../widgets/scrollable_slider.dart";
import "../../../widgets/wavy_slider.dart";
import "../desktop.dart";
import "../shared.dart";

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

    final isRecommendation = playlist?.isRecommendationTypePlaylist == true;

    Future<void> onLikeTap() async {
      HapticFeedback.lightImpact();
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
      HapticFeedback.lightImpact();
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
        if (isRecommendation)
          LoadingIconButton(
            icon: Icon(
              Icons.thumb_down_outlined,
              color: scheme.onPrimaryContainer,
            ),
            color: scheme.onPrimaryContainer,
            onPressed: onDislikeTap,
          )
        else
          const Gap(40),
      ],
    );
  }
}

/// Виджет, отображаемый изображение текущего трека.
class _Image extends HookConsumerWidget {
  /// Радиус скругления изображений.
  static const double borderRadius = 16;

  /// Длительность анимации перехода между изображениями.
  static const Duration animationDuration = Duration(seconds: 1);

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

    return AnimatedSwitcher(
      duration: animationDuration,
      child: Stack(
        key: ValueKey(
          imageUrl,
        ),
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          BackgroundGlowImageWidget(
            audio: audio!,
          ),
          AudioImageWidget(
            audio: audio,
            size: size,
            borderRadius: borderRadius,
          ),
          AudioAnimatedImageWidget(
            audio: audio,
            size: size,
            borderRadius: borderRadius,
          ),
        ],
      ),
    );
  }
}

/// Левый ряд для управления плеером ([_Controls]).
class _LeftControls extends ConsumerWidget {
  /// Использовать ли компактный вид.
  final bool dense;

  const _LeftControls({
    this.dense = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final queueEnabled =
        ref.watch(preferencesProvider.select((val) => val.playerQueueBlock));
    final lyricsEnabled =
        ref.watch(preferencesProvider.select((val) => val.playerLyricsBlock));

    final scheme = Theme.of(context).colorScheme;

    void onQueueToggle() {
      prefsNotifier.setPlayerQueueBlockEnabled(!queueEnabled);
    }

    void onLyricsToggle() {
      prefsNotifier.setPlayerLyricsBlockEnabled(!lyricsEnabled);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: dense ? 0 : 8,
      children: [
        IconButton(
          onPressed: onQueueToggle,
          icon: Icon(
            queueEnabled ? Icons.queue_music : Icons.queue_music_outlined,
            color: queueEnabled ? scheme.primary : scheme.onPrimaryContainer,
          ),
        ),
        IconButton(
          onPressed: onLyricsToggle,
          icon: Icon(
            lyricsEnabled ? Icons.lyrics : Icons.lyrics_outlined,
            color: lyricsEnabled ? scheme.primary : scheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

/// Правый ряд для управления плеером ([_Controls]).
class _RightControls extends HookConsumerWidget {
  /// Использовать ли компактный вид.
  final bool dense;

  /// Указывает, что будет использоваться [Slider] для громкости без замены на [Icon].
  ///
  /// Если false, то будет использоваться [Icon], который при наведении на этот блок будет заменяться на [Slider].
  final bool fullVolume;

  /// Вызвается при наведении на иконку громкости.
  final void Function(bool)? onHovered;

  const _RightControls({
    this.dense = false,
    this.fullVolume = false,
    this.onHovered,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerVolumeProvider);

    final volume = player.volume;

    final scheme = Theme.of(context).colorScheme;

    void onFullscreenClose() {
      Navigator.of(context).pop();
    }

    return MouseRegion(
      onEnter: (_) {
        onHovered?.call(true);
      },
      onExit: (_) {
        onHovered?.call(false);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: dense ? 0 : 8,
        children: [
          AnimatedSwitcher(
            duration: _Controls.transitionDuration,
            child: fullVolume
                ? SizedBox(
                    width: 125,
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
                  )
                : Icon(
                    Icons.volume_up,
                    color: scheme.onPrimaryContainer,
                  ),
          ),
          IconButton(
            onPressed: onFullscreenClose,
            icon: Icon(
              Icons.fullscreen_exit,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ряд для управления плеером.
class _Controls extends HookConsumerWidget {
  /// Длительность анимации "раскрытия" и "перемещения" блоков управления при наведении на блок с громкостью.
  static const Duration transitionDuration = Duration(milliseconds: 300);

  /// Размер изображения.
  final double size;

  const _Controls({
    required this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showFullVolume = size >= 580;
    final useLessSpacing = size <= 450;
    final hideSideButtons = size < 360;
    final useDense = size < 250;

    final volumeExpanded = useState(false);

    void onVolumeHovered(bool isHovered) {
      if (showFullVolume) return;

      volumeExpanded.value = isHovered;
    }

    useEffect(
      () {
        if (showFullVolume) {
          volumeExpanded.value = false;
        }

        return;
      },
      [showFullVolume],
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (!hideSideButtons)
          AnimatedOpacity(
            duration: transitionDuration,
            opacity: volumeExpanded.value ? 0.0 : 1.0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _LeftControls(
                dense: useLessSpacing,
              ),
            ),
          ),
        AnimatedAlign(
          duration: transitionDuration,
          alignment:
              volumeExpanded.value ? Alignment.centerLeft : Alignment.center,
          curve: Curves.easeInOut,
          child: PlayerControlsWidget(
            dense: useLessSpacing && (useDense || !hideSideButtons),
            showShuffle: !useDense,
            showRepeat: !useDense,
          ),
        ),
        if (!hideSideButtons)
          Align(
            alignment: Alignment.centerRight,
            child: _RightControls(
              dense: useLessSpacing,
              fullVolume: showFullVolume || volumeExpanded.value,
              onHovered: onVolumeHovered,
            ),
          ),
      ],
    );
  }
}

/// Отображает блок с информацией по тому треку, который воспроизводится.
class CurrentAudioBlock extends ConsumerWidget {
  /// Размер этого блока.
  final Size size;

  const CurrentAudioBlock({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageSize = clampDouble(
      min(
        size.width - 100,
        size.height - 200,
      ),
      100,
      800,
    );

    return Column(
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
        RepaintBoundary(
          child: SizedBox(
            width: imageSize,
            child: const SliderWithProgressWidget(),
          ),
        ),
        SizedBox(
          width: imageSize,
          child: _Controls(
            size: imageSize,
          ),
        ),
      ],
    );
  }
}
