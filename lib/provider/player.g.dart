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
String _$playerIsLoadedHash() => r'370507fedd08dd88e8ddcf32c1e26616a223bf3c';

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
String _$playerIsPlayingHash() => r'2ea578990e0d625e86cd8e3b9493ef93284c6e4c';

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
String _$playerAudioHash() => r'7fb47ba28aae7830ceb68ef4044d56d3c6c670cf';

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
String _$playerPositionHash() => r'4080fd36037354ee82dc5ba8831279ae003fc549';

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
String _$playerSeekHash() => r'4d1e713bbf38c70aecf1dbd1b88a1f574cf6255c';

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
String _$playerVolumeHash() => r'87c61bb2b8cff485f50e424f9df4ddb12e960d30';

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
String _$playerIsBufferingHash() => r'00be868a33ba3ee60b4d66f73d1f77704b4ad236';

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
    r'5f6036d130d14e54e94bb6c8efd07938ebcaa1ef';

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
String _$playerPlaylistHash() => r'ad4f3e58b2ef97e0020dc24951f84dea031e4be4';

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
String _$playerQueueHash() => r'75bfb4aae92dc17ceeee9a36f8cf00265a09c9fa';

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
String _$playerIsShufflingHash() => r'198cf8cba9bedf3108a043539e9ab16c9840bf86';

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
String _$playerIsRepeatingHash() => r'f246537a7a7106d6dc5d301d9e40aed476f1194f';

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
