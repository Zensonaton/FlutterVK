import "dart:async";

import "package:dio/dio.dart";

import "../../main.dart";
import "consts.dart";

/// Делает запрос к API ВКонтакте.
///
/// [method] - название метода, например, `users.get`.
/// [token] - access-токен.
/// [body] - содержимое запроса.
@Deprecated("Должно быть реализовано на стороне Dio")
Future<Response> callVkAPI(
  String method,
  String token,
  Map<String, dynamic> body,
) async {
  body["access_token"] = token;
  body["v"] = vkAPIversion;

  // TODO: Использовать HTTP Header `Authorization: bearer token` используя interceptor.

  return await vkDio.post(
    method,
    data: body,
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

/// Проверяет передаваемый API-ответ от ВКонтакте на наличие поля `error`. Если таковое поле находится, то данный метод вызовет исключение.
@Deprecated("Должно быть реализовано на стороне Dio")
void raiseOnAPIError(
  dynamic response,
) {
  if (response.error == null) return;

  throw VKAPIError(
    errorCode: response.error.errorCode,
    message: response.error.errorMessage,
  );
}
