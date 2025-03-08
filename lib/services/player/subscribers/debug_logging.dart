import "dart:async";

import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для debug-логирования событий плеера, если пользователь включил для этого подходящую настройку.
class DebugLoggerPlayerSubscriber extends PlayerSubscriber {
  DebugLoggerPlayerSubscriber(Player player) : super("Debug logger", player);

  /// Возвращает объект [AppLogger] для указанного [sender].
  AppLogger _getLogger(String? sender) {
    if (sender == null) {
      return getLogger("Player");
    }

    return getLogger("Player/$sender");
  }

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.logStream.listen(onLog),
    ];
  }

  /// События логирования плеера.
  void onLog(PlayerLog log) {
    if (!player.isDebugLoggingEnabled) return;

    final AppLogger logger = _getLogger(log.sender);

    switch (log.level) {
      case PlayerLogLevel.verbose:
      case PlayerLogLevel.debug:
      case PlayerLogLevel.info:
        logger.i(log.text);

        break;
      case PlayerLogLevel.warning:
        logger.w(log.text);

        break;
      case PlayerLogLevel.error:
        logger.e(log.text);

        break;
    }
  }
}
