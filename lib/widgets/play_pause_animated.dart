import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../provider/player.dart";
import "audio_player.dart";

/// Виджет, отображающий анимированную иконку для кнопки воспроизведения/паузы.
class PlayPauseAnimatedIcon extends HookConsumerWidget {
  /// Цвет иконки.
  final Color? color;

  /// Размер иконки.
  final double? size;

  const PlayPauseAnimatedIcon({
    super.key,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerIsPlayingProvider);

    final isPlaying = player.isPlaying;
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
      size: size,
    );
  }
}

/// Кнопка, которая меняет форму в зависимости от того, поставлен ли плеер на паузу или нет.
class PlayPauseAnimatedButton extends HookConsumerWidget {
  /// Callback-метод, вызываемый при нажатии на эту кнопку.
  final VoidCallback onPressed;

  /// Callback-метод, вызываемый при длительном нажатии на эту кнопку.
  final VoidCallback? onLongPress;

  const PlayPauseAnimatedButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerIsPlayingProvider);

    final isPlaying = player.isPlaying;
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
    useValueListenable(playPauseAnimation);

    final BorderRadius borderRadius =
        BorderRadius.circular(20 - 6 * playPauseAnimation.value);

    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: scheme.onPrimaryContainer,
          ),
          padding: const EdgeInsets.all(8),
          child: PlayPauseAnimatedIcon(
            color: scheme.primaryContainer,
          ),
        ),
      ),
    );
  }
}
