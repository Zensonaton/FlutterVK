// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dioHash() => r'cef074d595217af69375dab7909d4bc9d33928d0';

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
///
/// Copied from [dio].
@ProviderFor(dio)
final dioProvider = AutoDisposeProvider<Dio>.internal(
  dio,
  name: r'dioProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DioRef = AutoDisposeProviderRef<Dio>;
String _$vkDioHash() => r'90961afbafc61fe18d7a433ee31dffa5eac9f210';

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
///
/// Copied from [vkDio].
@ProviderFor(vkDio)
final vkDioProvider = AutoDisposeProvider<Dio>.internal(
  vkDio,
  name: r'vkDioProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$vkDioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VkDioRef = AutoDisposeProviderRef<Dio>;
String _$lrcLibDioHash() => r'c6d88dff6ecb7ca6f7c2e1161f634f8d26309e6d';

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
///
/// Copied from [lrcLibDio].
@ProviderFor(lrcLibDio)
final lrcLibDioProvider = AutoDisposeProvider<Dio>.internal(
  lrcLibDio,
  name: r'lrcLibDioProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$lrcLibDioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LrcLibDioRef = AutoDisposeProviderRef<Dio>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
