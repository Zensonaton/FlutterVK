import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// Виджет, отображающий [CircularProgressIndicator] во время выполнения Future, указанного в [AsyncCallback].
class LoadingIconButton extends HookWidget {
  /// Виджет, отображаемый как иконка, если загрузка не идёт.
  final Widget icon;

  /// Метод, вызываемый при нажатии на эту кнопку.
  ///
  /// Во время выполнения этого Future, [icon] будет заменён [CircularProgressIndicator].
  final AsyncCallback? onPressed;

  /// Цвет для [CircularProgressIndicator].
  final Color? color;

  const LoadingIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);

    return IconButton(
      onPressed: onPressed != null && !isLoading.value
          ? () async {
              isLoading.value = true;

              try {
                await onPressed!.call();
              } catch (e) {
                rethrow;
              } finally {
                if (context.mounted) isLoading.value = false;
              }
            }
          : null,
      icon: isLoading.value
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator.adaptive(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(
                  color,
                ),
              ),
            )
          : icon,
    );
  }
}
