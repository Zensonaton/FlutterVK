import "dart:async";

import "../../../main.dart";
import "../../../provider/user.dart";
import "../../../provider/vk_api.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для трансляции текущей аудиозаписи в статус текущего пользователя.
class StatusBroadcastPlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("StatusBroadcastPlayerSubscriber");

  StatusBroadcastPlayerSubscriber(Player player)
      : super("Status broadcast", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.isLoadedStream.listen(onIsLoaded),
      player.audioStream.listen(onAudio),
      player.isStatusBroadcastEnabledStream.listen(onIsStatusBroadcastEnabled),
    ];
  }

  /// Указывает, что этим подписчиком был установлен статус.
  bool _isStatusSet = false;

  /// События запуска плеера.
  void onIsLoaded(bool isLoaded) async {
    updatePlaybackStatus();
  }

  /// События изменения трека, играющий в данный момент.
  void onAudio(ExtendedAudio audio) async {
    updatePlaybackStatus();
  }

  /// События изменения состояния включения настройки трансляции статуса.
  void onIsStatusBroadcastEnabled(bool isEnabled) async {
    onIsLoaded(isEnabled);
  }

  /// Обновляет отображаемый статус воспроизведения музыки.
  void updatePlaybackStatus() async {
    if (!connectivityManager.hasConnection) return;

    final api = player.ref.read(vkAPIProvider);
    final audio = player.audio;

    final isEnabled = player.isStatusBroadcastEnabled && player.isLoaded;
    if (!isEnabled && !_isStatusSet) return;

    try {
      await api.audio.setBroadcast(
        isEnabled ? audio!.mediaKey : null,
      );

      _isStatusSet = isEnabled;
    } catch (error, stackTrace) {
      logger.w(
        "Couldn't set broadcast status: ",
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
