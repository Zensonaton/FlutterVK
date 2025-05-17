import "package:flutter/material.dart";

/// Модицифированная версия [FadeForwardsPageTransitionsBuilder], которая использует более корректную длительность анимации перехода между страницами.
///
/// Значения взяты из [документации M3 компонентов](https://github.com/material-components/material-components-android/blob/master/docs/theming/Motion.md#shared-axis).
class SharedAxisHorizontalPageTransitionsBuilder
    extends FadeForwardsPageTransitionsBuilder {
  const SharedAxisHorizontalPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);
}
