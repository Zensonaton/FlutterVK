import "dart:async";

import "../../../provider/user.dart";
import "../../../utils.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для отображения названия трека в окне, если включена сопутствующая настройка.
class WindowBarTitlePlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("WindowBarTitlePlayerSubscriber");

  WindowBarTitlePlayerSubscriber(Player player)
      : super("Window bar title", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.isLoadedStream.listen(onIsLoaded),
      player.isPlayingStream.listen(onIsPlaying),
      player.audioStream.listen(onAudio),
      player.trackTitleInWindowBarEnabledStream
          .listen(onTrackTitleInWindowBarEnabled),
    ];
  }

  /// События запуска плеера.
  void onIsLoaded(bool isLoaded) async {
    updatePlaybackStatus();
  }

  /// События паузы/воспроизведения музыки.
  void onIsPlaying(bool isPlaying) async {
    updatePlaybackStatus();
  }

  /// События изменения трека, играющий в данный момент.
  void onAudio(ExtendedAudio audio) async {
    updatePlaybackStatus();
  }

  /// События изменения настройки отображения названия трека в окне.
  void onTrackTitleInWindowBarEnabled(bool enabled) async {
    updatePlaybackStatus();
  }

  /// Обновляет отображаемый статус воспроизведения музыки.
  void updatePlaybackStatus() async {
    final audio = player.audio;
    final enabled = player.trackTitleInWindowBarEnabled;
    if (audio == null || !enabled) {
      await setWindowTitle();

      return;
    }

    String title = audio.title;
    if (audio.subtitle != null) {
      title += " (${audio.subtitle})";
    }
    title += " - ${audio.artist}";

    setWindowTitle(title: title);
  }
}
