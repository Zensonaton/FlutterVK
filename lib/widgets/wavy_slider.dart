import "package:flutter/material.dart";

/// Расширение для [RoundedRectSliderTrackShape], которое рисует волну для [Slider].
class WavyTrackShape extends RoundedRectSliderTrackShape {
  /// Длина одной части волны (подъем/спуск).
  static const double waveWidth = 13;

  /// Высота одной части волны (подъем/спуск).
  static const double waveHeight = 5;

  /// Значение процента высоты волны, где `1.0` - это 100% высоты от волны.
  ///
  /// Используется для анимации перехода из "плоской" линии в "волнистую".
  final double waveHeightPercent;

  /// Значение процента смещения волны влево, где `1.0` - это 100% первого блока волны.
  ///
  /// Используется для реализации анимация движения волны.
  final double waveOffsetPercent;

  const WavyTrackShape({
    this.waveHeightPercent = 1.0,
    this.waveOffsetPercent = 0.0,
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
    if (waveHeightPercent < 0.0 || waveHeightPercent > 1.0) {
      throw ArgumentError("waveHeightPercent must be between 0.0 and 1.0");
    }
    if (waveOffsetPercent < 0.0 || waveOffsetPercent > 1.0) {
      throw ArgumentError("waveOffsetPercent must be between 0.0 and 1.0");
    }

    final paint = Paint()
      ..color = sliderTheme.activeTrackColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3;

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final height = parentBox.size.height;
    final halfHeight = height / 2;

    final additionalWaveWidth = 2 * waveWidth * waveOffsetPercent;
    final widthBeforeThumb =
        thumbCenter.dx - trackRect.left + additionalWaveWidth;

    final path = Path()
      ..moveTo(
        trackRect.left,
        offset.dy + halfHeight,
      );
    final inactivePath = Path()
      ..moveTo(
        thumbCenter.dx,
        offset.dy + halfHeight,
      )
      ..lineTo(
        trackRect.right,
        offset.dy + halfHeight,
      );

    // Рисуем волны до ползунка.
    if (waveHeightPercent > 0) {
      final int wavesCount = (widthBeforeThumb / waveWidth).ceil();

      // Для реализации анимации движения волны, смещаем путь на `additionalWaveWidth` влево.
      if (additionalWaveWidth > 0) {
        path.relativeMoveTo(-additionalWaveWidth, 0);
      }

      for (int i = 0; i < wavesCount; i++) {
        final isEven = i % 2 == 0;

        final isLastWave = i == wavesCount - 1;
        final isFullWave = !isLastWave;
        final distanceToWaveEnd = widthBeforeThumb - (i * waveWidth);

        // Рисуем саму волну.
        //
        // Волны могут либо подниматься, либо спускаться.
        // Для реализации анимации движения волны, мы изначально переместили путь на `additionalWaveWidth` влево.
        path.relativeQuadraticBezierTo(
          // x1: X для точки подъёма.
          waveWidth / 2,
          // y1: Y для точки подъёма.
          (isEven ? waveHeight : -waveHeight) * waveHeightPercent,

          // x2: X для точки, в которую идёт линия.
          isFullWave ? waveWidth : distanceToWaveEnd,
          // y2: Y для точки, в которую идёт линия. В нашем случа не меняется.
          0,
        );
      }
    } else {
      // Если высота волны равна нулю, то рисуем прямую линию.
      path.lineTo(
        thumbCenter.dx,
        offset.dy + halfHeight,
      );
    }

    // Мы отрисовали все пути, теперь рендерим их.
    // Рисуем волны, которые обрезаем слева, до ползунка.
    context.canvas.save();
    context.canvas.clipRect(
      Rect.fromPoints(
        trackRect.centerLeft + Offset(0, -halfHeight),
        thumbCenter + Offset(0, halfHeight),
      ),
    );
    context.canvas.drawPath(
      path,
      paint,
    );
    context.canvas.restore();

    // Рисуем нактивную часть пути, которая идёт после ползунка.
    context.canvas.drawPath(
      inactivePath,
      inactivePaint,
    );
  }
}

/// Расширение для класса [SliderComponentShape], которое рисует скруглённый ползунок для [Slider], чтобы напоминать вид Android 13+.
class MaterialYouThumbShape extends SliderComponentShape {
  /// Ширина ползунка.
  static const double width = 6;

  /// Высота ползунка.
  static const double height = 20;

  /// Радиус скругления ползунка.
  static const double radius = 3;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(height, height);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final paint = Paint()
      ..color = sliderTheme.thumbColor!
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      ),
      const Radius.circular(
        radius,
      ),
    );
    context.canvas.drawRRect(rrect, paint);
  }
}
