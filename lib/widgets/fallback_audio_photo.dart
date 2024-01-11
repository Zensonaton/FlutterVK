import "package:flutter/material.dart";
import "package:skeletonizer/skeletonizer.dart";

/// Fallback-виджет, используемый в случае, если у трека нет изображения.
class FallbackAudioAvatar extends StatelessWidget {
  const FallbackAudioAvatar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      width: 50,
      height: 50,
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
