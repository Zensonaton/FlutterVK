import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

import "../services/logger.dart";

/// Класс для простого создания виджетов типа [Dialog], которые соответствуют дизайну Material 3 диалогам.
class MaterialDialog extends StatelessWidget {
  /// [IconData], используемый как содержимое иконки, располагаемая в самой верхушке диалога.
  final IconData? icon;

  /// Цвет иконки.
  final Color? iconColor;

  /// Текст, отображаемый после [icon], располагаемый по центру диалога.
  final String? title;

  /// Содержимое данного диалога.
  final String text;

  /// Массив из кнопок (чаще всего используется [IconButton]), располагаемый в правом нижнем углу.
  ///
  /// Если указать null, то будет использоваться кнопка "Закрыть".
  final List<Widget>? actions;

  const MaterialDialog({
    super.key,
    this.icon,
    this.iconColor,
    this.title,
    required this.text,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка.
            if (icon != null)
              Center(
                child: Icon(
                  icon,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            if (icon != null)
              const SizedBox(
                height: 12,
              ),

            // Title диалога.
            if (title != null)
              Center(
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            if (title != null)
              const SizedBox(
                height: 24,
              ),

            // Содержимое диалога.
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),

            // Действия диалога.
            if (actions == null || (actions ?? []).isNotEmpty)
              const SizedBox(
                height: 24,
              ),
            if (actions == null || (actions ?? []).isNotEmpty)
              Align(
                alignment: Alignment.bottomRight,
                child: Wrap(
                  spacing: 8,
                  children: actions ??
                      [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            AppLocalizations.of(context)!.general_close,
                          ),
                        )
                      ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
class WIPDialog extends StatelessWidget {
  final String? title;

  final String? description;

  const WIPDialog({
    super.key,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialDialog(
      icon: Icons.web_asset_off_outlined,
      title: title ?? "Не реализовано",
      text: description ??
          "Данный функционал ещё не был реализован. Пожалуйста, ожидайте обновлений приложения в будущем!",
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
class ErrorDialog extends StatelessWidget {
  final String? title;

  final String? description;

  const ErrorDialog({
    super.key,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialDialog(
      icon: Icons.error_outline,
      title: title ?? "Произошла ошибка",
      text: description ??
          "Что-то очень сильно пошло не так. Что-то поломалось. Всё очень плохо.",
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
      "Был вызван метод showLogErrorDialog, однако context.mounted == false. Это значит, что был произведён вызов Navigator.of(...).pop() раньше времени.",
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
