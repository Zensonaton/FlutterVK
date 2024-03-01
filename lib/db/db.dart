import "package:isar/isar.dart";
import "package:path_provider/path_provider.dart";

import "schemas/playlists.dart";

/// Класс для работы с базой данных Isar, используемого для хранения persistent-данных пользователя.
class AppStorage {
  String? _dbDirectoryPath;

  Isar? _isar;

  /// Название файла базы данных Isar.
  static String isarDBName = "flutter-vk";

  /// Возвращает путь к папке, в которой будут храниться файлы баз данных Isar.
  Future<String> getDBDirectoryPath() async {
    _dbDirectoryPath ??= (await getApplicationSupportDirectory()).path;

    return _dbDirectoryPath!;
  }

  /// Возвращает объект базы данных Isar.
  Future<Isar> _getIsar() async {
    _isar ??= await Isar.open(
      [DBPlaylistSchema],
      directory: await getDBDirectoryPath(),
      name: isarDBName,
    );

    return _isar!;
  }

  /// Возвращает список из всех плейлистов пользователя.
  Future<List<DBPlaylist?>> getPlaylists() async {
    final Isar isar = await _getIsar();

    return await isar.dBPlaylists
        .where(
          sort: Sort.desc,
        )
        .anyIsarId()
        .findAll();
  }

  /// Сохраняет единственный плейлист пользователя в БД.
  Future<void> savePlaylist(
    DBPlaylist playlist,
  ) async {
    final Isar isar = await _getIsar();

    await isar.writeTxn(() async {
      await isar.dBPlaylists.put(playlist);
    });
  }

  /// Сохраняет список из плейлистов пользователя в БД.
  Future<void> savePlaylists(
    List<DBPlaylist> playlists,
  ) async {
    final Isar isar = await _getIsar();

    await isar.writeTxn(() async {
      await isar.dBPlaylists.putAll(playlists);
    });
  }
}
