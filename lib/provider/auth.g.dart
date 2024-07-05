// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tokenHash() => r'd3157a000e2c022d6d0f54985a36d6f59b60b9bf';

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
String _$secondaryTokenHash() => r'086f3f28514feba48741b8ec386775178b295552';

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
String _$currentAuthStateHash() => r'4faced97d2c4858090718b7959545e35784773bf';

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