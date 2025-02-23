// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dioHash() => r'e86d29b48f8cba82c13d86c9be1f2317363bb0d7';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DioRef = AutoDisposeProviderRef<Dio>;
String _$vkDioHash() => r'd8dcd47af9ba9829b4da50dc12da08a994a249a9';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VkDioRef = AutoDisposeProviderRef<Dio>;
String _$lrcLibDioHash() => r'2d243cd93fff5f7622b90bf42fbe863bd0748d82';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LrcLibDioRef = AutoDisposeProviderRef<Dio>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
