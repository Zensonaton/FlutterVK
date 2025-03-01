import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../consts.dart";

/// Отображает отдельную строчку в тексте песни.
class LyricWidget extends StatelessWidget {
  /// Длительность перехода между строчками.
  static const Duration transitionDuration = Duration(milliseconds: 250);

  /// Curve для перехода между строчками.
  static const Curve transitionCurve = Curves.ease;

  /// Возвращает значение прозрачности (alpha) для строчки с указанным расстоянием.
  static double getDistanceAlpha(int distance) {
    const maxDistance = 5;
    const minAlpha = 0.1;
    const maxAlpha = 1.0;

    final normalizedDistance = (distance.abs() / maxDistance).clamp(0.0, 1.0);
    return maxAlpha - (normalizedDistance * (maxAlpha - minAlpha));
  }

  /// Текст строчки.
  ///
  /// Если не указан, то будет использоваться иконка ноты.
  final String? line;

  /// Указывает, что эта строчка воспроизводится в данный момент.
  ///
  /// У такой строчки текст будет увеличен.
  final bool isActive;

  /// Расстояние от активной строчки (т.е., той, которая воспроизводится в данный момент) от этой строчки.
  ///
  /// Если число отрицательное, то считается, что это старая строчка, если положительное - то строчка ещё не была воспроизведена.
  final int distance;

  /// Действие, вызываемое при нажатии на эту строчку.
  ///
  /// Если не указано, то нажатие будет проигнорировано, а так же текст не будет располагаться по центру.
  final void Function()? onTap;

  const LyricWidget({
    super.key,
    this.line,
    this.isActive = false,
    this.distance = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final isSynchronized = onTap != null;
    final isInterlide = line == null;
    final alignment = isSynchronized ? Alignment.center : Alignment.centerLeft;
    final textAlign = isSynchronized ? TextAlign.center : TextAlign.start;
    final fontWeight = isSynchronized ? FontWeight.w500 : FontWeight.w400;
    final color = scheme.primary.withValues(
      alpha: getDistanceAlpha(distance),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 50,
          ),
          child: AnimatedScale(
            duration: transitionDuration,
            curve: transitionCurve,
            scale: isActive ? 1.2 : 1,
            child: isInterlide
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                    ),
                    child: Align(
                      alignment: alignment,
                      child: Icon(
                        Icons.music_note,
                        size: 20,
                        color: color,
                      ),
                    ),
                  )
                : Text(
                    line!,
                    textAlign: textAlign,
                    style: TextStyle(
                      fontSize: 20,
                      color: color,
                      fontWeight: fontWeight,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

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
