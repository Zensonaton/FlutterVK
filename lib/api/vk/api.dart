import "dart:async";
import "dart:convert";
import "dart:io";

import "package:http/http.dart";
import "package:retry/retry.dart";

import "../../services/logger.dart";
import "consts.dart";

/// Делает API-POST запрос.
///
/// Если запрос не был отправлен по какой-то причине (скажем, пользователь с WiFi переключился на LTE и/ли наоборот), то запрос будет выслан несколько раз, перед тем как вызывать исключение.
Future<Response> apiPost(
  String url,
  Map<String, dynamic> body, {
  Map<String, String>? moreHeaders,
  List<int>? retryHttpCodes,
}) async {
  AppLogger logger = getLogger("API");

  final Map<String, String> headers = {
    "Content-Type": "application/x-www-form-urlencoded",
    "User-Agent": vkAPIKateMobileUA,
  };
  if (moreHeaders != null) headers.addAll(moreHeaders);

  // Избавляемся от null-полей.
  body.removeWhere(
    (String key, dynamic value) => value == null,
  );

  final response = await retry(
    () async {
      String bodyConcat = jsonEncode(body);
      if (bodyConcat.length > 500) {
        bodyConcat =
            "${bodyConcat.substring(0, 500)}... (${bodyConcat.length} chars)";
      }

      logger.d(
        "Begin POST to $url, body: $bodyConcat",
      );

      var req = await post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      if (retryHttpCodes != null && retryHttpCodes.contains(req.statusCode)) {
        throw SocketException("Bad HTTP code recieved: ${req.statusCode}");
      }

      return req;
    },
    retryIf: (e) => e is SocketException || e is TimeoutException,
    onRetry: (e) => logger.w(
      "Req error, retrying",
      error: e,
    ),
  );

  String bodyConcat = response.body;
  if (bodyConcat.length > 500) {
    bodyConcat =
        "${bodyConcat.substring(0, 500)}... (${bodyConcat.length} chars)";
  }

  logger.d("Req status code: ${response.statusCode}, body: $bodyConcat");

  return response;
}

/// Делает запрос к API ВКонтакте.
///
/// [method] - название метода, например, `users.get`.
/// [token] - access-токен.
/// [body] - содержимое запроса.
Future<Response> vkAPIcall(
  String method,
  String token,
  Map<String, dynamic> body, {
  Map<String, String>? moreHeaders,
  List<int>? retryHttpCodes,
}) async {
  body["access_token"] = token;
  body["v"] = vkAPIversion;

  return await apiPost(
    vkAPIBaseURL + method,
    body,
    moreHeaders: moreHeaders,
    retryHttpCodes: retryHttpCodes,
  );
}

/// Класс, расширяющий [Exception], олицетворяющий ошибку API ВКонтакте.
class VKAPIError implements Exception {
  /// Код ошибки.
  int? errorCode;

  /// Текст ошибки.
  String? message;

  @override
  String toString() => "VK API error $errorCode: $message";

  VKAPIError({
    this.errorCode,
    this.message,
  });
}

/// Проверяет передаваемый API-ответ от ВКонтакте на наличие поля `error`. Если таковое поле находится, то данный метод вызвает исключение.
void raiseOnAPIError(
  dynamic response,
) {
  if (response.error == null) return;

  throw VKAPIError(
    errorCode: response.error.errorCode,
    message: response.error.errorMessage,
  );
}
