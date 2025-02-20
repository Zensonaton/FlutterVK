import "dart:async";

import "../../../main.dart";
import "../../../provider/user.dart";
import "../../../provider/vk_api.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для оповещения серверов ВКонтакте о том, какой трек прослушивается сейчас, чтобы рекомендации учитывали это.
class RecommendationsNotifierPlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger =
      getLogger("RecommendationsNotifierPlayerSubscriber");

  RecommendationsNotifierPlayerSubscriber(Player player)
      : super("Recommendations notifier", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.audioStream.listen(onAudio),
    ];
  }

  /// События изменения трека, играющий в данный момент.
  void onAudio(ExtendedAudio audio) async {
    final api = player.ref.read(vkAPIProvider);

    if (player.playlist?.isRecommendationTypePlaylist != true) return;
    if (!connectivityManager.hasConnection) return;

    // TODO: Сделать настройку, чтобы выключить это поведение.

    try {
      await api.audio.sendStartEvent(player.audio!.mediaKey);
    } catch (error, stackTrace) {
      logger.w(
        "Couldn't notify VK about track listening state: ",
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
