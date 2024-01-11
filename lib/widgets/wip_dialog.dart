import "package:flutter/material.dart";

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
    builder: (BuildContext context) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.web_asset_off_outlined,
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                title ?? "Не реализовано",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 24,
              ),
              Text(
                description ??
                    "Данный функционал ещё не был реализован. Пожалуйста, ожидайте обновлений приложения в будущем!",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(
                height: 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
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
