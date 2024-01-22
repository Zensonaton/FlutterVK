import "package:flutter/material.dart";
import "package:skeletonizer/skeletonizer.dart";

/// Fallback-виджет, используемый в случае, если у трека нет изображения.
class FallbackAudioAvatar extends StatelessWidget {
  /// Ширина. По умолчанию используется 50.
  final double width;

  /// Высота. По умолчанию используется 50.
  final double height;

  const FallbackAudioAvatar({
    super.key,
    this.width = 50,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      width: width,
      height: height,
      child: Center(
        child: Skeleton.keep(
          child: Icon(
            Icons.music_note,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

/// Fallback-виджет, используемый в случае, если у плейлиста нет изображения.
class FallbackAudioPlaylistAvatar extends StatelessWidget {
  const FallbackAudioPlaylistAvatar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      width: 200,
      height: 200,
      child: Center(
        child: Skeleton.keep(
          child: Icon(
            Icons.queue_music,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: 56,
          ),
        ),
      ),
    );
  }
}
