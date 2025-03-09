import "package:flutter/material.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../extensions.dart";
import "audio_track.dart";

/// Fallback-виджет, используемый в случае, если у трека нет изображения.
class FallbackAudioAvatar extends StatelessWidget {
  /// Высота. По умолчанию, используется [AudioTrackTile.height].
  final double size;

  /// Радиус скругления.
  final double? borderRadius;

  const FallbackAudioAvatar({
    super.key,
    this.size = AudioTrackTile.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius:
            borderRadius != null ? BorderRadius.circular(borderRadius!) : null,
      ),
      child: Center(
        child: Skeleton.keep(
          child: Icon(
            Icons.music_note,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Fallback-виджет, используемый в случае, если у плейлиста нет изображения.
class FallbackAudioPlaylistAvatar extends StatelessWidget {
  /// Указывает, что данный плейлист является плейлистом типа "Любимая музыка". Плейлисты такого вида имеют иконку сердца внутри, а так же небольшой градиент.
  final bool favoritesPlaylist;

  /// Значение, используемое как ширина и высота для данного виджета.
  final double size;

  const FallbackAudioPlaylistAvatar({
    super.key,
    this.favoritesPlaylist = false,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: favoritesPlaylist
            ? LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  scheme.primaryContainer,
                  scheme.primaryContainer.lighten(0.25),
                ],
              )
            : null,
        color: favoritesPlaylist ? null : scheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Skeleton.keep(
          child: Icon(
            favoritesPlaylist ? Icons.favorite : Icons.queue_music,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: size > 50 ? 56 : null,
          ),
        ),
      ),
    );
  }
}
