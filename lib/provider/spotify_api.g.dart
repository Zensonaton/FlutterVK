// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spotify_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$spotifySPDCCookieHash() => r'e73fcf7c1ef63b65106f69ed3019c50a5117b6b3';

/// Возвращает значение Cookie `sp_dc` для Spotify.
///
/// Copied from [spotifySPDCCookie].
@ProviderFor(spotifySPDCCookie)
final spotifySPDCCookieProvider = AutoDisposeProvider<String?>.internal(
  spotifySPDCCookie,
  name: r'spotifySPDCCookieProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$spotifySPDCCookieHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SpotifySPDCCookieRef = AutoDisposeProviderRef<String?>;
String _$spotifyAPIHash() => r'26ba13c26bf7b7779e7c5ba8dd87d6d23fd50d95';

/// [Provider] для работы с API Spotify.
///
/// Copied from [SpotifyAPI].
@ProviderFor(SpotifyAPI)
final spotifyAPIProvider =
    AutoDisposeNotifierProvider<SpotifyAPI, SpotifyAuthData>.internal(
  SpotifyAPI.new,
  name: r'spotifyAPIProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$spotifyAPIHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SpotifyAPI = AutoDisposeNotifier<SpotifyAuthData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
