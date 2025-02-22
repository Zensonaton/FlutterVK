// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tokenHash() => r'1ce76c440f04284d8e03515767ed37ff2d7251e8';

/// Возвращает основной токен (Kate Mobile) для ВКонтакте.
///
/// Copied from [token].
@ProviderFor(token)
final tokenProvider = AutoDisposeProvider<String?>.internal(
  token,
  name: r'tokenProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tokenHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TokenRef = AutoDisposeProviderRef<String?>;
String _$secondaryTokenHash() => r'2f2043e60ee54766ea1bc82aba3896b2643be0d7';

/// Возвращает вторичный токен (VK Admin) для ВКонтакте.
///
/// Copied from [secondaryToken].
@ProviderFor(secondaryToken)
final secondaryTokenProvider = AutoDisposeProvider<String?>.internal(
  secondaryToken,
  name: r'secondaryTokenProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$secondaryTokenHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SecondaryTokenRef = AutoDisposeProviderRef<String?>;
String _$isDemoHash() => r'b27afefc2ba0ffdf74bece30bfafa47a9db4e7e0';

/// Возвращает true, если включён демо-режим.
///
/// Copied from [isDemo].
@ProviderFor(isDemo)
final isDemoProvider = AutoDisposeProvider<bool>.internal(
  isDemo,
  name: r'isDemoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isDemoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsDemoRef = AutoDisposeProviderRef<bool>;
String _$currentAuthStateHash() => r'160a1ab679d72e5e389a7a0c6ae85642f759e3cd';

/// [Provider] для хранения состояния авторизации пользователя. Позволяет авторизовывать и деавторизовывать пользователя.
///
/// Для получения доступа к этому [Provider] используйте [currentAuthStateProvider]:
/// ```dart
/// final AuthState authState = ref.read(currentAuthStateProvider);
/// ```
///
/// Copied from [CurrentAuthState].
@ProviderFor(CurrentAuthState)
final currentAuthStateProvider =
    AutoDisposeNotifierProvider<CurrentAuthState, AuthState>.internal(
  CurrentAuthState.new,
  name: r'currentAuthStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentAuthStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentAuthState = AutoDisposeNotifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
