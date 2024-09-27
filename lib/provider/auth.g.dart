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

typedef SecondaryTokenRef = AutoDisposeProviderRef<String?>;
String _$currentAuthStateHash() => r'a3ab5cf7d99e12e4af78b9fe09fce0dad4a8aeac';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
