import "package:flutter/material.dart";

/// Расширение для [RoundedRectSliderTrackShape], которое рисует волну для [Slider].
class WavyTrackShape extends RoundedRectSliderTrackShape {
  /// Длина одной части волны (подъем/спуск).
  static const double waveWidth = 10;

  /// Полная длина волны, включая подъем и спуск.
  static const double fullWaveWidth = waveWidth * 2;

  /// Значение процента высоты волны, где `1.0` - это 100% высоты от волны.
  final double waveHeightPercent;

  const WavyTrackShape({
    this.waveHeightPercent = 1.0,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    assert(
      waveHeightPercent >= 0.0 && waveHeightPercent <= 1.0,
      "waveHeightPercent must be between 0.0 and 1.0",
    );

    final paint = Paint()
      ..color = sliderTheme.activeTrackColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final height = parentBox.size.height;
    final width = parentBox.size.width;
    final widthBeforeThumb = thumbCenter.dx;

    final path = Path()
      ..moveTo(
        offset.dx,
        offset.dy + height / 2,
      );

    // Рисуем волну до ползунка.
    if (waveHeightPercent > 0) {
      for (double i = 0; i < widthBeforeThumb; i += waveWidth) {
        final isEven = i % fullWaveWidth == 0;

        path.relativeQuadraticBezierTo(
          5,
          (isEven ? -2.5 : 2.5) * waveHeightPercent,
          waveWidth,
          0,
        );
      }
    } else {
      path.lineTo(
        thumbCenter.dx,
        offset.dy + height / 2,
      );
    }

    // Рисуем линию после ползунка.
    final inactivePath = Path()
      ..moveTo(
        thumbCenter.dx,
        offset.dy + height / 2,
      )
      ..lineTo(
        offset.dx + width,
        offset.dy + height / 2,
      );

    // Рисуем пути.
    context.canvas.drawPath(path, paint);
    context.canvas.drawPath(inactivePath, inactivePaint);
  }
}
