import "dart:async";

import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для debug-логирования событий плеера, если пользователь включил для этого подходящую настройку.
class DebugLoggerPlayerSubscriber extends PlayerSubscriber {
  /// Список из возможных [AppLogger]'ов, в зависимости от уровня логирования.
  static final Map<PlayerLogLevel, AppLogger> loggers = {
    PlayerLogLevel.verbose: getLogger("PlayerL/v"),
    PlayerLogLevel.debug: getLogger("PlayerL/d"),
    PlayerLogLevel.info: getLogger("PlayerL/i"),
    PlayerLogLevel.warning: getLogger("PlayerL/w"),
    PlayerLogLevel.error: getLogger("PlayerL/e"),
  };
  // TODO: Использование AppLogger'овского вместо уровня лога.

  DebugLoggerPlayerSubscriber(Player player) : super("Debug logger", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.logStream.listen(onLog),
    ];
  }

  void onLog(PlayerLog log) {
    if (!player.isDebugLoggingEnabled) return;

    final AppLogger logger = loggers[log.level]!;

    if (log.sender != null) {
      logger.i("${log.sender}: ${log.text}");

      return;
    }

    logger.i(log.text);
  }
}
