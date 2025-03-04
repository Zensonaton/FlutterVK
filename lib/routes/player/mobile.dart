import "dart:math";
import "dart:ui";

import "package:flutter/material.dart";

import "mobile/bottom.dart";
import "mobile/image.dart";
import "mobile/info.dart";
import "mobile/top.dart";

/// Часть [PlayerRoute], отображающая полнооконный плеер для Mobile Layout'а.
class MobilePlayerWidget extends StatelessWidget {
  /// Длительность для всех переходов между треками.
  static const Duration transitionDuration = Duration(milliseconds: 500);

  /// Размер Padding'а.
  static const EdgeInsets padding = EdgeInsets.all(16);

  /// Размер блоков [TopBarWidget] (сверху) и [BottomBarWidget] (снизу).
  static const double barHeight = 50;

  const MobilePlayerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mqSize = MediaQuery.sizeOf(context);
    final mqPadding = MediaQuery.paddingOf(context);

    final fullAreaSize = Size(
      mqSize.width - padding.horizontal - mqPadding.horizontal,
      mqSize.height - padding.vertical - mqPadding.vertical,
    );
    // final bodySize = Size(
    //   fullAreaSize.width,
    //   fullAreaSize.height - barHeight * 2,
    // );
    final imageSize = clampDouble(
      min(
        fullAreaSize.width,
        fullAreaSize.height - 300,
      ),
      100,
      1500,
    );

    return SafeArea(
      child: Padding(
        padding: padding,
        child: SizedBox(
          width: fullAreaSize.width,
          height: fullAreaSize.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                height: barHeight,
                child: TopBarWidget(),
              ),
              Align(
                child: TrackImageWidget(
                  size: imageSize,
                ),
              ),
              const TrackInfoWidget(),
              const SizedBox(
                height: barHeight,
                child: BottomBarWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
