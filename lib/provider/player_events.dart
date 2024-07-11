import "package:just_audio/just_audio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../main.dart";
import "user.dart";

part "player_events.g.dart";

/// [Provider] для получения значения [VKMusicPlayer.loadedStateStream].
///
/// {@macro VKMusicPlayer.loadedStateStream}
@riverpod
Stream<bool> playerLoadedState(PlayerLoadedStateRef ref) =>
    player.loadedStateStream;

/// [Provider] для получения значения [VKMusicPlayer.playlistModificationsStream].
///
/// {@macro VKMusicPlayer.playlistModificationsStream}
@riverpod
Stream<ExtendedPlaylist> playerPlaylistModifications(
  PlayerPlaylistModificationsRef ref,
) =>
    player.playlistModificationsStream;

/// [Provider] для получения значения [VKMusicPlayer.seekStateStream].
///
/// {@macro VKMusicPlayer.seekStateStream}
@riverpod
Stream<Duration> playerSeekState(PlayerSeekStateRef ref) =>
    player.seekStateStream;

/// [Provider] для получения значения [VKMusicPlayer.playingStream].
///
/// {@macro VKMusicPlayer.playingStream}
@riverpod
Stream<bool> playerPlayingState(PlayerPlayingStateRef ref) =>
    player.playingStream;

/// [Provider] для получения значения [VKMusicPlayer.bufferedPositionStream].
///
/// {@macro VKMusicPlayer.bufferedPositionStream}
@riverpod
Stream<Duration> playerBufferedPosition(PlayerBufferedPositionRef ref) =>
    player.bufferedPositionStream;

/// [Provider] для получения значения [VKMusicPlayer.volumeStream].
///
/// {@macro VKMusicPlayer.volumeStream}
@riverpod
Stream<double> playerVolume(PlayerVolumeRef ref) => player.volumeStream;

/// [Provider] для получения значения [VKMusicPlayer.positionStream].
///
/// {@macro VKMusicPlayer.positionStream}
@riverpod
Stream<Duration> playerPosition(PlayerPositionRef ref) => player.positionStream;

/// [Provider] для получения значения [VKMusicPlayer.durationStream].
///
/// {@macro VKMusicPlayer.durationStream}
@riverpod
Stream<Duration?> playerDuration(PlayerDurationRef ref) =>
    player.durationStream;

/// [Provider] для получения значения [VKMusicPlayer.playerStateStream].
///
/// {@macro VKMusicPlayer.playerStateStream}
@riverpod
Stream<PlayerState> playerState(PlayerStateRef ref) => player.playerStateStream;

/// [Provider] для получения значения [VKMusicPlayer.sequenceStateStream].
///
/// {@macro VKMusicPlayer.sequenceStateStream}
@riverpod
Stream<SequenceState?> playerSequenceState(PlayerSequenceStateRef ref) =>
    player.sequenceStateStream;

/// [Provider] для получения значения [VKMusicPlayer.currentIndexStream].
///
/// {@macro VKMusicPlayer.currentIndexStream}
@riverpod
Stream<int?> playerCurrentIndex(PlayerCurrentIndexRef ref) =>
    player.currentIndexStream;

/// [Provider] для получения значения [VKMusicPlayer.shuffleModeEnabledStream].
///
/// {@macro VKMusicPlayer.shuffleModeEnabledStream}
@riverpod
Stream<bool> playerShuffleModeEnabled(PlayerShuffleModeEnabledRef ref) =>
    player.shuffleModeEnabledStream;

/// [Provider] для получения значения [VKMusicPlayer.loopModeStream].
///
/// {@macro VKMusicPlayer.loopModeStream}
@riverpod
Stream<LoopMode> playerLoopMode(PlayerLoopModeRef ref) => player.loopModeStream;
