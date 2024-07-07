// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlists.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dbPlaylistsHash() => r'3e3f25c8bd181fb9a3c542b49b5091cbabb09628';

/// [Provider], загружающий информацию о плейлистах пользователя из локальной БД.
///
/// Copied from [dbPlaylists].
@ProviderFor(dbPlaylists)
final dbPlaylistsProvider = FutureProvider<PlaylistsState?>.internal(
  dbPlaylists,
  name: r'dbPlaylistsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dbPlaylistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DbPlaylistsRef = FutureProviderRef<PlaylistsState?>;
String _$favoritesPlaylistHash() => r'd4fb3026ea29c01478058de9e0ef1aa5237cfeb7';

/// [Provider], возвращающий [ExtendedPlaylist], характеризующий фейковый плейлист "Любимая музыка".
///
/// Copied from [favoritesPlaylist].
@ProviderFor(favoritesPlaylist)
final favoritesPlaylistProvider =
    AutoDisposeProvider<ExtendedPlaylist?>.internal(
  favoritesPlaylist,
  name: r'favoritesPlaylistProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoritesPlaylistHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FavoritesPlaylistRef = AutoDisposeProviderRef<ExtendedPlaylist?>;
String _$userPlaylistsHash() => r'6d7e57daf6fa68d1e0bfc6e5cf2c54300f081d59';

/// [Provider], возвращающий список плейлистов ([ExtendedPlaylist]) пользователя.
///
/// Copied from [userPlaylists].
@ProviderFor(userPlaylists)
final userPlaylistsProvider =
    AutoDisposeProvider<List<ExtendedPlaylist>?>.internal(
  userPlaylists,
  name: r'userPlaylistsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userPlaylistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserPlaylistsRef = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$mixPlaylistsHash() => r'9f2e3a654b9ab700f1967a4571330949f1f29ad1';

/// [Provider], возвращающий список рекомендуемых плейлистов ([ExtendedPlaylist]) пользователя типа "VK Mix".
///
/// Copied from [mixPlaylists].
@ProviderFor(mixPlaylists)
final mixPlaylistsProvider =
    AutoDisposeProvider<List<ExtendedPlaylist>?>.internal(
  mixPlaylists,
  name: r'mixPlaylistsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mixPlaylistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MixPlaylistsRef = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$moodPlaylistsHash() => r'846a228d671c76d185c16a9a17f51b066d130b57';

/// [Provider], возвращающий список рекомендуемых плейлистов ([ExtendedPlaylist]) пользователя по настроению.
///
/// Copied from [moodPlaylists].
@ProviderFor(moodPlaylists)
final moodPlaylistsProvider =
    AutoDisposeProvider<List<ExtendedPlaylist>?>.internal(
  moodPlaylists,
  name: r'moodPlaylistsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$moodPlaylistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MoodPlaylistsRef = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$recommendedPlaylistsHash() =>
    r'244e7fcc2560cf3e29d08f4a9ad33d3d4266d6f5';

/// [Provider], возвращающий список рекомендуемых плейлистов ([ExtendedPlaylist]) пользователя типа "Плейлист дня 1" и подобные.
///
/// Copied from [recommendedPlaylists].
@ProviderFor(recommendedPlaylists)
final recommendedPlaylistsProvider =
    AutoDisposeProvider<List<ExtendedPlaylist>?>.internal(
  recommendedPlaylists,
  name: r'recommendedPlaylistsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recommendedPlaylistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RecommendedPlaylistsRef
    = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$simillarPlaylistsHash() => r'755a13bb38638602b2e49a81decc68fac7434b0c';

/// [Provider], возвращающий список рекомендуемых плейлистов ([ExtendedPlaylist]) пользователя, которые имеют схожести с другими плейлистами пользователя ВКонтакте.
///
/// Copied from [simillarPlaylists].
@ProviderFor(simillarPlaylists)
final simillarPlaylistsProvider =
    AutoDisposeProvider<List<ExtendedPlaylist>?>.internal(
  simillarPlaylists,
  name: r'simillarPlaylistsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$simillarPlaylistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SimillarPlaylistsRef = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$madeByVKPlaylistsHash() => r'4dbcfb5fc857da017f89e77e2b0f21dcd3cf8bbe';

/// [Provider], возвращающий список рекомендуемых плейлистов ([ExtendedPlaylist]) от ВКонтакте.
///
/// Copied from [madeByVKPlaylists].
@ProviderFor(madeByVKPlaylists)
final madeByVKPlaylistsProvider =
    AutoDisposeProvider<List<ExtendedPlaylist>?>.internal(
  madeByVKPlaylists,
  name: r'madeByVKPlaylistsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$madeByVKPlaylistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MadeByVKPlaylistsRef = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$playlistsHash() => r'0746cadba8f7482fedb359326c06045cf12a62fa';

/// [Provider], хранящий в себе информацию о плейлистах пользователя.
///
/// Так же стоит обратить внимание на следующие [Provider]'ы, упрощающие доступ к получению плейлистов:
/// - [favoritesPlaylistProvider].
/// - [userPlaylistsProvider].
/// - [mixPlaylistsProvider].
/// - [moodPlaylistsProvider].
/// - [recommendedPlaylistsProvider].
/// - [simillarPlaylistsProvider].
/// - [madeByVKPlaylistsProvider].
///
/// Copied from [Playlists].
@ProviderFor(Playlists)
final playlistsProvider =
    AsyncNotifierProvider<Playlists, PlaylistsState?>.internal(
  Playlists.new,
  name: r'playlistsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$playlistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Playlists = AsyncNotifier<PlaylistsState?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
