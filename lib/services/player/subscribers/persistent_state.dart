import "dart:async";

import "../../../provider/preferences.dart";
import "../../../utils.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для обработки некоторых полей [Player]'а, с последующим сохранением их в [SharedPreferences].
class PersistentStatePlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("PersistentStatePlayerSubscriber");

  /// Время, через которое после изменения громкости плеера это изменение будет сохранено на диск.
  static const Duration volumeSaveDelay = Duration(seconds: 2);

  PersistentStatePlayerSubscriber(Player player)
      : super("Persistent state", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.isShufflingStream.listen(onIsShuffling),
      player.isRepeatingStream.listen(onIsRepeating),
      player.volumeStream.listen(onVolume),
    ];
  }

  /// Возвращает объект [Preferences] для сохранения настроек.
  Preferences get _prefs => player.ref.read(preferencesProvider.notifier);

  /// Таймер по сохранению громкости.
  Timer? _volumeSaveTimer;

  /// События изменения режима перемешивания треков.
  void onIsShuffling(bool isShuffling) async {
    _prefs.setShuffleEnabled(isShuffling);
  }

  /// События изменения режима повторения треков.
  void onIsRepeating(bool isRepeating) async {
    _prefs.setLoopModeEnabled(isRepeating);
  }

  /// События изменения громкости.
  void onVolume(double volume) async {
    if (!isDesktop) return;

    _volumeSaveTimer?.cancel();
    _volumeSaveTimer = Timer(volumeSaveDelay, () {
      _prefs.setVolume(volume);
    });
  }
}
