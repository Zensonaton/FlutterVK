import "package:hooks_riverpod/hooks_riverpod.dart";

import "../services/logger.dart";

/// Класс, расширяющий [ProviderObserver], логирующий ошибки различных Provider'ов.
class FlutterVKProviderObserver extends ProviderObserver {
  static final AppLogger logger = getLogger("FlutterVKProviderObserver");

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) =>
      logger.d(
        "Provider $provider threw an exception:",
        error: error,
        stackTrace: stackTrace,
      );
}
