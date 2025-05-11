import "package:flutter/material.dart";
import "package:gap/gap.dart";

import "../consts.dart";

/// Виджет, который является Wrapper'ом для [Card], который отображает информацию в виде "подсказки".
///
/// У такой подсказки есть (опциональный) [icon] слева, (опциональный) [title], отображаемый сверху, а так же [description].
/// Опционально, можно указать [onTap], который будет вызван при нажатии на виджет.
class TipWidget extends StatelessWidget {
  /// Иконка, отображаемая слева.
  final IconData? icon;

  /// Заголовок, отображаемый сверху.
  final String? title;

  /// Описание, отображаемое ниже [title].
  ///
  /// Обязан быть, если не указан [descriptionWidget].
  final String? description;

  /// Виджет, отображаемый вместо [description].
  ///
  /// Обязан быть, если не указан [description].
  final Widget? descriptionWidget;

  /// Указывает, что иконка будет расположена сверху, а [title] будет тоже по центру.
  final bool iconOnTop;

  /// Список из виджетов-действий, отображаемых снизу.
  final List<Widget> actions;

  /// Обработчик нажатия на виджет.
  final void Function()? onTap;

  const TipWidget({
    super.key,
    this.icon = Icons.info,
    this.title,
    this.description,
    this.descriptionWidget,
    this.iconOnTop = false,
    this.actions = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    assert(
      description != null || descriptionWidget != null,
      "description or richDescription must be provided",
    );

    final color = ColorScheme.of(context).primary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            20,
          ),
          child: Row(
            children: [
              // Иконка слева.
              if (!iconOnTop && icon != null) ...[
                Icon(
                  icon,
                  color: color,
                ),
                const Gap(12),
              ],

              // Содержимое.
              Expanded(
                child: Column(
                  crossAxisAlignment: iconOnTop
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    // Иконка сверху.
                    if (iconOnTop && icon != null) ...[
                      Icon(
                        icon,
                        color: color,
                      ),
                      const Gap(4),
                    ],

                    // Заголовок.
                    if (title != null)
                      Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorScheme.of(context).primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const Gap(12),

                    // Описание.
                    descriptionWidget ?? Text(description!),

                    // Дополнительные действия.
                    if (actions.isNotEmpty) ...[
                      const Gap(20),
                      ...actions,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
