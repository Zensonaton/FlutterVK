import "package:flutter/material.dart";

/// Класс-оверлей, показывающий индикатор загрузки на весь экран.
class LoadingOverlay extends StatelessWidget {
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(false);

  /// [Widget], располагаемый под этим [LoadingOverlay].
  final Widget child;

  /// Опциональная задержка, через которую будет отображён данный виджет.
  final Duration? delay;

  static LoadingOverlay of(BuildContext context) {
    return context.findAncestorWidgetOfExactType<LoadingOverlay>()!;
  }

  /// Показывает индикатор загрузки.
  void show() => _loadingNotifier.value = true;

  /// Прячет индикатор загрузки.
  void hide() => _loadingNotifier.value = false;

  /// Переключает видимость индикатора загрузки.
  void toggle() => _loadingNotifier.value = !_loadingNotifier.value;

  /// Устанавливает значение видимости виджета загрузки.
  void setEnabled(bool value) => _loadingNotifier.value = value;

  /// Передаёт значение, указывающее, показан ли виджет для загрузки или нет.
  bool get isLoading => _loadingNotifier.value;

  /// Выполняет операцию, передаваемую внутри [action] с показом ([show]) и последующим выключением ([hide]) [LoadingOverlay].
  ///
  /// Пример использования:
  /// ```dart
  /// await loadingOverlay.doWithLoadingOverlay(() async {
  ///   print('Starting operation');
  ///   await Future.delayed(Duration(seconds: 2));
  ///
  ///   print('Operation completed');
  /// });
  /// ```
  Future<dynamic> doWithLoadingOverlay(
    Future<dynamic> Function() action,
  ) async {
    try {
      show();

      return await action();
    } finally {
      hide();
    }
  }

  LoadingOverlay({
    super.key,
    required this.child,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _loadingNotifier,
      child: child,
      builder: (BuildContext context, bool enabled, Widget? child) {
        if (!enabled) return child!;

        return Stack(
          children: [
            child!,
            Container(
              color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
              child: Center(
                child: FutureBuilder(
                  future: Future.delayed(delay ?? Duration.zero),
                  builder: (BuildContext context, AsyncSnapshot snapshot) =>
                      snapshot.connectionState == ConnectionState.done
                          ? const CircularProgressIndicator.adaptive()
                          : const SizedBox(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
