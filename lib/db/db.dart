import "package:isar/isar.dart";
import "package:path_provider/path_provider.dart";

import "../services/logger.dart";
import "schemas/playlists.dart";

/// Класс для работы с базой данных Isar, используемого для хранения persistent-данных пользователя.
class AppStorage {
  static final AppLogger logger = getLogger("AppStorage");

  /// Название файла базы данных Isar.
  static String isarDBName = "flutter-vk";

  String? _dbDirectoryPath;

  Isar? _isar;

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
  ///
  /// Если Вам нужно сохранить множество плейлистов за раз, то воспользуйтесь методом [savePlaylists].
  Future<void> savePlaylist(DBPlaylist playlist) async {
    logger.d("Called savePlaylist for $playlist");

    final Isar isar = await _getIsar();

    await isar.writeTxn(() async {
      await isar.dBPlaylists.put(playlist);
    });
  }

  /// Сохраняет список из плейлистов пользователя в БД.
  ///
  /// Отличие этого метода от [savePlaylist] в том, что он массово сохраняет сразу много плейлистов, что может быть быстрее, нежели использование `for`-цикла с [savePlaylist].
  Future<void> savePlaylists(List<DBPlaylist> playlists) async {
    logger.d("Called savePlaylist for ${playlists.length} playlists");

    final Isar isar = await _getIsar();

    await isar.writeTxn(() async {
      await isar.dBPlaylists.putAll(playlists);
    });
  }

  /// Удаляет все данные, хранимые в БД.
  Future<void> resetDB() async {
    final Isar isar = await _getIsar();

    await isar.close(
      deleteFromDisk: true,
    );
    _isar = null;
  }

  /// Возвращает все записи из БД в виде JSON-объекта.
  Future<List<Map<String, dynamic>>> exportAsJSON() async {
    final Isar isar = await _getIsar();

    return await isar.dBPlaylists.where().exportJson();
  }

  /// Импортирует содержимое как JSON-объект, ранее экспортированного при помощи метода [exportAsJSON].
  ///
  /// Учтите, что используя этот метод, содержимое БД удаляется.
  Future<void> importFromJSON(List<Map<String, dynamic>> json) async {
    final Isar isar = await _getIsar();

    await isar.writeTxn(() async {
      await isar.dBPlaylists.clear();
      await isar.dBPlaylists.importJson(json);
    });
  }
}
