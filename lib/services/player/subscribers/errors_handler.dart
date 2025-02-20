import "dart:async";

import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для обработки событий ошибок.
class ErrorsHandlerPlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("ErrorsHandlerPlayerSubscriber");

  ErrorsHandlerPlayerSubscriber(Player player)
      : super("Errors handler", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.errorStream.listen(onError),
    ];
  }

  void onError(String message) {
    // TODO: Отобразить в интерфейсе.
    // TODO: Остановить плеер.

    logger.e(message);
  }
}
