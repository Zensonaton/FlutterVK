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

/// Page Route, который делает эффект sliding'а нового Route снизу экрана.
///
/// Пример использования:
/// ```dart
/// Navigator.push(
///   context,
///   SlideFromBottomPageRoute(
///     builder: (context) => MyRoute(),
///   ),
/// );
///```
class SlideFromBottomPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  SlideFromBottomPageRoute({
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
            const begin = Offset(
              0.0,
              1.0,
            );
            const end = Offset.zero;

            var slideTween = Tween(
              begin: begin,
              end: end,
            ).chain(
              CurveTween(
                curve: Curves.ease,
              ),
            );
            var fadeTween = Tween(
              begin: 0.0,
              end: 1.0,
            );

            var offsetAnimation = animation.drive(slideTween);
            var fadeAnimation = animation.drive(fadeTween);

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
        );
}
