import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Виджет, который делает Fade-out эффект для виджетов со [ScrollController]'ами.
class FadingListView extends HookWidget {
  /// [Widget], для которого будет использоваться эффект.
  final Widget child;

  /// Направление для скроллинга.
  final Axis scrollDirection;

  /// Указывает, что скроллинг производится в обратную сторону.
  final bool reverse;

  /// Указывает число, которое используется как делитесь для расстояния.
  final double distanceDivider;

  /// Указывает "мощность" эффекта.
  final double strength;

  const FadingListView({
    super.key,
    required this.child,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.distanceDivider = 200,
    this.strength = 0.025,
  });

  @override
  Widget build(BuildContext context) {
    final stopStart = useState(0.0);
    final stopEnd = useState(1.0);

    return NotificationListener(
      onNotification: (ScrollNotification scrollNotification) {
        stopStart.value = clampDouble(
          scrollNotification.metrics.pixels / distanceDivider,
          0.0,
          1.0,
        );
        stopEnd.value = clampDouble(
          (scrollNotification.metrics.maxScrollExtent -
                  scrollNotification.metrics.pixels) /
              distanceDivider,
          0.0,
          1.0,
        );

        return true;
      },
      child: ShaderMask(
        shaderCallback: (Rect rect) {
          return LinearGradient(
            begin: scrollDirection == Axis.horizontal
                ? Alignment.centerLeft
                : Alignment.topCenter,
            end: scrollDirection == Axis.horizontal
                ? Alignment.centerRight
                : Alignment.bottomCenter,
            colors: const [
              Colors.black,
              Colors.transparent,
              Colors.transparent,
              Colors.black,
            ],
            stops: reverse
                ? [
                    0.0,
                    strength * stopEnd.value,
                    1 - strength * stopStart.value,
                    1.0,
                  ]
                : [
                    0.0,
                    strength * stopStart.value,
                    1 - strength * stopEnd.value,
                    1.0,
                  ],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstOut,
      ),
    );
  }
}
