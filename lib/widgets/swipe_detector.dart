import "package:flutter/material.dart";

/// Виджет для получения событий о свайпе на определённом виджете.
class SwipeDetector extends StatefulWidget {
  static const double minMainDisplacement = 50;
  static const double maxCrossRatio = 0.75;
  static const double minVelocity = 300;

  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final HitTestBehavior? behavior;
  final Function()? onTap;
  final Function()? onDoubleTap;
  final Widget child;

  const SwipeDetector({
    super.key,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.behavior,
    this.onTap,
    this.onDoubleTap,
    required this.child,
  });

  @override
  State<SwipeDetector> createState() => _SwipeDetectorState();
}

class _SwipeDetectorState extends State<SwipeDetector> {
  DragStartDetails? panStartDetails;
  DragUpdateDetails? panUpdateDetails;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => panUpdateDetails = null,
      behavior: widget.behavior,
      onPanStart: (startDetails) => panStartDetails = startDetails,
      onPanUpdate: (updateDetails) => panUpdateDetails = updateDetails,
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onPanEnd: (endDetails) {
        if (panStartDetails == null || panUpdateDetails == null) return;

        double dx = panUpdateDetails!.globalPosition.dx -
            panStartDetails!.globalPosition.dx;
        double dy = panUpdateDetails!.globalPosition.dy -
            panStartDetails!.globalPosition.dy;

        int panDurationMiliseconds =
            panUpdateDetails!.sourceTimeStamp!.inMilliseconds -
                panStartDetails!.sourceTimeStamp!.inMilliseconds;

        double mainDis, crossDis, mainVel;
        bool isHorizontalMainAxis = dx.abs() > dy.abs();

        if (isHorizontalMainAxis) {
          mainDis = dx.abs();
          crossDis = dy.abs();
        } else {
          mainDis = dy.abs();
          crossDis = dx.abs();
        }

        mainVel = 1000 * mainDis / panDurationMiliseconds;

        if (mainDis < SwipeDetector.minMainDisplacement) {
          return;
        }
        if (crossDis > SwipeDetector.maxCrossRatio * mainDis) {
          return;
        }
        if (mainVel < SwipeDetector.minVelocity) {
          return;
        }

        if (isHorizontalMainAxis) {
          if (dx > 0) {
            widget.onSwipeRight?.call();
          } else {
            widget.onSwipeLeft?.call();
          }
        } else {
          if (dy < 0) {
            widget.onSwipeUp?.call();
          } else {
            widget.onSwipeDown?.call();
          }
        }
      },
      child: widget.child,
    );
  }
}
