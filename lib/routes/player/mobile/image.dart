import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../provider/player.dart";
import "../shared.dart";

/// Виджет для [MobilePlayerWidget], отображающий изображение трека, которое можно передвигать пальцем для переключения между треками.
class TrackImageWidget extends ConsumerWidget {
  /// Размер одной из сторон изображения.
  final double size;

  const TrackImageWidget({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider);
    ref.watch(playerAudioProvider);

    final audio = player.audio;

    return Stack(
      children: [
        AudioImageWidget(
          audio: audio!,
          size: size,
        ),
        AudioAnimatedImageWidget(
          audio: audio,
          size: size,
        ),
      ],
    );
  }
}
