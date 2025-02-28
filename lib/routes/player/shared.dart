import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

/// Виджет, отображаемый для блоков "воспроизведение плейлиста" и "источник текста песни", который отображает нужную иконку, а при наведении заменяет её крестиком.
class CategoryIconWidget extends HookConsumerWidget {
  /// Длительность анимации смены иконки.
  static const Duration animationDuration = Duration(milliseconds: 200);

  /// Иконка.
  final IconData icon;

  const CategoryIconWidget({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);

    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: AnimatedSwitcher(
        duration: animationDuration,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: Icon(
          key: ValueKey(
            isHovered.value,
          ),
          isHovered.value ? Icons.close : icon,
          color: isHovered.value ? scheme.error : scheme.onPrimaryContainer,
          size: 50,
        ),
      ),
    );
  }
}

/// Виджет, отображающий текст, находящийся сверху блоков.
class CategoryTextWidget extends StatelessWidget {
  /// Иконка, отображаемая слева либо справа, в зависимости от [isLeft].
  final IconData icon;

  /// Верхний текст.
  final String header;

  /// Текст ниже.
  final String text;

  /// Указывает, что данный блок расположен слева.
  final bool isLeft;

  const CategoryTextWidget({
    super.key,
    required this.icon,
    required this.header,
    required this.text,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final categoryIcon = CategoryIconWidget(icon: icon);
    final align = isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final textAlign = isLeft ? TextAlign.start : TextAlign.end;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        if (isLeft) categoryIcon,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: align,
          children: [
            Text(
              header,
              textAlign: textAlign,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              text,
              textAlign: textAlign,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        if (!isLeft) categoryIcon,
      ],
    );
  }
}
