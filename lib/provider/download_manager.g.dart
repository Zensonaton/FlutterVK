// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$downloadTaskByIDHash() => r'4ad3eb06440cc33a2b82485de4d747f4a8e5bae6';

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

/// Возвращает [DownloadTask] по его [id].
///
/// Copied from [downloadTaskByID].
@ProviderFor(downloadTaskByID)
const downloadTaskByIDProvider = DownloadTaskByIDFamily();

/// Возвращает [DownloadTask] по его [id].
///
/// Copied from [downloadTaskByID].
class DownloadTaskByIDFamily extends Family<DownloadTask?> {
  /// Возвращает [DownloadTask] по его [id].
  ///
  /// Copied from [downloadTaskByID].
  const DownloadTaskByIDFamily();

  /// Возвращает [DownloadTask] по его [id].
  ///
  /// Copied from [downloadTaskByID].
  DownloadTaskByIDProvider call(
    String id,
  ) {
    return DownloadTaskByIDProvider(
      id,
    );
  }

  @override
  DownloadTaskByIDProvider getProviderOverride(
    covariant DownloadTaskByIDProvider provider,
  ) {
    return call(
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
  String? get name => r'downloadTaskByIDProvider';
}

/// Возвращает [DownloadTask] по его [id].
///
/// Copied from [downloadTaskByID].
class DownloadTaskByIDProvider extends AutoDisposeProvider<DownloadTask?> {
  /// Возвращает [DownloadTask] по его [id].
  ///
  /// Copied from [downloadTaskByID].
  DownloadTaskByIDProvider(
    String id,
  ) : this._internal(
          (ref) => downloadTaskByID(
            ref as DownloadTaskByIDRef,
            id,
          ),
          from: downloadTaskByIDProvider,
          name: r'downloadTaskByIDProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$downloadTaskByIDHash,
          dependencies: DownloadTaskByIDFamily._dependencies,
          allTransitiveDependencies:
              DownloadTaskByIDFamily._allTransitiveDependencies,
          id: id,
        );

  DownloadTaskByIDProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    DownloadTask? Function(DownloadTaskByIDRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DownloadTaskByIDProvider._internal(
        (ref) => create(ref as DownloadTaskByIDRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<DownloadTask?> createElement() {
    return _DownloadTaskByIDProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DownloadTaskByIDProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DownloadTaskByIDRef on AutoDisposeProviderRef<DownloadTask?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _DownloadTaskByIDProviderElement
    extends AutoDisposeProviderElement<DownloadTask?> with DownloadTaskByIDRef {
  _DownloadTaskByIDProviderElement(super.provider);

  @override
  String get id => (origin as DownloadTaskByIDProvider).id;
}

String _$downloadManagerHash() => r'f76e7075ffbb3d56df039b620e812c53301b4218';

/// [Provider], предоставляющий доступ к менеджеру загрузок.
///
/// Copied from [DownloadManager].
@ProviderFor(DownloadManager)
final downloadManagerProvider =
    AutoDisposeNotifierProvider<DownloadManager, DownloadManagerState>.internal(
  DownloadManager.new,
  name: r'downloadManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$downloadManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DownloadManager = AutoDisposeNotifier<DownloadManagerState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
