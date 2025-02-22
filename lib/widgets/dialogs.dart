import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../main.dart";
import "../provider/auth.dart";
import "../provider/l18n.dart";
import "../services/logger.dart";

/// Класс для простого создания виджетов типа [Dialog], которые соответствуют дизайну Material 3 диалогам.
class MaterialDialog extends ConsumerWidget {
  /// [IconData], используемый как содержимое иконки, располагаемая в самой верхушке диалога.
  final IconData? icon;

  /// Цвет иконки.
  final Color? iconColor;

  /// Текст, отображаемый после [icon], располагаемый по центру диалога.
  final String? title;

  /// Текстовое содержимое данного диалога.
  ///
  /// Данное поле либо [contents] не должно быть null.
  final String? text;

  /// [List] из [Widget], который расположен по центру данного диалога.
  ///
  /// Данное поле либо [text] не должно быть null.
  final List<Widget>? contents;

  /// Массив из кнопок (чаще всего используется [IconButton]), располагаемый в правом нижнем углу.
  ///
  /// Если указать null, то будет использоваться кнопка "Закрыть".
  final List<Widget>? actions;

  /// Общий Padding для всего диалога.
  final EdgeInsets padding;

  const MaterialDialog({
    super.key,
    this.icon,
    this.iconColor,
    this.title,
    this.text,
    this.contents,
    this.actions,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (text == null && contents == null) {
      throw ArgumentError("Expected text or contents to be specified");
    }

    final l18n = ref.watch(l18nProvider);

    return Dialog(
      child: Container(
        padding: padding,
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка.
            if (icon != null) ...[
              Center(
                child: Icon(
                  icon,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
              const Gap(12),
            ],

            // Title диалога.
            if (title != null) ...[
              Center(
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const Gap(24),
            ],

            // Текстовое содержимое диалога.
            if (text != null)
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    text!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),

            // Разделитель, если есть одновременно и содержимое и текста.
            if (text != null && contents != null) const Gap(8),

            // Обычное содержимое диалога.
            if (contents != null)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: contents!,
                ),
              ),

            // Действия диалога.
            if (actions == null || (actions ?? []).isNotEmpty) ...[
              const Gap(24),
              Align(
                alignment: Alignment.bottomRight,
                child: Wrap(
                  spacing: 8,
                  children: actions ??
                      [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            l18n.general_close,
                          ),
                        ),
                      ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Диалог типа [MaterialDialog], отображающий кастомное содержимое, с кнопками "Да" и "Нет".
class YesNoMaterialDialog extends ConsumerWidget {
  /// [IconData], используемый как содержимое иконки, располагаемая в самой верхушке диалога.
  final IconData? icon;

  /// Текст, отображаемый после [icon], располагаемый по центру диалога.
  final String title;

  /// Текстовое содержимое данного диалога.
  ///
  /// Данное поле либо [contents] не должно быть null.
  final String description;

  /// Текст у кнопки "Да".
  final String? yesText;

  /// Текст у кнопки "Нет".
  final String? noText;

  const YesNoMaterialDialog({
    super.key,
    this.icon,
    required this.title,
    required this.description,
    this.yesText,
    this.noText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: icon ?? Icons.help_outline,
      title: title,
      text: description,
      actions: [
        // Нет.
        TextButton(
          child: Text(
            noText ?? l18n.general_no,
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),

        // Да.
        FilledButton(
          child: Text(
            yesText ?? l18n.general_yes,
          ),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Показывает модальньный диалог, спрашивающий у пользователя о каком-то действии, показывая кнопки "Да" и "Нет".
///
/// В качестве параметров принимает [context] - контекст, в котором нужно показать диалог, [icon] - опциональная иконка, [title] - заголовок диалога, [description] - описание диалога.
Future<bool?> showYesNoDialog(
  BuildContext context, {
  IconData? icon,
  required String title,
  required String description,
  String? yesText,
  String? noText,
}) =>
    showDialog(
      context: context,
      builder: (BuildContext context) => YesNoMaterialDialog(
        icon: icon,
        title: title,
        description: description,
        yesText: yesText,
        noText: noText,
      ),
    );

/// Диалог типа [MaterialDialog], отображаемый в случае, если какой-то контент ещё не разработан/находится в разработке.
///
/// Удобства ради, вместо вызова данного класса можно воспользоваться удобной функцией [showWipDialog]:
/// ```dart
/// showWipDialog(
///   context,
///   title: "Название функционала",
///   description: "Необязательное описание данного функционала.",
/// );
/// ```
class WIPDialog extends ConsumerWidget {
  /// Опциональный заголовок данного диалога.
  final String? title;

  /// Опциональное описание данного диалога.
  final String? description;

  const WIPDialog({
    super.key,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.web_asset_off_outlined,
      title: title ?? l18n.not_yet_implemented,
      text: description ?? l18n.not_yet_implemented_desc,
    );
  }
}

/// Показывает модальньный диалог, показывающий, что часть функционала ещё не реализована.
///
/// В качестве параметров принимает [context] - контекст, в котором нужно показать диалог, [title] - заголовок диалога, [description] - описание диалога.
void showWipDialog(
  BuildContext context, {
  String? title,
  String? description,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) => WIPDialog(
      title: title,
      description: description,
    ),
  );
}

/// Диалог типа [MaterialDialog], отображаемый в случае, если произошла какая-то ошибка.
///
/// Удобства ради, вместо вызова данного класса можно воспользоваться удобной функцией [showErrorDialog]:
/// ```dart
/// showErrorDialog(
///   context,
///   title: "Необязательный титульник ошибки",
///   description: "Текст ошибки.",
/// );
/// ```
class ErrorDialog extends ConsumerWidget {
  /// Текст титульника данного диалога.
  final String? title;

  /// Текст ошибки.
  final String? description;

  const ErrorDialog({
    super.key,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.error_outline,
      title: title ?? l18n.error_dialog,
      text: description ?? l18n.error_dialog_desc,
    );
  }
}

/// Показывает диалог, показывающий о случившейся ошибке.
///
/// В качестве параметров принимает [context] - контекст, в котором нужно показать диалог, [title] - заголовок диалога, [description] - описание диалога.
void showErrorDialog(
  BuildContext context, {
  String? title,
  String? description,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) => ErrorDialog(
      title: title,
      description: description,
    ),
  );
}

/// Показывает диалог, показывающий информацию о том, что данное действие невозможно выполнить, если нет доступа к интернету.
///
/// В качестве параметров принимает [context] - контекст.
void showInternetRequiredDialog(WidgetRef ref, BuildContext context) {
  final l18n = ref.watch(l18nProvider);

  showErrorDialog(
    context,
    title: l18n.internet_required_title,
    description: l18n.internet_required_desc,
  );
}

/// В случае, если нет доступа к интернету ([ConnectivityManager.hasConnection]), возвращает false, а так же вызывает [showInternetRequiredDialog], показывая сообщение об ошибке.
///
/// Пример использования данного метода:
/// ```dart
/// if (!networkRequiredDialog(context)) return;
///
/// var response = await get("google.com");
/// ```
bool networkRequiredDialog(WidgetRef ref, BuildContext context) {
  if (connectivityManager.hasConnection) {
    return true;
  }

  showInternetRequiredDialog(ref, context);

  return false;
}

/// Показывает диалог, показывающий информацию о том, что действие невозможно выполнить, поскольку приложение запущено в демо-режиме.
///
/// В качестве параметров принимает [context] - контекст.
void showDemoModeDialog(WidgetRef ref, BuildContext context) {
  final l18n = ref.watch(l18nProvider);

  showErrorDialog(
    context,
    title: l18n.demo_mode_enabled_title,
    description: l18n.demo_mode_enabled_desc,
  );
}

/// В случае, если запущена демо-версия приложения, возвращает false, а так же вызывает [showDemoModeDialog], показывая сообщение об ошибке.
bool demoModeDialog(WidgetRef ref, BuildContext context) {
  if (!ref.read(isDemoProvider)) {
    return true;
  }

  showDemoModeDialog(ref, context);

  return false;
}

/// Логирует информацию о произошедшей ошибке, а так же показывает диалоговое окно, говорящее пользователю о произошедшей ошибке.
///
/// [logText] - текст, появляющийся в логах.
/// [error] - объект ошибки.
/// [stackTrace] - стек, пришедший к ошибке.
/// [logger] - объект типа [AppLogger].
/// [context] - [BuildContext], в котором будет показан данный диалог. Если не указать, то диалоговое окно не будет показано.
/// [title] - текст титульника для диалога с ошибкой.
void showLogErrorDialog(
  String logText,
  Object error,
  StackTrace stackTrace,
  AppLogger logger,
  BuildContext? context, {
  String? title,
}) {
  logger.e(
    logText,
    error: error,
    stackTrace: stackTrace,
  );

  if (context == null) return;

  if (!context.mounted) {
    logger.w(
      "showLogErrorDialog() was called while context.mounted is false",
    );

    return;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) => ErrorDialog(
      title: title,
      description: error.toString(),
    ),
  );
}
