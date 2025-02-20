import "dart:async";

import "../player.dart";
import "../subscriber.dart";

/// Stub-версия класса для [SMTCPlayerSubscriber] для неподдерживаемых платформ (Android, web, ...).
class SMTCPlayerSubscriber extends PlayerSubscriber {
  SMTCPlayerSubscriber(Player player) : super("SMTC (stub)", player);

  @override
  List<StreamSubscription> subscribe(Player player) => [];
}
