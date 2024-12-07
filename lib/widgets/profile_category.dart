import "package:flutter/material.dart";
import "package:gap/gap.dart";

import "../consts.dart";

/// Виджет, отображающий отдельную категорию настроек в профиле.
class ProfileSettingCategory extends StatelessWidget {
  /// Иконка категории.
  final IconData icon;

  /// Название категории.
  final String title;

  /// Указывает, что [title] и [icon] будут располагаться по центру и вне виджета [Card]. Используется при Mobile Layout'е.
  final bool centerTitle;

  /// [Padding] для [children] внутри виджета [Card].
  final EdgeInsetsGeometry padding;

  /// Содержимое этой категории.
  final List<Widget> children;

  const ProfileSettingCategory({
    super.key,
    required this.icon,
    required this.title,
    this.centerTitle = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 14,
    ),
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final Widget titleWidget = Row(
      mainAxisSize: centerTitle ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // Разделитель.
        if (centerTitle)
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Divider(),
            ),
          ),

        // Иконка.
        if (!centerTitle) const Gap(16),
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const Gap(12),

        // Название категории.
        SelectionContainer.disabled(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Разделитель.
        if (centerTitle)
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Divider(),
            ),
          ),
      ],
    );

    return Column(
      children: [
        // Иконка и название вне Card.
        if (centerTitle) ...[
          titleWidget,
          const Gap(20),
        ],

        // Внутреннее содержимое.
        ClipRRect(
          borderRadius: BorderRadius.circular(
            globalBorderRadius,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                globalBorderRadius,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка и название, располагаемые внутри Card.
                if (!centerTitle) ...[
                  const Gap(14),
                  titleWidget,
                ],

                // Содержимое.
                Padding(
                  padding: padding,
                  child: Column(
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
