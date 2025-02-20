import "dart:async";

import "../player.dart";
import "../subscriber.dart";

/// Stub-версия класса для [DiscordRPCPlayerSubscriber] для неподдерживаемых платформ (Android, web, ...).
class DiscordRPCPlayerSubscriber extends PlayerSubscriber {
  DiscordRPCPlayerSubscriber(Player player)
      : super(
          "Discord RPC (stub)",
          player,
        );

  @override
  List<StreamSubscription> subscribe(Player player) => [];
}
