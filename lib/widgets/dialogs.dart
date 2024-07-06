import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../main.dart";
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

  const MaterialDialog({
    super.key,
    this.icon,
    this.iconColor,
    this.title,
    this.text,
    this.contents,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      text != null || contents != null,
      "Expected text or contents to be specified",
    );

    final l18n = ref.watch(l18nProvider);

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
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor ?? Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

            // Title диалога.
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 24,
                ),
                child: Center(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

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
            if (actions == null || (actions ?? []).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  top: 24,
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Wrap(
                    spacing: 8,
                    children: actions ??
                        [
                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              l18n.general_close,
                            ),
                          ),
                        ],
                  ),
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

/// Показывает диалог, показывающий информацию о том, что данное действие невозможно выполнить, если нет доступа к интернету.
///
/// В качестве параметров принимает [context] - контекст.
void showInternetRequiredDialog(WidgetRef ref, BuildContext context) {
  final l18n = ref.watch(l18nProvider);

  showErrorDialog(
    context,
    title: l18n.internetConnectionRequiredTitle,
    description: l18n.internetConnectionRequiredDescription,
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
