// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$playerHash() => r'c2b3c51844b2d7f701cb80094810e44bb12633ba';

/// [Provider] для получения объекта [Player] для воспроизведения музыки.
///
/// Copied from [player].
@ProviderFor(player)
final playerProvider = Provider<Player>.internal(
  player,
  name: r'playerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$playerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerRef = ProviderRef<Player>;
String _$playerIsLoadedHash() => r'5130c15b136ad81d3107304c416eed1a2e3d9d86';

/// {@macro Player.isLoadedStream}
///
/// Copied from [playerIsLoaded].
@ProviderFor(playerIsLoaded)
final playerIsLoadedProvider = AutoDisposeStreamProvider<bool>.internal(
  playerIsLoaded,
  name: r'playerIsLoadedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playerIsLoadedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerIsLoadedRef = AutoDisposeStreamProviderRef<bool>;
String _$playerIsPlayingHash() => r'9ab20456869a9f49b91d97f84318b1c769bfceed';

/// {@macro Player.isPlayingStream}
///
/// Copied from [playerIsPlaying].
@ProviderFor(playerIsPlaying)
final playerIsPlayingProvider = AutoDisposeStreamProvider<bool>.internal(
  playerIsPlaying,
  name: r'playerIsPlayingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playerIsPlayingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerIsPlayingRef = AutoDisposeStreamProviderRef<bool>;
String _$playerAudioHash() => r'e18cb646f94ecf87297f3a1215c1629b5873b700';

/// {@macro Player.audioStream}
///
/// Copied from [playerAudio].
@ProviderFor(playerAudio)
final playerAudioProvider = AutoDisposeStreamProvider<ExtendedAudio>.internal(
  playerAudio,
  name: r'playerAudioProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$playerAudioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerAudioRef = AutoDisposeStreamProviderRef<ExtendedAudio>;
String _$playerPositionHash() => r'd5a059e7ee11354236a3436db77a992079b72a82';

/// {@macro Player.positionStream}
///
/// Copied from [playerPosition].
@ProviderFor(playerPosition)
final playerPositionProvider = AutoDisposeStreamProvider<Duration>.internal(
  playerPosition,
  name: r'playerPositionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playerPositionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerPositionRef = AutoDisposeStreamProviderRef<Duration>;
String _$playerSeekHash() => r'947febc91ba2722f6538acccb7fcb0aac6013468';

/// {@macro Player.seekStream}
///
/// Copied from [playerSeek].
@ProviderFor(playerSeek)
final playerSeekProvider = AutoDisposeStreamProvider<Duration>.internal(
  playerSeek,
  name: r'playerSeekProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$playerSeekHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerSeekRef = AutoDisposeStreamProviderRef<Duration>;
String _$playerVolumeHash() => r'74f5604486c8a5087f095db71a320d3b62ff9b13';

/// {@macro Player.volumeStream}
///
/// Copied from [playerVolume].
@ProviderFor(playerVolume)
final playerVolumeProvider = AutoDisposeStreamProvider<double>.internal(
  playerVolume,
  name: r'playerVolumeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$playerVolumeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerVolumeRef = AutoDisposeStreamProviderRef<double>;
String _$playerIsBufferingHash() => r'c11304c8c83040104eeaef9c681d4367c03e1ba3';

/// {@macro Player.isBufferingStream}
///
/// Copied from [playerIsBuffering].
@ProviderFor(playerIsBuffering)
final playerIsBufferingProvider = AutoDisposeStreamProvider<bool>.internal(
  playerIsBuffering,
  name: r'playerIsBufferingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playerIsBufferingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerIsBufferingRef = AutoDisposeStreamProviderRef<bool>;
String _$playerBufferedPositionHash() =>
    r'd6bb1004ed6279964a5d5c502658843b66856bb7';

/// {@macro Player.bufferedPositionStream}
///
/// Copied from [playerBufferedPosition].
@ProviderFor(playerBufferedPosition)
final playerBufferedPositionProvider =
    AutoDisposeStreamProvider<Duration>.internal(
  playerBufferedPosition,
  name: r'playerBufferedPositionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playerBufferedPositionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerBufferedPositionRef = AutoDisposeStreamProviderRef<Duration>;
String _$playerPlaylistHash() => r'4ca46e75edc3d95e7f8781d16b818995b4bee6e8';

/// {@macro Player.playlistStream}
///
/// Copied from [playerPlaylist].
@ProviderFor(playerPlaylist)
final playerPlaylistProvider =
    AutoDisposeStreamProvider<ExtendedPlaylist>.internal(
  playerPlaylist,
  name: r'playerPlaylistProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playerPlaylistHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerPlaylistRef = AutoDisposeStreamProviderRef<ExtendedPlaylist>;
String _$playerQueueHash() => r'73bd41cfa01527af8221eeb00a1b0308be064779';

/// {@macro Player.queueStream}
///
/// Copied from [playerQueue].
@ProviderFor(playerQueue)
final playerQueueProvider =
    AutoDisposeStreamProvider<List<ExtendedAudio>>.internal(
  playerQueue,
  name: r'playerQueueProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$playerQueueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerQueueRef = AutoDisposeStreamProviderRef<List<ExtendedAudio>>;
String _$playerIsShufflingHash() => r'77a2a3124241d4c62d1e3b9075a2470a23d43d1b';

/// {@macro Player.isShufflingStream}
///
/// Copied from [playerIsShuffling].
@ProviderFor(playerIsShuffling)
final playerIsShufflingProvider = AutoDisposeStreamProvider<bool>.internal(
  playerIsShuffling,
  name: r'playerIsShufflingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playerIsShufflingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerIsShufflingRef = AutoDisposeStreamProviderRef<bool>;
String _$playerIsRepeatingHash() => r'ab514be456bb5de86245938606a22c002abeca27';

/// {@macro Player.isRepeatingStream}
///
/// Copied from [playerIsRepeating].
@ProviderFor(playerIsRepeating)
final playerIsRepeatingProvider = AutoDisposeStreamProvider<bool>.internal(
  playerIsRepeating,
  name: r'playerIsRepeatingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playerIsRepeatingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerIsRepeatingRef = AutoDisposeStreamProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
