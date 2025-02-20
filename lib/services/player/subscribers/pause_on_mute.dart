import "dart:async";

import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для вызова метода [Player.pause], если его громкость равна нулю.
class PauseOnMutePlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("PauseOnMutePlayerSubscriber");

  PauseOnMutePlayerSubscriber(Player player) : super("Pause on mute", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.volumeStream.listen(onVolume),
      player.isPlayingStream.listen(onIsPlaying),
      player.isPauseOnMuteEnabledStream.listen(onIsPauseOnMuteEnabled),
    ];
  }

  /// Указывает, что пауза была вызвана этим подписчиком.
  bool _pausedDueMute = false;

  /// События изменения громкости.
  void onVolume(double volume) async {
    if (!player.isPauseOnMuteEnabled) return;

    if (_pausedDueMute && volume > 0.0) {
      player.play();

      _pausedDueMute = false;
    } else if (volume == 0.0 && player.isPlaying) {
      logger.d("Pausing player due to mute.");
      player.pause();

      _pausedDueMute = true;
    }
  }

  /// События паузы/воспроизведения музыки.
  void onIsPlaying(bool isPlaying) async {
    if (!isPlaying) return;

    _pausedDueMute = false;
  }

  /// События изменения настроек паузы при отключении звука.
  void onIsPauseOnMuteEnabled(bool isEnabled) async {
    if (_pausedDueMute && !isEnabled) {
      player.play();
      _pausedDueMute = false;

      return;
    }

    onVolume(player.volume);
  }
}
