import "dart:ui";

import "package:flutter/material.dart";

/// Виджет, который делает Fade-out эффект для виджетов со [ScrollController]'ами.
class FadingListView extends StatefulWidget {
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
  State<FadingListView> createState() => _FadingListViewState();
}

class _FadingListViewState extends State<FadingListView> {
  double stopStart = 0.0;
  double stopEnd = 1.0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (ScrollNotification scrollNotification) {
        setState(() {
          stopStart = clampDouble(
            scrollNotification.metrics.pixels / widget.distanceDivider,
            0.0,
            1.0,
          );
          stopEnd = clampDouble(
            (scrollNotification.metrics.maxScrollExtent -
                    scrollNotification.metrics.pixels) /
                widget.distanceDivider,
            0.0,
            1.0,
          );
        });

        return true;
      },
      child: ShaderMask(
        shaderCallback: (Rect rect) {
          return LinearGradient(
            begin: widget.scrollDirection == Axis.horizontal
                ? Alignment.centerLeft
                : Alignment.topCenter,
            end: widget.scrollDirection == Axis.horizontal
                ? Alignment.centerRight
                : Alignment.bottomCenter,
            colors: const [
              Colors.black,
              Colors.transparent,
              Colors.transparent,
              Colors.black,
            ],
            stops: widget.reverse
                ? [
                    0.0,
                    widget.strength * stopEnd,
                    1 - widget.strength * stopStart,
                    1.0,
                  ]
                : [
                    0.0,
                    widget.strength * stopStart,
                    1 - widget.strength * stopEnd,
                    1.0,
                  ],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstOut,
        child: widget.child,
      ),
    );
  }
}
