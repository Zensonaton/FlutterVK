// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$playerHash() => r'd3c0c2994623387f4d80a5d8983cdde0517a8d6b';

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
String _$playerIsLoadedHash() => r'74922788b2b4c8a75a240ce7f71cc7b094814014';

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
String _$playerIsPlayingHash() => r'9a6d6bbca3ee532400f89aea22a2040c04688216';

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
String _$playerAudioHash() => r'95b4a18c59575b74d75ee91ab0b6c5bfd799879a';

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
String _$playerPositionHash() => r'403362a4d4abc647884790ddf4d1ab6c8bcfe455';

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
String _$playerSeekHash() => r'09a18ec976abe63239b21b0d619f009b730c0324';

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
String _$playerVolumeHash() => r'21f2649028f2ce1e4b4521bd57dc52414b5b8c26';

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
String _$playerIsBufferingHash() => r'552c23ad34e36b3ab6e5273c5184e0ecb5a1a0bc';

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
    r'c7ea9b82bac4b236b8090e309e64a367532483e0';

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
String _$playerPlaylistHash() => r'71fca4174b95b566fbc9166cb9b4faebabf5ba7c';

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
String _$playerQueueHash() => r'64824e9dcfe236d9c4d610e62baa8552c1e473c9';

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
String _$playerIsShufflingHash() => r'e65e69da76ad6dda8fbb92bb03dc7293964af05e';

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
String _$playerIsRepeatingHash() => r'5897420b76557fae203170c02d5f6ed7cd08c8ad';

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
String _$playerLogHash() => r'126187afebd56ea68997776383e510f1c484661f';

/// {@macro Player.logStream}
///
/// Copied from [playerLog].
@ProviderFor(playerLog)
final playerLogProvider = AutoDisposeStreamProvider<PlayerLog>.internal(
  playerLog,
  name: r'playerLogProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$playerLogHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerLogRef = AutoDisposeStreamProviderRef<PlayerLog>;
String _$playerErrorHash() => r'd059d7614761995694540f37b20674af38b82a85';

/// {@macro Player.errorStream}
///
/// Copied from [playerError].
@ProviderFor(playerError)
final playerErrorProvider = AutoDisposeStreamProvider<String>.internal(
  playerError,
  name: r'playerErrorProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$playerErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerErrorRef = AutoDisposeStreamProviderRef<String>;
String _$playerVolumeNormalizationHash() =>
    r'a46caebad08333308e47a41beacba067bf0902d4';

/// {@macro Player.volumeNormalizationStream}
///
/// Copied from [playerVolumeNormalization].
@ProviderFor(playerVolumeNormalization)
final playerVolumeNormalizationProvider =
    AutoDisposeStreamProvider<VolumeNormalization>.internal(
  playerVolumeNormalization,
  name: r'playerVolumeNormalizationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playerVolumeNormalizationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerVolumeNormalizationRef
    = AutoDisposeStreamProviderRef<VolumeNormalization>;
String _$playerSilenceRemovalEnabledHash() =>
    r'dc5beaece4e6ec8fe5ead40962a060ade624f9ff';

/// {@macro Player.silenceRemovalEnabledStream}
///
/// Copied from [playerSilenceRemovalEnabled].
@ProviderFor(playerSilenceRemovalEnabled)
final playerSilenceRemovalEnabledProvider =
    AutoDisposeStreamProvider<bool>.internal(
  playerSilenceRemovalEnabled,
  name: r'playerSilenceRemovalEnabledProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playerSilenceRemovalEnabledHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlayerSilenceRemovalEnabledRef = AutoDisposeStreamProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
