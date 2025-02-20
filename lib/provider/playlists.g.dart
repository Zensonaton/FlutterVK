// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlists.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dbPlaylistsHash() => r'63dae5c097c923479c7c821764e469968f0e931d';

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
String _$favoritesPlaylistHash() => r'0742712f7d0a208cf6db561d115ec2f2f1a923a9';

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
String _$searchResultsPlaylistHash() =>
    r'cf07341f574ae51d838afb845e80a3b3b2f3cc73';

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

typedef SearchResultsPlaylistRef = AutoDisposeProviderRef<ExtendedPlaylist?>;
String _$userPlaylistsHash() => r'dc9239504382be5944942bd4462a6eaac1a6f9eb';

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
String _$mixPlaylistsHash() => r'b92c6879671d5aeae9794e334afa1a2e6a39f518';

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
String _$moodPlaylistsHash() => r'790a815ea5478f6ef4f0c45ccb3bbab87c35211e';

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
    r'b10ec810b9f0b262f5178c206962d2075036771a';

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
String _$simillarPlaylistsHash() => r'f634fb7c40a5d628f457a9d189bb4aee078f252c';

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
String _$madeByVKPlaylistsHash() => r'4aa456da0be0e9c7d9caf7e84bef2ca82b3f7849';

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

String _$playlistsHash() => r'cf6b420aa231ea0c81e2475339f4d552da0eff90';

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
