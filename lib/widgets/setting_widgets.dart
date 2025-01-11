import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";

import "../main.dart";
import "../provider/player_events.dart";
import "../services/logger.dart";
import "../utils.dart";
import "audio_player.dart";

/// Виджет, отображающий Rive-анимацию по передаваемому [name].
///
/// Если у анимации есть [StateMachineController], то он будет использоваться для управления анимацией, и для этого будет необходимым передача аргумента [artboardName].
///
/// Анимация в формате `.riv` должна находиться по пути `assets/animation/[name].riv`.
class RiveAnimationBlock extends HookWidget {
  static final AppLogger logger = getLogger("RiveAnimationBlock");

  /// Название Rive-анимации, которая будет расположена по пути `assets/animation/[name].riv`.
  final String name;

  /// Название артборда, который будет использоваться для управления анимацией (см. метод [StateMachineController.fromArtboard]).
  ///
  /// Если не указан, то State-машина не будет использоваться.
  final String? artboardName;

  /// Метод, возвращающий объект [StateMachineController], если он был найден, и [artboardName] был валиден.
  final Function(StateMachineController)? onStateMachineController;

  const RiveAnimationBlock({
    super.key,
    required this.name,
    this.artboardName,
    this.onStateMachineController,
  });

  /// Возвращает название пути к файлу Rive-анимации в asset'ах приложения, используя переданное название анимации.
  static String getAssetPath(String name) => "assets/animations/$name.riv";

  @override
  Widget build(BuildContext context) {
    void onRiveInit(Artboard artboard) {
      logger.d("Rive animation \"$name\" initialized");

      if (artboardName == null) return;

      final StateMachineController? controller =
          artboard.stateMachineByName(artboardName!);
      if (controller == null) {
        throw Exception(
          "State machine with name $artboardName not found in $name.riv",
        );
      }

      artboard.addController(controller);

      if (onStateMachineController != null) {
        onStateMachineController!(controller);
      }
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            32,
          ),
          child: Container(
            width: 400,
            height: 300,
            color: Colors.black,
            child: RiveAnimation.asset(
              getAssetPath(name),
              onInit: onRiveInit,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      ),
    );
  }
}

/// Виджет, отображающий своеобразную карточку настроек, внутри которой может быть размещено любое содержимое, например, [SwitchListTile].
class SettingsCardWidget extends StatelessWidget {
  /// Радиус скругления углов карточки.
  static const double borderRadius = 28;

  /// Виджет, отображаемый внутри карточки.
  final Widget child;

  /// Указывает, что в [child] будет использоваться [SwitchListTile], и его стиль будет изменён.
  final bool isSwitchListTile;

  const SettingsCardWidget({
    super.key,
    required this.child,
    this.isSwitchListTile = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(
        listTileTheme: ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isSwitchListTile ? 16 : 10,
          ).copyWith(
            right: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius,
            ),
          ),
          titleTextStyle: TextStyle(
            fontSize: 20,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: scheme.primaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            borderRadius,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Виджет, отображающий отдельную кнопку для виджета по типу [SettingsCardWidget], внутри которой есть иконка, и название кнопки.
///
/// Используется, к примеру, для выбора темы приложения.
class SettingCardSelectorWidget extends StatelessWidget {
  /// Иконка, отображаемая сверху [title].
  final IconData icon;

  /// Название кнопки, отображаемое ниже [icon].
  final String title;

  /// Указывает, выбрана ли эта кнопка.
  final bool isSelected;

  /// Обработчик нажатия на кнопку.
  final VoidCallback? onTap;

  const SettingCardSelectorWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final backgroundColor = isSelected ? scheme.primary : scheme.inversePrimary;
    final color = scheme.onPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        12,
      ),
      child: Card(
        color: backgroundColor,
        margin: EdgeInsets.zero,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(
            12,
          ),
          child: Column(
            children: [
              // Иконка.
              Icon(
                icon,
                color: color,
              ),
              const Gap(12),

              // Название кнопки.
              Text(
                title,
                style: TextStyle(
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Расширение для виджета [SettingCardSelectorWidget], добавляющий поля, если виджет используется как [RadioListTile].
class GroupSettingCardSelectorWidget<T> extends StatelessWidget {
  /// Иконка, отображаемая сверху [title].
  final IconData icon;

  /// Название кнопки, отображаемое ниже [icon].
  final String title;

  /// Значение у этой кнопки.
  final T value;

  /// Групповое значение, с которым будет сравниваться [value].
  final T groupValue;

  /// Обработчик нажатия на эту кнопку.
  final Function(T)? onChanged;

  const GroupSettingCardSelectorWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.groupValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingCardSelectorWidget(
      icon: icon,
      title: title,
      isSelected: value == groupValue,
      onTap: () => onChanged?.call(value),
    );
  }
}

/// Виджет, отображающий страницу настрек в "профиле" с анимацией сверху (см. [RiveAnimationBlock]).
class SettingPageWithAnimationWidget extends ConsumerWidget {
  /// Название для этой страницы.
  final String title;

  /// Опциональный виджет, располагаемый после [title], и отображающий изображение или анимацию сверху.
  ///
  /// Чаще всего, используется [RiveAnimationBlock] или им подобные.
  final Widget? headerImage;

  /// Виджеты, отображаемые по середине.
  final List<Widget>? children;

  /// Текстовое предупреждение, о, например, причине, по которой эта опция недоступна. Отображается под [children].
  final String? warning;

  /// Текстовое описание, располагаемое снизу.
  ///
  /// Между [children] и [description] будет отображена иконка.
  final String? description;

  /// Указывает, будет ли учитываться мобильный плеер снизу при Mobile Layout.
  final bool addPaddingOnMobilePlayer;

  const SettingPageWithAnimationWidget({
    super.key,
    required this.title,
    this.headerImage,
    this.children,
    this.warning,
    this.description,
    this.addPaddingOnMobilePlayer = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (addPaddingOnMobilePlayer) {
      ref.watch(playerLoadedStateProvider);
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final textColor = scheme.onSurface.withValues(
      alpha: 0.9,
    );
    final errorTextColor = scheme.error.withValues(
      alpha: 0.9,
    );

    final mobileLayout = isMobileLayout(context);

    return CustomScrollView(
      slivers: [
        // AppBar.
        SliverAppBar.large(
          title: Text(
            title,
          ),
          expandedHeight: 184,
        ),

        // Внутреннее содержимое.
        SliverPadding(
          padding: EdgeInsets.all(
            mobileLayout ? 16 : 24,
          ).copyWith(
            top: 0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                // Изображение.
                if (headerImage != null) ...[
                  headerImage!,
                  const Gap(16),
                ],

                // Содержимое страницы.
                if (children != null) ...[
                  ...children!,
                  const Gap(32),
                ],

                // Предупреждение.
                if (warning != null) ...[
                  // Иконка предупреждения.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: errorTextColor,
                    ),
                  ),
                  const Gap(20),

                  // Текст предупреждения.
                  Text(
                    warning!,
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 0.05,
                      fontWeight: FontWeight.w500,
                      color: errorTextColor,
                    ),
                  ),
                  const Gap(32),
                ],

                // Описание.
                if (description != null) ...[
                  // Иконка описания.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.info_outline,
                      color: textColor,
                    ),
                  ),
                  const Gap(20),

                  // Описание.
                  Text(
                    description!,
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 0.05,
                      color: textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Дополнительный отступ для мобильного плеера.
        if (addPaddingOnMobilePlayer && player.loaded)
          const SliverGap(
            MusicPlayerWidget.mobileHeightWithPadding - 12,
          ),
      ],
    );
  }
}
