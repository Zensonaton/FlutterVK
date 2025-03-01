import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../enums.dart";
import "../services/player/player.dart";
import "user.dart";

part "player.g.dart";

/// Метод для получения объекта [Player] для воспроизведения музыки.
Player _(Ref ref) => ref.read(playerProvider);

/// [Provider] для получения объекта [Player] для воспроизведения музыки.
@Riverpod(keepAlive: true)
Player player(Ref ref) => Player(ref);

/// {@macro Player.isLoadedStream}
@riverpod
Stream<bool> playerIsLoaded(Ref ref) => _(ref).isLoadedStream;

/// {@macro Player.isPlayingStream}
@riverpod
Stream<bool> playerIsPlaying(Ref ref) => _(ref).isPlayingStream;

/// {@macro Player.audioStream}
@riverpod
Stream<ExtendedAudio> playerAudio(Ref ref) => _(ref).audioStream;

/// {@macro Player.positionStream}
@riverpod
Stream<Duration> playerPosition(Ref ref) => _(ref).positionStream;

/// {@macro Player.seekStream}
@riverpod
Stream<Duration> playerSeek(Ref ref) => _(ref).seekStream;

/// {@macro Player.volumeStream}
@riverpod
Stream<double> playerVolume(Ref ref) => _(ref).volumeStream;

/// {@macro Player.isBufferingStream}
@riverpod
Stream<bool> playerIsBuffering(Ref ref) => _(ref).isBufferingStream;

/// {@macro Player.bufferedPositionStream}
@riverpod
Stream<Duration> playerBufferedPosition(Ref ref) =>
    _(ref).bufferedPositionStream;

/// {@macro Player.playlistStream}
@riverpod
Stream<ExtendedPlaylist> playerPlaylist(Ref ref) => _(ref).playlistStream;

/// {@macro Player.queueStream}
@riverpod
Stream<List<ExtendedAudio>> playerQueue(Ref ref) => _(ref).queueStream;

/// {@macro Player.isShufflingStream}
@riverpod
Stream<bool> playerIsShuffling(Ref ref) => _(ref).isShufflingStream;

/// {@macro Player.isRepeatingStream}
@riverpod
Stream<bool> playerIsRepeating(Ref ref) => _(ref).isRepeatingStream;

/// {@macro Player.logStream}
@riverpod
Stream<PlayerLog> playerLog(Ref ref) => _(ref).logStream;

/// {@macro Player.errorStream}
@riverpod
Stream<String> playerError(Ref ref) => _(ref).errorStream;

/// {@macro Player.volumeNormalizationStream}
@riverpod
Stream<VolumeNormalization> playerVolumeNormalization(Ref ref) =>
    _(ref).volumeNormalizationStream;

/// {@macro Player.silenceRemovalEnabledStream}
@riverpod
Stream<bool> playerSilenceRemovalEnabled(Ref ref) =>
    _(ref).silenceRemovalEnabledStream;
