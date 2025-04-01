import "dart:io";

/// Игнорирует плохие SSL-сертификаты для всех запросов.
class HTTPOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    client.badCertificateCallback = badCertificateCallback;
    return client;
  }

  /// Callback-метод для [HttpClient.badCertificateCallback], который игнорирует ошибки SSL-сертификатов.
  static bool badCertificateCallback(cert, host, port) {
    return true;
  }
}
