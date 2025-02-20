import "dart:async";

import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для обработки события паузы плеера, чтобы вызвать метод [Player.stop] если пауза длится долго.
class StopOnLongPausePlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("StopOnLongPausePlayerSubscriber");

  /// Время, через которое после паузы плеер будет остановлен ([Player.stop]).
  static const Duration stopTimerDuration = Duration(minutes: 10);

  StopOnLongPausePlayerSubscriber(Player player)
      : super("Stop on long pause", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.isPlayingStream.listen(onIsPlaying),
      player.isStopOnLongPauseEnabledStream.listen(onIsStopOnLongPauseEnabled),
    ];
  }

  /// Таймер, по истечению которого плеер будет остановлен методом [Player.stop].
  Timer? _pauseTimer;

  /// События паузы/воспроизведения музыки.
  void onIsPlaying(bool isPlaying) async {
    _pauseTimer?.cancel();
    if (isPlaying || !player.isStopOnLongPauseEnabled) return;

    _pauseTimer = Timer(
      stopTimerDuration,
      () {
        logger.d("Force-stopping player due to long pause");

        player.stop();
      },
    );
  }

  /// События изменения настройки [Player.isStopOnLongPauseEnabled].
  void onIsStopOnLongPauseEnabled(bool isEnabled) async {
    onIsPlaying(player.isPlaying);
  }
}
