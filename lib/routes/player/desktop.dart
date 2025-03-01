import "package:flutter/material.dart";

import "desktop/info.dart";
import "desktop/lyrics.dart";
import "desktop/queue.dart";

/// Часть [PlayerRoute], отображающая полнооконный плеер для Desktop Layout'а.
class DesktopPlayerWidget extends StatelessWidget {
  /// Длительность для всех переходов между треками.
  static const Duration transitionDuration = Duration(milliseconds: 500);

  /// Размер Padding'а.
  static const EdgeInsets paddingSize = EdgeInsets.all(50);

  /// Расстояние между блоками.
  static const double gapSize = 50;

  const DesktopPlayerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mqSize = MediaQuery.sizeOf(context);
    final mqPadding = MediaQuery.paddingOf(context);
    final availableWidth =
        mqSize.width - mqPadding.horizontal - paddingSize.horizontal;
    final availableHeight =
        mqSize.height - mqPadding.vertical - paddingSize.vertical;

    const blocksCount = 3;
    final blockWidth =
        (availableWidth - (blocksCount - 1) * gapSize) / blocksCount;
    final blockSize = Size(
      blockWidth,
      availableHeight,
    );

    return SafeArea(
      child: Padding(
        padding: paddingSize,
        child: SizedBox(
          width: availableWidth,
          height: availableHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: gapSize,
            children: [
              if (blocksCount >= 2)
                QueueInfoBlock(
                  size: blockSize,
                ),
              if (blocksCount >= 1)
                CurrentAudioBlock(
                  size: blockSize,
                ),
              if (blocksCount >= 3)
                LyricsInfoBlock(
                  size: blockSize,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
