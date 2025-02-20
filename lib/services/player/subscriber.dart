import "dart:async";

import "../logger.dart";
import "player.dart";

/// Класс, репрезентирующий подписчика на события [Player].
class PlayerSubscriber {
  static final AppLogger logger = getLogger("PlayerSubscriber");

  /// Название для этого [PlayerSubscriber].
  final String name;

  /// Объект [Player]'а, который можно использовать для подписки на события.
  final Player player;

  PlayerSubscriber(
    this.name,
    this.player,
  );

  /// Инициализирует данного [PlayerSubscriber].
  Future<void> initialize() async {
    // No-op.
  }

  Future<void> dispose() async {
    // No-op.
  }

  /// Возвращает список из всех [StreamSubscription] подписок, необходимых для работы этого [PlayerSubscriber].
  List<StreamSubscription> subscribe(Player player) =>
      throw UnimplementedError();
}
