// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlists.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dbPlaylistsHash() => r'a48b3bc960a3ea6a0f8d9ee6cefe21e1a365908d';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DbPlaylistsRef = FutureProviderRef<PlaylistsState?>;
String _$favoritesPlaylistHash() => r'7f8eb78aaca460a97d34745e7c92462e4aaa30d6';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FavoritesPlaylistRef = AutoDisposeProviderRef<ExtendedPlaylist?>;
String _$searchResultsPlaylistHash() =>
    r'85bc22d8d272b22b0a66339fdb7906fd7afd474d';

/// [Provider], возвращающий [ExtendedPlaylist], характеризующий фейковый плейлист "Музыка из результатов поиска".
///
/// Copied from [searchResultsPlaylist].
@ProviderFor(searchResultsPlaylist)
final searchResultsPlaylistProvider =
    AutoDisposeProvider<ExtendedPlaylist?>.internal(
  searchResultsPlaylist,
  name: r'searchResultsPlaylistProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchResultsPlaylistHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchResultsPlaylistRef = AutoDisposeProviderRef<ExtendedPlaylist?>;
String _$userPlaylistsHash() => r'db3194d97744dbbbd96f50c2dba14b6a9f73aad7';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserPlaylistsRef = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$mixPlaylistsHash() => r'a6a9d455b79f890f4f6b74becbe5dfa4972abe55';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MixPlaylistsRef = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$moodPlaylistsHash() => r'b6c78c578e82f00055616e3a447fe75117ddea0f';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MoodPlaylistsRef = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$recommendedPlaylistsHash() =>
    r'876f62d4eb9f7f4cd3189397b32807450ecfff54';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecommendedPlaylistsRef
    = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$simillarPlaylistsHash() => r'427d1d67edf5ee846503a9b3220047c7a26ef2ee';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SimillarPlaylistsRef = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$madeByVKPlaylistsHash() => r'02235febbcc6ba11e620ddb583f6bac3d3d856b7';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MadeByVKPlaylistsRef = AutoDisposeProviderRef<List<ExtendedPlaylist>?>;
String _$getPlaylistHash() => r'd286b4872aebdd61fc3d2d552f8d8a46703868cb';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// [Provider], возвращающий [ExtendedPlaylist] по передаваемому [ownerID] и [id] плейлиста.
///
/// Copied from [getPlaylist].
@ProviderFor(getPlaylist)
const getPlaylistProvider = GetPlaylistFamily();

/// [Provider], возвращающий [ExtendedPlaylist] по передаваемому [ownerID] и [id] плейлиста.
///
/// Copied from [getPlaylist].
class GetPlaylistFamily extends Family<ExtendedPlaylist?> {
  /// [Provider], возвращающий [ExtendedPlaylist] по передаваемому [ownerID] и [id] плейлиста.
  ///
  /// Copied from [getPlaylist].
  const GetPlaylistFamily();

  /// [Provider], возвращающий [ExtendedPlaylist] по передаваемому [ownerID] и [id] плейлиста.
  ///
  /// Copied from [getPlaylist].
  GetPlaylistProvider call(
    int ownerID,
    int id,
  ) {
    return GetPlaylistProvider(
      ownerID,
      id,
    );
  }

  @override
  GetPlaylistProvider getProviderOverride(
    covariant GetPlaylistProvider provider,
  ) {
    return call(
      provider.ownerID,
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'getPlaylistProvider';
}

/// [Provider], возвращающий [ExtendedPlaylist] по передаваемому [ownerID] и [id] плейлиста.
///
/// Copied from [getPlaylist].
class GetPlaylistProvider extends AutoDisposeProvider<ExtendedPlaylist?> {
  /// [Provider], возвращающий [ExtendedPlaylist] по передаваемому [ownerID] и [id] плейлиста.
  ///
  /// Copied from [getPlaylist].
  GetPlaylistProvider(
    int ownerID,
    int id,
  ) : this._internal(
          (ref) => getPlaylist(
            ref as GetPlaylistRef,
            ownerID,
            id,
          ),
          from: getPlaylistProvider,
          name: r'getPlaylistProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getPlaylistHash,
          dependencies: GetPlaylistFamily._dependencies,
          allTransitiveDependencies:
              GetPlaylistFamily._allTransitiveDependencies,
          ownerID: ownerID,
          id: id,
        );

  GetPlaylistProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.ownerID,
    required this.id,
  }) : super.internal();

  final int ownerID;
  final int id;

  @override
  Override overrideWith(
    ExtendedPlaylist? Function(GetPlaylistRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetPlaylistProvider._internal(
        (ref) => create(ref as GetPlaylistRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        ownerID: ownerID,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<ExtendedPlaylist?> createElement() {
    return _GetPlaylistProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetPlaylistProvider &&
        other.ownerID == ownerID &&
        other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, ownerID.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetPlaylistRef on AutoDisposeProviderRef<ExtendedPlaylist?> {
  /// The parameter `ownerID` of this provider.
  int get ownerID;

  /// The parameter `id` of this provider.
  int get id;
}

class _GetPlaylistProviderElement
    extends AutoDisposeProviderElement<ExtendedPlaylist?> with GetPlaylistRef {
  _GetPlaylistProviderElement(super.provider);

  @override
  int get ownerID => (origin as GetPlaylistProvider).ownerID;
  @override
  int get id => (origin as GetPlaylistProvider).id;
}

String _$playlistsHash() => r'392a06a8365e6d0127d46ce49672356b149864fc';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
