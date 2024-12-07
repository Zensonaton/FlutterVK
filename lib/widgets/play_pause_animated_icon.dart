import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../main.dart";
import "../provider/player_events.dart";
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
      size: size,
    );
  }
}
