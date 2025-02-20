import "package:riverpod_annotation/riverpod_annotation.dart";

import "../services/player/player.dart";
import "user.dart";

part "player.g.dart";

/// [Provider] для получения объекта [Player] для воспроизведения музыки.
@Riverpod(keepAlive: true)
Player player(PlayerRef ref) => Player(ref);

/// {@macro Player.isLoadedStream}
@riverpod
Stream<bool> playerIsLoaded(PlayerIsLoadedRef ref) =>
    ref.read(playerProvider).isLoadedStream;

/// {@macro Player.isPlayingStream}
@riverpod
Stream<bool> playerIsPlaying(PlayerIsPlayingRef ref) =>
    ref.read(playerProvider).isPlayingStream;

/// {@macro Player.audioStream}
@riverpod
Stream<ExtendedAudio> playerAudio(PlayerAudioRef ref) =>
    ref.read(playerProvider).audioStream;

/// {@macro Player.positionStream}
@riverpod
Stream<Duration> playerPosition(PlayerPositionRef ref) =>
    ref.read(playerProvider).positionStream;

/// {@macro Player.seekStream}
@riverpod
Stream<Duration> playerSeek(PlayerSeekRef ref) =>
    ref.read(playerProvider).seekStream;

/// {@macro Player.volumeStream}
@riverpod
Stream<double> playerVolume(PlayerVolumeRef ref) =>
    ref.read(playerProvider).volumeStream;

/// {@macro Player.isBufferingStream}
@riverpod
Stream<bool> playerIsBuffering(PlayerIsBufferingRef ref) =>
    ref.read(playerProvider).isBufferingStream;

/// {@macro Player.bufferedPositionStream}
@riverpod
Stream<Duration> playerBufferedPosition(PlayerBufferedPositionRef ref) =>
    ref.read(playerProvider).bufferedPositionStream;

/// {@macro Player.playlistStream}
@riverpod
Stream<ExtendedPlaylist> playerPlaylist(PlayerPlaylistRef ref) =>
    ref.read(playerProvider).playlistStream;

/// {@macro Player.queueStream}
@riverpod
Stream<List<ExtendedAudio>> playerQueue(PlayerQueueRef ref) =>
    ref.read(playerProvider).queueStream;

/// {@macro Player.isShufflingStream}
@riverpod
Stream<bool> playerIsShuffling(PlayerIsShufflingRef ref) =>
    ref.read(playerProvider).isShufflingStream;

/// {@macro Player.isRepeatingStream}
@riverpod
Stream<bool> playerIsRepeating(PlayerIsRepeatingRef ref) =>
    ref.read(playerProvider).isRepeatingStream;
