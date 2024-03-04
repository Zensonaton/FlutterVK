import "dart:async";
import "dart:io";

import "package:connectivity_plus/connectivity_plus.dart";

/// Класс-менеджер, определяющий состояние подключения данного устройства к интернету.
class ConnectivityManager {
  final Connectivity _connectivity = Connectivity();

  final StreamController<bool> _connectionController =
      StreamController.broadcast();

  bool? _hasConnection = false;

  /// Указывает, есть ли интернет соединение.
  bool get hasConnection => _hasConnection ?? false;

  /// Производит инициализацию данного класса.
  ///
  /// Данный метод должен быть вызван лишь одинажды.
  Future<void> initialize() async {
    _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) => Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
        checkConnection,
      ),
    );

    await checkConnection();
  }

  /// [Stream], отображающий состояние подключеник к интернету.
  Stream<bool> get connectionChange => _connectionController.stream;

  /// Делает запрос, узнавая, есть ли доступ к интернет соединению.
  Future<bool> checkConnection() async {
    bool? previousConnection = _hasConnection;

    try {
      final result = await InternetAddress.lookup("vk.com");

      _hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _hasConnection = false;
    }

    // Если предыдущее значение доступа к интернету отличается от текущего, значит нам нужно оповестить об изменениях.
    if (previousConnection != _hasConnection) {
      _connectionController.add(_hasConnection!);
    }

    return _hasConnection!;
  }
}
