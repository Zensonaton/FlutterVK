import "package:flutter/material.dart";

/// Виджет-заглушка для аватара пользователя.
class UserAvatarPlaceholder extends StatelessWidget {
  /// Размер виджета. Используется как ширина и высота.
  final double size;

  const UserAvatarPlaceholder({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      width: size,
      height: size,
      child: Center(
        child: Icon(
          Icons.person,
          size: 36,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
