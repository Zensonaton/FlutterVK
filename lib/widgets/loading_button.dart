import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Виджет, отображающий [CircularProgressIndicator] во время выполнения Future, указанного в [AsyncCallback].
class LoadingIconButton extends HookWidget {
  /// Виджет, отображаемый как иконка, если загрузка не идёт.
  final Widget icon;

  /// Виджет, отображаемый как label.
  final Widget? label;

  /// Метод, вызываемый при нажатии на эту кнопку.
  ///
  /// Во время выполнения этого Future, [icon] будет заменён [CircularProgressIndicator].
  final AsyncCallback? onPressed;

  /// Размер для иконки.
  final double iconSize;

  /// Цвет для [CircularProgressIndicator].
  final Color? color;

  const LoadingIconButton({
    super.key,
    required this.icon,
    this.label,
    this.iconSize = 24,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);

    void wrapper() async {
      isLoading.value = true;

      try {
        await onPressed!.call();
      } catch (e) {
        rethrow;
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    final onPressedWrapper =
        onPressed != null && !isLoading.value ? wrapper : null;

    final widgetIcon = isLoading.value
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                color,
              ),
            ),
          )
        : icon;

    if (label != null) {
      return FilledButton.icon(
        onPressed: onPressedWrapper,
        icon: widgetIcon,
        label: label!,
      );
    }

    return IconButton(
      onPressed: onPressedWrapper,
      icon: widgetIcon,
      iconSize: iconSize,
    );
  }

  factory LoadingIconButton.icon({
    Key? key,
    required Widget icon,
    Widget? label,
    required AsyncCallback? onPressed,
    double iconSize = 24,
    Color? color,
  }) {
    return LoadingIconButton(
      icon: icon,
      label: label,
      onPressed: onPressed,
      iconSize: iconSize,
      color: color,
    );
  }
}
