import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../services/player/player.dart";
import "user.dart";

part "player.g.dart";

/// [Provider] для получения объекта [Player] для воспроизведения музыки.
@Riverpod(keepAlive: true)
Player player(Ref ref) => Player(ref);

/// {@macro Player.isLoadedStream}
@riverpod
Stream<bool> playerIsLoaded(Ref ref) => ref.read(playerProvider).isLoadedStream;

/// {@macro Player.isPlayingStream}
@riverpod
Stream<bool> playerIsPlaying(Ref ref) =>
    ref.read(playerProvider).isPlayingStream;

/// {@macro Player.audioStream}
@riverpod
Stream<ExtendedAudio> playerAudio(Ref ref) =>
    ref.read(playerProvider).audioStream;

/// {@macro Player.positionStream}
@riverpod
Stream<Duration> playerPosition(Ref ref) =>
    ref.read(playerProvider).positionStream;

/// {@macro Player.seekStream}
@riverpod
Stream<Duration> playerSeek(Ref ref) => ref.read(playerProvider).seekStream;

/// {@macro Player.volumeStream}
@riverpod
Stream<double> playerVolume(Ref ref) => ref.read(playerProvider).volumeStream;

/// {@macro Player.isBufferingStream}
@riverpod
Stream<bool> playerIsBuffering(Ref ref) =>
    ref.read(playerProvider).isBufferingStream;

/// {@macro Player.bufferedPositionStream}
@riverpod
Stream<Duration> playerBufferedPosition(Ref ref) =>
    ref.read(playerProvider).bufferedPositionStream;

/// {@macro Player.playlistStream}
@riverpod
Stream<ExtendedPlaylist> playerPlaylist(Ref ref) =>
    ref.read(playerProvider).playlistStream;

/// {@macro Player.queueStream}
@riverpod
Stream<List<ExtendedAudio>> playerQueue(Ref ref) =>
    ref.read(playerProvider).queueStream;

/// {@macro Player.isShufflingStream}
@riverpod
Stream<bool> playerIsShuffling(Ref ref) =>
    ref.read(playerProvider).isShufflingStream;

/// {@macro Player.isRepeatingStream}
@riverpod
Stream<bool> playerIsRepeating(Ref ref) =>
    ref.read(playerProvider).isRepeatingStream;
