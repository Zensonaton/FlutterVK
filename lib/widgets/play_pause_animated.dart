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
  /// Размер внутреннего padding'а.
  static const double padding = 8;

  /// Callback-метод, вызываемый при нажатии на эту кнопку.
  final VoidCallback onPressed;

  /// Callback-метод, вызываемый при длительном нажатии на эту кнопку.
  final VoidCallback? onLongPress;

  /// Цвет для фона кнопка.
  final Color? backgroundColor;

  /// Цвет для иконки.
  final Color? color;

  /// Размер иконки.
  final double? iconSize;

  const PlayPauseAnimatedButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.backgroundColor,
    this.color,
    this.iconSize,
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

    final sideSize = 2 * padding + (iconSize ?? 24);
    final borderRadius =
        BorderRadius.circular(sideSize / 2 - 6 * playPauseAnimation.value);

    return InkWell(
      onTap: onPressed,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: backgroundColor,
          ),
          padding: const EdgeInsets.all(
            padding,
          ),
          child: PlayPauseAnimatedIcon(
            color: color,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
