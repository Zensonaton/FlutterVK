import "dart:async";

import "package:smtc_windows/smtc_windows.dart";

import "../../../provider/user.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для обработки SMTC.
class SMTCPlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("SMTCPlayerSubscriber");

  /// Длительность, передаваемая в [Player.seekBy] при нажатии на кнопку перемотки.
  static const Duration seekDuration = Duration(seconds: 10);

  SMTCPlayerSubscriber(Player player) : super("SMTC", player);

  /// Объект SMTC для обработки событий SMTC.
  late final SMTCWindows _smtc;

  @override
  Future<void> initialize() async {
    _smtc = SMTCWindows(
      config: const SMTCConfig(
        prevEnabled: true,
        pauseEnabled: true,
        playEnabled: true,
        nextEnabled: true,
        stopEnabled: true,
        fastForwardEnabled: true,
        rewindEnabled: true,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _smtc.disableSmtc();
    await _smtc.dispose();
  }

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.isLoadedStream.listen(onIsLoaded),
      player.isPlayingStream.listen(onIsPlaying),
      player.isBufferingStream.listen(onIsBuffering),
      player.isShufflingStream.listen(onIsShuffling),
      player.isRepeatingStream.listen(onIsRepeating),
      player.positionStream.listen(onPosition),
      player.audioStream.listen(onAudio),

      // События SMTC.
      _smtc.buttonPressStream.listen(onSMTCButtonPress),
    ];
  }

  /// События запуска плеера.
  void onIsLoaded(bool isLoaded) async {
    if (isLoaded) {
      await _smtc.enableSmtc();

      return;
    }

    await _smtc.disableSmtc();
  }

  /// События паузы/воспроизведения музыки.
  void onIsPlaying(bool isPlaying) async {
    updatePlaybackStatus();
  }

  /// События буфферизации музыки.
  void onIsBuffering(bool isBuffering) async {
    updatePlaybackStatus();
  }

  /// Обновляет отображаемый статус воспроизведения музыки.
  void updatePlaybackStatus() async {
    PlaybackStatus status = PlaybackStatus.Paused;

    if (player.isBuffering) {
      status = PlaybackStatus.Changing;
    } else if (player.isPlaying) {
      status = PlaybackStatus.Playing;
    }

    await _smtc.setPlaybackStatus(status);
  }

  /// События изменения режима перемешивания треков.
  void onIsShuffling(bool isShuffling) async {
    await _smtc.setShuffleEnabled(isShuffling);
  }

  /// События изменения режима повторения треков.
  void onIsRepeating(bool isRepeating) async {
    await _smtc.setRepeatMode(
      isRepeating ? RepeatMode.track : RepeatMode.none,
    );
  }

  /// События изменения позиции трека.
  void onPosition(Duration position) async {
    await _smtc.setPosition(position);
  }

  /// События изменения трека, играющий в данный момент.
  void onAudio(ExtendedAudio audio) async {
    await _smtc.updateMetadata(
      MusicMetadata(
        title: audio.fullTitle(),
        artist: audio.artist,
        albumArtist: audio.artist,
        album: audio.album?.title,
        thumbnail: audio.maxThumbnail,
      ),
    );
    await _smtc.setEndTime(
      Duration(
        seconds: audio.duration,
      ),
    );
  }

  /// События SMTC.
  void onSMTCButtonPress(PressedButton button) async {
    switch (button) {
      case PressedButton.next:
        await player.next();

        break;
      case PressedButton.play:
        await player.play();

        break;
      case PressedButton.pause:
        await player.pause();

        break;
      case PressedButton.previous:
        await player.smartPrevious(viaNotification: true);

        break;
      case PressedButton.stop:
        await player.stop();

        break;
      case PressedButton.fastForward:
        await player.seekBy(seekDuration);

        break;
      case PressedButton.rewind:
        await player.seekBy(seekDuration * -1);

        break;
      default:
        logger.w("Unknown button: $button");

        break;
    }
  }
}
