import "package:flutter/material.dart";

import "../utils.dart";

/// Виджет типа [Dialog] или [Dialog.fullscreen], который использует полноэкранный диалог на мобильной версии приложения ([Dialog.fullscreen]), и обычный [Dialog] для desktop.
///
/// Данный виджет используется вместе с [showDialog], пример:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const AdaptiveDialog(...)
/// );
class AdaptiveDialog extends StatelessWidget {
  /// Виджет, отображаемый внутри данного диалога.
  final Widget child;

  const AdaptiveDialog({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobileLayout(context)) {
      return Dialog.fullscreen(
        child: child,
      );
    }

    return Dialog(
      child: child,
    );
  }
}
