import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// TODO: DOC
class LoadingIconButton extends HookWidget {
  final Widget icon;
  final AsyncCallback? onPressed;
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
