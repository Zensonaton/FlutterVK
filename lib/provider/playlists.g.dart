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
String _$getPlaylistHash() => r'63afe756e91a2d5e00591af4ac15e8f66f3f93c9';

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

String _$playlistsHash() => r'26f0a2d9a2cd05c2194bae1b1545eedad57f3830';

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
