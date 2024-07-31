// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'color.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$colorInfoFromPlaylistHash() =>
    r'00515bf49391c4d8252f542b32ab3dc37f96c9b8';

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

/// [Provider], извлекающий цвета из изображения плейлиста, а так же сохраняющий их.
///
/// Если таковые цвета уже есть, то вместо извлечения новых, возвращаются старые.
///
/// Copied from [colorInfoFromPlaylist].
@ProviderFor(colorInfoFromPlaylist)
const colorInfoFromPlaylistProvider = ColorInfoFromPlaylistFamily();

/// [Provider], извлекающий цвета из изображения плейлиста, а так же сохраняющий их.
///
/// Если таковые цвета уже есть, то вместо извлечения новых, возвращаются старые.
///
/// Copied from [colorInfoFromPlaylist].
class ColorInfoFromPlaylistFamily
    extends Family<AsyncValue<ImageSchemeExtractor?>> {
  /// [Provider], извлекающий цвета из изображения плейлиста, а так же сохраняющий их.
  ///
  /// Если таковые цвета уже есть, то вместо извлечения новых, возвращаются старые.
  ///
  /// Copied from [colorInfoFromPlaylist].
  const ColorInfoFromPlaylistFamily();

  /// [Provider], извлекающий цвета из изображения плейлиста, а так же сохраняющий их.
  ///
  /// Если таковые цвета уже есть, то вместо извлечения новых, возвращаются старые.
  ///
  /// Copied from [colorInfoFromPlaylist].
  ColorInfoFromPlaylistProvider call(
    int ownerID,
    int id,
  ) {
    return ColorInfoFromPlaylistProvider(
      ownerID,
      id,
    );
  }

  @override
  ColorInfoFromPlaylistProvider getProviderOverride(
    covariant ColorInfoFromPlaylistProvider provider,
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
  String? get name => r'colorInfoFromPlaylistProvider';
}

/// [Provider], извлекающий цвета из изображения плейлиста, а так же сохраняющий их.
///
/// Если таковые цвета уже есть, то вместо извлечения новых, возвращаются старые.
///
/// Copied from [colorInfoFromPlaylist].
class ColorInfoFromPlaylistProvider
    extends AutoDisposeFutureProvider<ImageSchemeExtractor?> {
  /// [Provider], извлекающий цвета из изображения плейлиста, а так же сохраняющий их.
  ///
  /// Если таковые цвета уже есть, то вместо извлечения новых, возвращаются старые.
  ///
  /// Copied from [colorInfoFromPlaylist].
  ColorInfoFromPlaylistProvider(
    int ownerID,
    int id,
  ) : this._internal(
          (ref) => colorInfoFromPlaylist(
            ref as ColorInfoFromPlaylistRef,
            ownerID,
            id,
          ),
          from: colorInfoFromPlaylistProvider,
          name: r'colorInfoFromPlaylistProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$colorInfoFromPlaylistHash,
          dependencies: ColorInfoFromPlaylistFamily._dependencies,
          allTransitiveDependencies:
              ColorInfoFromPlaylistFamily._allTransitiveDependencies,
          ownerID: ownerID,
          id: id,
        );

  ColorInfoFromPlaylistProvider._internal(
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
    FutureOr<ImageSchemeExtractor?> Function(ColorInfoFromPlaylistRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ColorInfoFromPlaylistProvider._internal(
        (ref) => create(ref as ColorInfoFromPlaylistRef),
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
  AutoDisposeFutureProviderElement<ImageSchemeExtractor?> createElement() {
    return _ColorInfoFromPlaylistProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ColorInfoFromPlaylistProvider &&
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

mixin ColorInfoFromPlaylistRef
    on AutoDisposeFutureProviderRef<ImageSchemeExtractor?> {
  /// The parameter `ownerID` of this provider.
  int get ownerID;

  /// The parameter `id` of this provider.
  int get id;
}

class _ColorInfoFromPlaylistProviderElement
    extends AutoDisposeFutureProviderElement<ImageSchemeExtractor?>
    with ColorInfoFromPlaylistRef {
  _ColorInfoFromPlaylistProviderElement(super.provider);

  @override
  int get ownerID => (origin as ColorInfoFromPlaylistProvider).ownerID;
  @override
  int get id => (origin as ColorInfoFromPlaylistProvider).id;
}

String _$trackSchemeInfoHash() => r'99c3fd94a69b0c9af063cdd1871db24db208cb15';

/// [Provider], который извлекает цветовые схемы из передаваемого изображения трека.
///
/// Copied from [TrackSchemeInfo].
@ProviderFor(TrackSchemeInfo)
final trackSchemeInfoProvider = AutoDisposeNotifierProvider<TrackSchemeInfo,
    ImageSchemeExtractor?>.internal(
  TrackSchemeInfo.new,
  name: r'trackSchemeInfoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trackSchemeInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TrackSchemeInfo = AutoDisposeNotifier<ImageSchemeExtractor?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
