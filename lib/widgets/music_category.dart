import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";

import "../utils.dart";

/// Виджет для [MusicCategory], отображающий анимированное число элементов в категории.

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

    final oldCount = useState(count ?? 0);
    final controller = useAnimationController(
      duration: const Duration(seconds: 1),
    );

    final animation = useMemoized(
      () {
        return IntTween(
          begin: oldCount.value,
          end: count ?? 0,
        ).animate(controller);
      },
      [count],
    );
    useEffect(
      () {
        if (count != null) {
          oldCount.value = count ?? 0;
          controller.reset();
          controller.forward();
        }

        return null;
      },
      [count],
    );

    final animatedCount = useAnimation(animation);

    return MouseRegion(
      onEnter: onDismiss != null ? (_) => showDismiss.value = true : null,
      onExit: onDismiss != null ? (_) => showDismiss.value = false : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название с количеством, а так же кнопка для закрытия.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Название, количество.
              RichText(
                text: TextSpan(
                  children: [
                    // Название.
                    TextSpan(
                      text: title,
                      style: titleStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        color: ColorScheme.of(context).primary,
                      ),
                    ),

                    // Количество, при наличии.
                    WidgetSpan(
                      baseline: TextBaseline.alphabetic,
                      alignment: PlaceholderAlignment.baseline,
                      child: AnimatedOpacity(
                        duration: const Duration(
                          milliseconds: 500,
                        ),
                        curve: Curves.easeInOutCubicEmphasized,
                        opacity: count != null ? 1.0 : 0.0,
                        child: Text(
                          "  $animatedCount",
                          style: titleStyle.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),

              // Кнопка для закрытия категории.
              if (onDismiss != null)
                Padding(
                  padding: EdgeInsets.only(
                    right: mobileLayout ? 0 : 8,
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    opacity: showDismiss.value ? 1.0 : 0.0,
                    child: IconButton.filled(
                      icon: Icon(
                        Icons.close,
                        color: ColorScheme.of(context).surface,
                      ),
                      onPressed: onDismiss,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
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
