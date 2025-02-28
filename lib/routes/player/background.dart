import "dart:ui";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../extensions.dart";
import "../../provider/player.dart";
import "../../provider/preferences.dart";
import "../../services/cache_manager.dart";

/// Виджет, отображаемый как фон плеера, если у трека нет обложки.
class BackgroundFallbackImage extends StatelessWidget {
  const BackgroundFallbackImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primaryContainer,
            scheme.primaryContainer.darken(0.5),
          ],
        ),
      ),
    );
  }
}

/// Виджет, отображаемый фон плеера, а так же анимирующий его изменения.
///
/// Фон - изображение текущего трека, которое затемнено и имеет эффект размытия. Если у трека нет обложки, то используется градиент [BackgroundFallbackImage].
class BackgroundImage extends HookConsumerWidget {
  /// Длительность анимации перехода между изображениями.
  static const Duration animationDuration = Duration(seconds: 1);

  /// Радиус размытия изображения.
  static const double blurRadius = 50;

  /// Цвет, используемый для затемнения изображения.
  static const Color darkenColor = Color(0x8A000000);

  const BackgroundImage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsBackground = ref.watch(
      preferencesProvider.select((value) {
        return value.playerThumbAsBackground;
      }),
    );
    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);
    ref.watch(playerAudioProvider);

    final isLoaded = player.isLoaded;
    final audio = player.audio;
    if (!isLoaded || audio == null) {
      return const SizedBox.shrink();
    }

    final sizeOf = MediaQuery.sizeOf(context);
    final width = sizeOf.width;
    final height = sizeOf.height;
    final imageUrl = audio.maxThumbnail;

    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blurRadius,
        sigmaY: blurRadius,
      ),
      child: AnimatedSwitcher(
        duration: animationDuration,
        child: imageAsBackground && imageUrl != null
            ? SizedBox(
                key: ValueKey(
                  imageUrl,
                ),
                width: width,
                height: height,
                child: CachedNetworkImage(
                  imageUrl: audio.smallestThumbnail!,
                  cacheKey: "${audio.mediaKey}small",
                  fit: BoxFit.cover,
                  color: darkenColor,
                  colorBlendMode: BlendMode.darken,
                  placeholder: (BuildContext context, String string) {
                    return const BackgroundFallbackImage();
                  },
                  cacheManager: CachedAlbumImagesManager.instance,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholderFadeInDuration: Duration.zero,
                ),
              )
            : const BackgroundFallbackImage(),
      ),
    );
  }
}
