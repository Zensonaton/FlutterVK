import "dart:async";

import "package:http/http.dart";

import "../api.dart";
import "consts.dart";

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
