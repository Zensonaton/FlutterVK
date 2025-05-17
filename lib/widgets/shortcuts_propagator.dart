import "package:flutter/material.dart";
import "package:flutter/services.dart";

/// Wrapper-виджет для [TextField], который поглощает глобальные горячие клавиши, чтобы не мешать процессу печати в [TextField].
///
/// Пример использования:
/// ```dart
/// ShortcutsPropagator(
///   child: TextField(),
/// )
/// ```
class ShortcutsPropagator extends StatelessWidget {
  /// Список из всех зарегистрированных глобальных горячих клавиш.
  static const List<LogicalKeyboardKey> absorbKeys = [
    LogicalKeyboardKey.keyF,
    LogicalKeyboardKey.f11,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyL,
    LogicalKeyboardKey.keyQ,
    LogicalKeyboardKey.escape,
  ];

  /// Виджет, который будет обернут в [ShortcutsPropagator]. Чаще всего, это [TextField].
  final Widget child;

  const ShortcutsPropagator({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        for (final key in absorbKeys)
          LogicalKeySet(key): const DoNothingAndStopPropagationTextIntent(),
      },
      child: child,
    );
  }
}
