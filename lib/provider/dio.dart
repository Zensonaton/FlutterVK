import "dart:convert";
import "dart:io";

import "package:awesome_dio_interceptor/awesome_dio_interceptor.dart";
import "package:dio/dio.dart";
import "package:dio/io.dart";
import "package:dio_smart_retry/dio_smart_retry.dart";
import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../api/lrclib/consts.dart";
import "../api/lrclib/shared.dart";
import "../api/vk/consts.dart";
import "../api/vk/shared.dart";
import "../consts.dart";
import "../services/logger.dart";
import "auth.dart";

part "dio.g.dart";

/// [HttpClient], в котором отключена SSL-проверка.
///
/// Вместо этого, рекомендуется использовать [dio].
final HttpClient httpClient = HttpClient()
  ..badCertificateCallback = (cert, host, port) => true;

/// Request Encoder для [Dio], реализовывающий поддержку GZip.
List<int> gzipEncoder(
  String request,
  RequestOptions options,
) {
  return gzip.encode(utf8.encode(request));
}

/// Возвращает объект [Dio] с зарегистрированными [Interceptor]'ами.
void initDioInterceptors(
  Ref ref,
  Dio dio, {
  String loggerName = "Dio",
  bool isVK = false,
  bool isLRCLib = false,
}) {
  final AppLogger logger = getLogger(loggerName);

  // Игнорируем плохие SSL-сертификаты.
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
      () => httpClient;

  dio.interceptors.addAll([
    // Обработчик для добавления версии API и access_token для VK API.
    if (isVK)
      VKAPIInterceptor(
        ref: ref,
      ),

    // Обработчик для ошибок API LRCLib.
    if (isLRCLib) LRCLIBInterceptor(),

    // Обработчик для повтора HTTP-запросов в случае ошибок сети.
    RetryInterceptor(
      dio: dio,
      logPrint: (String log) => logger.d(log),
      retryEvaluator: (DioException error, int attempt) {
        // Если ошибка является игнорируемой, то не повторяем запрос.
        if (error is VKAPIException || error is LRCLIBException) {
          return false;
        }

        return true;
      },
      retryDelays: [
        Duration(
          seconds: isLRCLib ? 2 : 1,
        ),
      ],
      retries: isLRCLib ? 1 : 3,
    ),

    // Обработчик для логирования HTTP-запросов и их ответов в debug-режиме.
    if (kDebugMode && false)
      // ignore: dead_code
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
    final headers = options.headers;
    final body = options.data as Map<String, dynamic>;
    final extras = options.extra;

    // Удаляем null-поля.
    body.removeWhere((key, value) => value == null);

    // Устанавливаем ключ с версией API ВКонтакте.
    options.queryParameters["v"] = vkAPIVersion;

    // Устанавливаем access_token в HTTP Header, если он не установлен.
    final bool useSecondary = extras["useSecondary"] ?? false;
    final token = body.remove("access_token") ??
        _ref.read(useSecondary ? secondaryTokenProvider : tokenProvider);
    if (token == null) {
      throw Exception("Access token is null (secondary: $useSecondary)");
    }

    headers["Authorization"] = "Bearer $token";

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data as Map<String, dynamic>;
    final error = data["error"] ?? data["execute_errors"]?.first;

    // Проверяем на наличие ошибок.
    if (error != null) {
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

/// [Interceptor] для [Dio], обрабатывающий возможные ошибки, возвращаемые API LRCLib.
class LRCLIBInterceptor extends Interceptor {
  LRCLIBInterceptor();

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Проверяем на наличие ошибок.
    if (response.data is Map) {
      final data = response.data as Map<String, dynamic>;

      if (response.statusCode! >= 300 && data.containsKey("statusCode")) {
        throw LRCLIBException(
          code: data["statusCode"],
          name: data["name"],
          message: data["message"],
          requestOptions: response.requestOptions,
        );
      }
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
      validateStatus: (_) => true,
      headers: {
        "User-Agent": browserUA,
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
    loggerName: "VK",
    isVK: true,
  );

  return dio;
}

/// [Provider], возвращающий объект [Dio] с зарегистрированными [Interceptor]'ами, настроенный для создания API-запросов к сервису LRCLIB.
///
/// Данный объект содержит в себе interceptor'ы, позволяющие:
/// - Повторять запрос в случае ошибки сети.
/// - Логировать запросы и их ответы.
///
/// Пример использования:
/// ```dart
/// await dio.get("search?q=Never Gonna Give You Up")
/// ```
@riverpod
Dio lrcLibDio(LrcLibDioRef ref) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: lrcLibBaseURL,
      requestEncoder: gzipEncoder,
      validateStatus: (_) => true,
      headers: {
        "User-Agent": lrcLibUA,
        "Accept-Encoding": "gzip",
        "Content-Encoding": "gzip",
      },
    ),
  );

  initDioInterceptors(
    ref,
    dio,
    loggerName: "LRCLib",
    isLRCLib: true,
  );

  return dio;
}
