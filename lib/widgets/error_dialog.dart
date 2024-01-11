import "package:flutter/material.dart";

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
    builder: (BuildContext context) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline),
              const SizedBox(
                height: 16,
              ),
              Text(
                title ?? "Произошла ошибка",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 24,
              ),
              Text(
                description ?? "Произошла неизвестная ошибка.",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(
                height: 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Закрыть",
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      );
    },
  );
}
