import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:isar/isar.dart";
import "package:path_provider/path_provider.dart";

import "../db/schemas/playlists.dart";
import "../enums.dart";
import "../main.dart" show appStorage;
import "../provider/preferences.dart";
import "../provider/user.dart";
import "audio_player.dart";
import "logger.dart";

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
  Future<List<DBPlaylist>> getPlaylists() async {
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

  /// Удаляет все плейлисты пользователя, заменяя их на новые [playlists].
  Future<void> replaceAllPlaylists(List<DBPlaylist> playlists) async {
    logger.d("Called replaceAllPlaylists for ${playlists.length} playlists");

    final Isar isar = await _getIsar();

    await isar.writeTxn(() async {
      await isar.dBPlaylists.clear();
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

/// Тип для перечисления списка плейлистов.
typedef ListOfPlaylists = List<DBPlaylist>;

/// Тип для метода миграции базы данных Isar.
typedef MigrationMethod = Future<List<DBPlaylist>> Function(List<DBPlaylist>);

/// Класс, прозводящий миграцию базы данных Isar.
///
/// Для получения экземпляра класса используйте [dbMigratorProvider].
class IsarDBMigrator {
  static final AppLogger logger = getLogger("IsarDBMigrator");

  /// Максимальная версия базы данных.
  static const int maxDBVersion = 1;

  /// Возвращает список из всех методов, используемых для миграций БД.
  List<MigrationMethod> get migrationMethods => [
        _migrateV0,
      ];

  /// Возвращает список из методов, используемых для миграций БД, начиная с версии [startVersion].
  List<MigrationMethod> getMigrationMethodsFromVersion(
    int startVersion,
  ) =>
      migrationMethods.sublist(startVersion);

  final Ref _ref;

  IsarDBMigrator({
    required Ref ref,
  }) : _ref = ref {
    assert(
      migrationMethods.length == maxDBVersion,
      "Not all migration methods are implemented. Expected $maxDBVersion, got ${migrationMethods.length}",
    );
  }

  /// Запускает миграцию базы данных Isar.
  ///
  /// При вызове, проверяет текущую версию БД, и если она не равна максимальной ([maxDBVersion]), то начинает миграцию.
  Future<void> performMigration() async {
    logger.d("Called performMigration");

    final preferences = _ref.read(preferencesProvider);
    final preferencesNotifier = _ref.read(preferencesProvider.notifier);

    int currentDBVersion = preferences.dbVersion;

    // Поскольку Flutter VK не делал учёт версии БД в предыдущих версиях,
    // то нам нужно определить то, с какой версии нам нужно начать миграцию.
    //
    // У "новых" пользователей версия БД будет равна maxDBVersion, и это правильно,
    // однако, у "старых" пользователей версия БД будет такой же, и это неправильно.
    //
    // Поэтому, мы должны определить, с какой версии начать миграцию: для этого мы
    // проверяем то, существует ли одна из "старых" папок для хранения кэша треков.
    // Если хотя бы одна из них существует, то начинаем миграцию с версии 0.
    final oldCacheDirs =
        await CachedStreamAudioSource.getOldTrackStorageDirectories();
    if (oldCacheDirs.any((dir) => dir.existsSync())) {
      logger.i(
        "Found old tracks cache directory, starting DB migration from version 0",
      );

      currentDBVersion = 0;
    }

    // Если версия БД равна максимальной, то миграция не требуется.
    if (currentDBVersion == maxDBVersion) {
      logger.d("Database is up-to-date, no migration required");

      return;
    }

    // Производим миграции.
    logger.i(
      "Starting database migration from v$currentDBVersion to v$maxDBVersion...",
    );

    final migrationMethods = getMigrationMethodsFromVersion(currentDBVersion);
    assert(
      migrationMethods.length == maxDBVersion - currentDBVersion,
      "Not all migration methods are implemented. Expected ${maxDBVersion - currentDBVersion}, got ${migrationMethods.length}",
    );
    final Stopwatch migrationTimer = Stopwatch()..start();

    int curMigratedVersion = currentDBVersion;
    List<DBPlaylist> curPlaylists = await appStorage.getPlaylists();
    for (final migrationMethod in migrationMethods) {
      logger.d("Migrating from v$curMigratedVersion...");

      final Stopwatch curMigrationTimer = Stopwatch()..start();
      curPlaylists = await migrationMethod([...curPlaylists]);

      // Миграция для текущей версии завершена.
      // Сохраняем плейлисты и увеличиваем версию БД.
      currentDBVersion++;
      await appStorage.replaceAllPlaylists(curPlaylists);
      preferencesNotifier.setDBVersion(curMigratedVersion + 1);

      curMigrationTimer.stop();
      logger.d(
        "Migration from v$curMigratedVersion completed in ${curMigrationTimer.elapsedMilliseconds}ms",
      );
    }

    // Общая миграция завершена.
    assert(
      currentDBVersion == maxDBVersion,
      "Database migration failed: expected version $maxDBVersion, got $currentDBVersion",
    );

    migrationTimer.stop();
    logger.i(
      "DB migration completed in ${migrationTimer.elapsedMilliseconds}ms to v$currentDBVersion",
    );
  }

  /// Миграция базы данных с версии 0.
  ///
  /// Данная миграция удаляет старый кэш треков, ранее хранившийся в папке `tracks` или `audios`.
  Future<ListOfPlaylists> _migrateV0(ListOfPlaylists playlists) async {
    final int userID = _ref.read(userProvider).id;

    PlaylistType? getPlaylistType(DBPlaylist playlist) {
      if (playlist.id == 0) {
        return PlaylistType.favorites;
      } else if (playlist.id > 0 &&
          playlist.backgroundAnimationUrl == null &&
          ((playlist.isFollowing ?? false) || playlist.ownerID == userID)) {
        return PlaylistType.regular;
      }

      return null;
    }

    // Удаляем старый кэш треков.
    final oldCacheDirs =
        await CachedStreamAudioSource.getOldTrackStorageDirectories();
    for (final dir in oldCacheDirs) {
      try {
        if (!dir.existsSync()) continue;

        await dir.delete(
          recursive: true,
        );
      } catch (error, stackTrace) {
        logger.e(
          "Failed to delete old tracks cache directory (${dir.path}):",
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    // Устанавливаем типы плейлистов.
    //
    // Здесь удаляются все плейлисты, кроме плейлиста "любимые треки" и плейлистов пользователя,
    // а так же поле isCached у всех треков устанавливается в false (поскольку кэш был удалён).
    return playlists
        .where((playlist) => getPlaylistType(playlist) != null)
        .map(
          (item) => item.copyWith(
            type: getPlaylistType(item),
            audios: item.audios
                ?.map(
                  (audio) => audio.copyWith(isCached: false),
                )
                .toList(),
          ),
        )
        .toList();
  }
}
