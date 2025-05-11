import "dart:convert";
import "dart:io";

import "package:dio/dio.dart";
import "package:dio_smart_retry/dio_smart_retry.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../api/apple_music/consts.dart";
import "../api/lrclib/consts.dart";
import "../api/lrclib/shared.dart";
import "../api/vk/consts.dart";
import "../api/vk/shared.dart";
import "../consts.dart";
import "../services/logger.dart";
import "../utils.dart";
import "auth.dart";

part "dio.g.dart";

/// Тип API для Dio.
enum DioType {
  dio,
  vk,
  lrcLib,
  appleMusic,
}

/// Request Encoder для [Dio], реализовывающий поддержку GZip.
List<int> gzipEncoder(
  String request,
  RequestOptions options,
) {
  if (isWeb) {
    return utf8.encode(request);
  }

  return gzip.encode(utf8.encode(request));
}

/// Возвращает объект [Dio] с зарегистрированными [Interceptor]'ами.
void initDioInterceptors(Ref ref, Dio dio, DioType type) {
  final AppLogger logger = getLogger(type.name);

  final isVK = type == DioType.vk;
  final isLRCLib = type == DioType.lrcLib;

  dio.interceptors.addAll([
    DemoInterceptor(
      ref: ref,
    ),
    if (isVK)
      VKAPIInterceptor(
        ref: ref,
      ),
    if (isLRCLib) LRCLIBInterceptor(),
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
          seconds: type == DioType.lrcLib ? 2 : 1,
        ),
      ],
      retries: type == DioType.lrcLib ? 1 : 3,
    ),
  ]);
}

/// [Interceptor] для [Dio], заменяющий запрос на демо-ответ.
class DemoInterceptor extends Interceptor {
  final Ref _ref;

  DemoInterceptor({
    required Ref ref,
  }) : _ref = ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.data is Map<String, dynamic>) {
      final data = options.data as Map<String, dynamic>;
      final demo = data.remove("_demo_");
      final allowDemoResponse =
          _ref.read(isDemoProvider) || data["access_token"] == "DEMO";

      if (demo != null && allowDemoResponse) {
        handler.resolve(
          Response(
            requestOptions: options,
            data: demo,
            statusCode: 200,
          ),
        );

        return;
      }
    }

    super.onRequest(options, handler);
  }
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
Dio dio(Ref ref) {
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

  initDioInterceptors(ref, dio, DioType.dio);

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
Dio vkDio(Ref ref) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: vkAPIBaseURL,
      requestEncoder: gzipEncoder,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": vkAPIKateMobileUA,
        "Accept-Encoding": "gzip",
        "Content-Encoding": "gzip",
      },
    ),
  );

  initDioInterceptors(ref, dio, DioType.vk);

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
Dio lrcLibDio(Ref ref) {
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

  initDioInterceptors(ref, dio, DioType.lrcLib);

  return dio;
}

/// [Provider], возвращающий объект [Dio] с зарегистрированными [Interceptor]'ами, настроенный для создания API-запросов к Apple Music.
///
/// Данный объект содержит в себе interceptor'ы, позволяющие:
/// - Повторять запрос в случае ошибки сети.
/// - Логировать запросы и их ответы.
@riverpod
Dio appleMusicDio(Ref ref) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: appleMusicBaseURL,
      requestEncoder: gzipEncoder,
      validateStatus: (_) => true,
      headers: {
        "Origin": "https://music.apple.com",
        "Authorization": "Bearer $appleMusicApiKey",
      },
    ),
  );

  initDioInterceptors(ref, dio, DioType.appleMusic);

  return dio;
}
