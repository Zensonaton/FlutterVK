import "dart:ui";

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

/// Виджет, который обрабатывает события сколлинга мышью.
class ScrollableWidget extends StatelessWidget {
  /// Событие, вызываемое при изменении значения данного виджета, вызванного событием скроллинга мышью. Возвращает значение от `-1.0` до `0.0`.
  final Function(double) onChanged;

  /// Child-виджет, на котором и будут проверяться события скроллинга мышью.
  final Widget child;

  const ScrollableWidget({
    super.key,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        if (event is! PointerScrollEvent) {
          return;
        }

        // Flutter возвращает количество как числа, кратные 100. Нельзя так же забывать, что логика здесь немного инвертирована.
        final double scrollAmount = (-event.scrollDelta.dy) / 100;

        // Ограничиваем выходное значение в пределах от 0.0 до 1.0.
        final double newValue = clampDouble(scrollAmount, -1.0, 1.0);

        // Вызываем событие изменения.
        onChanged(newValue);
      },
      child: child,
    );
  }
}

/// Виджет, олицетворяющий [Slider] с обработкой событий скроллинга мышью.
///
/// Использует [ScrollableWidget] под капотом.
class ScrollableSlider extends StatelessWidget {
  /// Текущее значение.
  final double value;

  /// Событие, вызываемое при изменении значения данного [Slider]'а, как при помощи мыши так и при обычном передвижении ползунка.
  final Function(double) onChanged;

  /// Цвет для ползунка.
  final Color? thumbColor;

  /// Цвет для активной части дорожки.
  final Color? activeColor;

  /// Цвет для неактивной части дорожки.
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
    return ScrollableWidget(
      onChanged: (double diff) => onChanged(
        clampDouble(value + diff / 10, 0.0, 1.0),
      ),
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
