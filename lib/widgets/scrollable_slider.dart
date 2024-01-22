import "dart:ui";

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

/// Виджет, олицетворяющий [Slider] с обработкой событий скроллинга мышью.
class ScrollableSlider extends StatelessWidget {
  /// Текущее значение.
  final double value;

  /// Событие, вызываемое при изменении значения данного [Slider]'а, как при помощи мыши так и при обычном передвижении ползунка.
  final Function(double) onChanged;

  final Color? thumbColor;

  final Color? activeColor;

  final Color? inactiveColor;

  const ScrollableSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.thumbColor,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        if (event is! PointerScrollEvent) {
          return;
        }

        // Flutter возвращает количество как числа, кратные 100.
        //
        // Поскольку мы храним громкость как число от 0.0 до 1.0, мы должны разделить "шаг скроллинга" на 1000.
        // Так же, нельзя забывать, что логика здесь немного инвертирована.
        final double scrollAmount = (-event.scrollDelta.dy) / 1000;

        // Ограничиваем выходное значение в пределах от 0.0 до 1.0.
        final double newValue = clampDouble(
          value + scrollAmount,
          0.0,
          1.0,
        );

        // Вызываем событие изменения.
        onChanged(newValue);
      },
      child: SliderTheme(
        data: SliderThemeData(
          overlayShape: SliderComponentShape.noThumb,
        ),
        child: Slider(
          value: value,
          onChanged: onChanged,
          thumbColor: thumbColor,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
        ),
      ),
    );
  }
}
