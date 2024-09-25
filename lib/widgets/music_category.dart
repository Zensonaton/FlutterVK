import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";

import "../utils.dart";

/// Виджет, отображающий отдельную категорию для раздела "музыки". У категории есть название, иногда количество элементов в категории.
class MusicCategory extends HookWidget {
  /// Название категории.
  final String title;

  /// Количество элементов в категории. К примеру, здесь может быть указано количество треков в разделе "ваша музыка", либо количество плейлистов.
  ///
  /// Если не указывать, то считается, что количество элементов неизвестно, и оно не будет отображаться.
  final int? count;

  /// Callback-метод, вызываемый при нажатии на X в категории. Если не указано, то X не будет отображаться.
  final VoidCallback? onDismiss;

  /// Содержимое этой категории.
  final List<Widget> children;

  const MusicCategory({
    super.key,
    required this.title,
    this.count,
    this.onDismiss,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final bool mobileLayout = isMobileLayout(context);

    final TextStyle titleStyle = mobileLayout
        ? Theme.of(context).textTheme.headlineSmall!
        : Theme.of(context).textTheme.bodyMedium!;

    final showDismiss = useState(false);

    return MouseRegion(
      onEnter: onDismiss != null ? (_) => showDismiss.value = true : null,
      onExit: onDismiss != null ? (_) => showDismiss.value = false : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название категории, а так же количество элементов в нём.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Название категории.
              Text(
                title,
                style: titleStyle.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              if (mobileLayout) const Spacer() else const Gap(8),

              // Количество элементов в категории.
              // TODO: Анимация появления.
              if (count != null)
                Text(
                  count.toString(),
                  style: titleStyle.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.75),
                  ),
                ),

              // Кнопка для закрытия категории.
              // FIXME: Кнопка имеет неправильный размер.
              if (onDismiss != null) ...[
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                  opacity: showDismiss.value ? 1.0 : 0.0,
                  child: IconButton.filled(
                    icon: const Icon(
                      Icons.close,
                    ),
                    onPressed: onDismiss,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ],
          ),
          const Gap(14),

          // Содержимое категории.
          ...children,
        ],
      ),
    );
  }
}
