import "package:animations/animations.dart";
import "package:flutter/material.dart";

/// Page Route, использующий анимацию из Material 3 для перехода между Route'ами.
///
/// Пример использования:
/// ```dart
/// Navigator.push(
///   context,
///   Material3PageRoute(
///     builder: (context) => MyRoute(),
///   ),
/// );
///```
@Deprecated("Use go_router.push() instead")
class Material3PageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  Material3PageRoute({
    required this.builder,
  }) : super(
          pageBuilder: (
            BuildContext context,
            Animation animation,
            Animation secondaryAnimation,
          ) {
            return builder(context);
          },
          transitionDuration: const Duration(
            milliseconds: 300,
          ),
          reverseTransitionDuration: const Duration(
            milliseconds: 300,
          ),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
        );
}
