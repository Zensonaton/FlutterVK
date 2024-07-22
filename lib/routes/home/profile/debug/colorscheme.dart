import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../../main.dart";
import "../../../../provider/color.dart";
import "../../../../provider/player_events.dart";
import "../../../../provider/user.dart";
import "../../../../services/cache_manager.dart";
import "../../../../widgets/fallback_audio_photo.dart";

/// Небольшой контейнер с цветом.
class ColorPill extends ConsumerWidget {
  final Color color;
  final int count;

  const ColorPill({
    super.key,
    required this.color,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int brightness = (color.computeLuminance() * 100).round();

    return Container(
      color: color,
      padding: const EdgeInsets.all(
        8,
      ),
      width: 150,
      child: Text(
        count == 0
            ? "$color\nbrightness $brightness%"
            : "$color\nbrightness $brightness%\n$count times",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: brightness >= 40 ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

/// Debug-меню, отображаемое в [HomeProfilePage] если включён debug-режим ([kDebugMode]), отображающая техническую информацию о цветовой схеме, полученной от цветов плеера.
class ColorSchemeDebugMenu extends ConsumerWidget {
  const ColorSchemeDebugMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ExtendedAudio? playingAudio = player.currentAudio;
    final schemeInfo = ref.watch(trackSchemeInfoProvider);
    ref.watch(playerLoadedStateProvider);
    ref.watch(playerCurrentIndexProvider);

    if (playingAudio == null) {
      return const Center(
        child: Text(
          "No audio is playing",
        ),
      );
    }

    if (schemeInfo == null) {
      return const Center(
        child: Text(
          "No data is yet available",
        ),
      );
    }

    final colors = schemeInfo.getColors();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Colorscheme debug",
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        children: [
          // Изображение трека.
          SizedBox(
            width: 300,
            height: 300,
            child: player.currentAudio!.maxThumbnail != null
                ? CachedNetworkImage(
                    imageUrl: player.currentAudio!.maxThumbnail!,
                    cacheKey: "${player.currentAudio!.mediaKey}max",
                    placeholder: (BuildContext context, String url) =>
                        const FallbackAudioAvatar(),
                    cacheManager: CachedAlbumImagesManager.instance,
                  )
                : const FallbackAudioAvatar(),
          ),
          const Gap(20),

          // Время, затраченное на получение цветов.
          Text(
            "Quantize (non-UI blocking): ${schemeInfo.quantizeDuration?.inMilliseconds}ms",
          ),
          const Gap(20),

          // Извлечённые основные цвета.
          Text(
            "Extracted primary colors (used for ColorScheme creation): ${schemeInfo.scoredColorInts.length}",
          ),
          const Gap(8),
          SelectionArea(
            child: Wrap(
              spacing: 8,
              children: schemeInfo
                  .getScoredColors()
                  .map(
                    (Color color) => ColorPill(
                      color: color,
                    ),
                  )
                  .toList(),
            ),
          ),
          const Gap(20),

          // Самый частый цвет, а так же общее количество цветов.
          Text(
            "Total colors (duplicated included): ${schemeInfo.colorCount}, frequent color percentage: ${(schemeInfo.frequentColorPercentage * 100).round()}%",
          ),
          const Gap(8),
          SelectionArea(
            child: ColorPill(
              color: schemeInfo.frequentColor,
              count: schemeInfo.frequentColorCount,
            ),
          ),

          // Извлечённые цвета.
          Text("Extracted colors: ${schemeInfo.colorInts.length}"),
          const Gap(8),
          SelectionArea(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.keys
                  .map(
                    (Color color) => ColorPill(
                      color: color,
                      count: colors[color]!,
                    ),
                  )
                  .toList(),
            ),
          ),

          const Gap(100),
        ],
      ),
    );
  }
}
