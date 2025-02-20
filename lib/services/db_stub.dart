import "../provider/user.dart";

/// Stub-версия класса для работы с хранилищем данных, используемая в Web-версии приложения.
class AppStorage {
  // TODO: Логирование вызовов этого класса.

  static const int maxDBVersion = -1;

  AppStorage({required dynamic ref});

  static int fastHash(String input) => 0;

  Future<List<ExtendedPlaylist>> getPlaylists() async => [];

  Future<void> savePlaylist(ExtendedPlaylist playlist) async {}

  Future<void> savePlaylists(List<ExtendedPlaylist> playlists) async {}

  Future<void> replaceAllPlaylists(List<ExtendedPlaylist> playlists) async {}

  Future<void> resetDB() async {}

  Future<List<Map<String, dynamic>>> exportAsJSON() async => [];

  Future<void> importFromJSON(List<Map<String, dynamic>> json) async {}

  Future<void> migrate() async {}
}
