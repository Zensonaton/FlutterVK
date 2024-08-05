import "dart:convert";
import "dart:io";

import "package:awesome_dio_interceptor/awesome_dio_interceptor.dart";
import "package:dio/dio.dart";
import "package:dio_http2_adapter/dio_http2_adapter.dart";
import "package:dio_smart_retry/dio_smart_retry.dart";
import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../api/vk/consts.dart";
import "../api/vk/shared.dart";
import "../services/logger.dart";
import "auth.dart";

part "dio.g.dart";

/// Request Encoder для [Dio], реализовывающий поддержку GZip.
List<int> gzipEncoder(
  String request,
  RequestOptions options,
) {
  return gzip.encode(utf8.encode(request));
}

/// Response Decoder для [Dio], реализовывающий поддержку GZip.
String gzipDecoder(
  List<int> responseBytes,
  RequestOptions options,
  ResponseBody responseBody,
) {
  return utf8.decode(gzip.decode(responseBytes));
}

/// Возвращает объект [Dio] с зарегистрированными [Interceptor]'ами.
void initDioInterceptors(
  Ref ref,
  Dio dio, {
  String loggerName = "Dio",
  bool isVK = false,
}) {
  final AppLogger logger = getLogger(loggerName);

  // Игнорируем плохие SSL-сертификаты.
  dio.httpClientAdapter = Http2Adapter(
    ConnectionManager(
      onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
    ),
  );

  dio.interceptors.addAll([
    // Обработчик для добавления версии API и access_token для VK API.
    if (isVK)
      VKAPIInterceptor(
        ref: ref,
      ),

    // Обработчик для повтора HTTP-запросов в случае ошибок сети.
    RetryInterceptor(
      dio: dio,
      logPrint: (String log) => logger.d(log),
      retryEvaluator: (DioException error, int attempt) {
        return error is! VKAPIException;
      },
      retryDelays: const [
        Duration(
          seconds: 1,
        ),
      ],
    ),

    // Обработчик для логирования HTTP-запросов и их ответов в debug-режиме.
    if (kDebugMode)
      AwesomeDioInterceptor(
        logRequestTimeout: false,
        logRequestHeaders: false,
        logResponseHeaders: false,
        logger: (String log) {
          String newLog = log;

          // Если слишком длинное, то обрезаем.
          if (newLog.length > 300) {
            newLog = "${newLog.substring(0, 300)}...";
          }

          logger.d(newLog);
        },
      ),
  ]);
}

/// [Interceptor] для [Dio], добавляющий версию API и access_token для VK API, а так же возвращающий объект `response` из ответа, если он правильный.
class VKAPIInterceptor extends Interceptor {
  final Ref _ref;

  VKAPIInterceptor({
    required Ref ref,
  }) : _ref = ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final body = options.data as Map<String, dynamic>;
    final headers = options.headers;

    // Удаляем null-поля.
    body.removeWhere((key, value) => value == null);

    // Если у нас нет установленного access_token'а, то ставим его.
    // TODO: Если access_token находится в body, то переносим его в HTTP Header.
    if (!body.containsKey("access_token")) {
      final useSecondary = options.extra["useSecondary"] as bool? ?? false;

      final token =
          _ref.read(useSecondary ? secondaryTokenProvider : tokenProvider);
      assert(
        token != null,
        "Access token is null (secondary: $useSecondary)",
      );

      headers["Authorization"] = "Bearer $token";
    }

    // Устанавливаем ключ с версией API ВКонтакте.
    options.queryParameters["v"] = vkAPIVersion;

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data as Map<String, dynamic>;

    // Проверяем на наличие ошибок.
    if (data["error"] != null) {
      throw VKAPIException(
        errorCode: data["error"]["error_code"],
        message: data["error"]["error_msg"],
        requestOptions: response.requestOptions,
      );
    }

    // Проверка на наличие ошибок при использовании API execute.
    if (data["execute_errors"] != null) {
      // При использовании API execute может быть возвращено несколько ошибок в поле execute_errors.
      // Здесь мы учитываем лишь первую.
      final error = data["execute_errors"].first;

      throw VKAPIException(
        errorCode: error["error_code"],
        message: error["error_msg"],
        requestOptions: response.requestOptions,
      );
    }

    // Возвращаем объект `response` из ответа.
    if (data["response"] != null) {
      response.data = data["response"];
    }

    super.onResponse(response, handler);
  }
}

/// [Provider], возвращающий объект [Dio] с зарегистрированными [Interceptor]'ами, используемый для создания обычных запросов.
///
/// Данный объект содержит в себе interceptor'ы, позволяющие:
/// - Повторять запрос в случае ошибки сети.
/// - Логировать запросы и их ответы.
///
/// Пример использования:
/// ```dart
/// await dio.get("https://example.com/")
/// ```
@riverpod
Dio dio(DioRef ref) {
  final Dio dio = Dio(
    BaseOptions(
      requestEncoder: gzipEncoder,
      responseDecoder: gzipDecoder,
      headers: {
        "User-Agent": vkAPIKateMobileUA,
        "Accept-Encoding": "gzip",
        "Content-Encoding": "gzip",
      },
    ),
  );

  initDioInterceptors(
    ref,
    dio,
  );

  return dio;
}

/// [Provider], возвращающий объект [Dio] с зарегистрированными [Interceptor]'ами, настроенный конкретно под работу с API ВКонтакте.
///
/// Данный объект содержит в себе interceptor'ы, позволяющие:
/// - Повторять запрос в случае ошибки сети.
/// - Логировать запросы и их ответы.
/// - Добавлять `access_token` и версию API в запросы.
///
/// Пример использования:
/// ```dart
/// await dio.post("users.get")
/// ```
@riverpod
Dio vkDio(VkDioRef ref) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: vkAPIBaseURL,
      requestEncoder: gzipEncoder,
      responseDecoder: gzipDecoder,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": vkAPIKateMobileUA,
        "Accept-Encoding": "gzip",
        "Content-Encoding": "gzip",

        // TODO: QUIC/msgpack/zstd support.
        // "x-quic": "1",
        // "X-Response-Format": "msgpack",
      },
    ),
  );

  initDioInterceptors(
    ref,
    dio,
    isVK: true,
  );

  return dio;
}
