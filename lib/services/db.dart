import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:isar/isar.dart";
import "package:path_provider/path_provider.dart";

import "../../enums.dart";
import "../../provider/user.dart";
import "../provider/preferences.dart";
import "../schema/playlists.dart";
import "logger.dart";
import "player/server.dart";

/// Тип для перечисления списка плейлистов.
typedef ListOfPlaylists = List<DBPlaylist>;

/// Тип для метода миграции базы данных Isar.
typedef MigrationMethod = Future<List<DBPlaylist>> Function(List<DBPlaylist>);

/// Класс для работы с базой данных Isar, используемого для хранения persistent-данных пользователя.
class AppStorage {
  static final AppLogger logger = getLogger("AppStorage");

  /// Название файла базы данных Isar.
  static const String isarDBName = "flutter-vk";

  /// Максимальная версия базы данных.
  static const int maxDBVersion = 1;

  String? _dbDirectoryPath;

  Isar? _isar;

  final Ref ref;

  AppStorage({required this.ref}) {
    if (migrationMethods.length != maxDBVersion) {
      throw Exception(
        "Not all migration methods are implemented. Expected $maxDBVersion, got ${migrationMethods.length}",
      );
    }
  }

  /// Возвращает список из всех методов, используемых для миграций БД.
  List<MigrationMethod> get migrationMethods => [
        _migrateV0,
      ];

  /// Возвращает список из методов, используемых для миграций БД, начиная с версии [startVersion].
  List<MigrationMethod> getMigrationMethodsFromVersion(
    int startVersion,
  ) =>
      migrationMethods.sublist(startVersion);

  /// 64-битный FNV-1a алгоритм для хэширования [String] в виде [int].
  ///
  /// Используется как поле ID в БД Isar.
  ///
  /// [Взято из документации Isar](https://isar.dev/recipes/string_ids.html#fast-hash-function).
  static int fastHash(String input) {
    var hash = 0xcbf29ce484222325;

    var i = 0;
    while (i < input.length) {
      final codeUnit = input.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }

    return hash;
  }

  /// Возвращает путь к папке, в которой будут храниться файлы баз данных Isar.
  Future<String> getDBDirectoryPath() async {
    _dbDirectoryPath ??= (await getApplicationSupportDirectory()).path;

    return _dbDirectoryPath!;
  }

  /// Возвращает объект базы данных Isar.
  Future<Isar> _getIsar() async {
    _isar ??= await Isar.open(
      [DBPlaylistSchema],
      name: isarDBName,
      directory: await getDBDirectoryPath(),
    );

    return _isar!;
  }

  /// Возвращает список всех плейлистов пользователя в формате [DBPlaylist].
  ///
  /// Вероятнее всего, вам нужен метод [getPlaylists].
  Future<List<DBPlaylist>> getDBPlaylists() async {
    final Isar isar = await _getIsar();

    return await isar.dBPlaylists
        .where(
          sort: Sort.desc,
        )
        .anyIsarId()
        .findAll();
  }

  /// Возвращает список из всех плейлистов пользователя.
  Future<List<ExtendedPlaylist>> getPlaylists() async {
    final List<DBPlaylist> dbPlaylists = await getDBPlaylists();

    return dbPlaylists
        .map(
          (DBPlaylist playlist) => DBPlaylist.toExtended(playlist),
        )
        .toList();
  }

  /// Сохраняет единственный плейлист пользователя в БД.
  ///
  /// Если Вам нужно сохранить множество плейлистов за раз, то воспользуйтесь методом [savePlaylists].
  Future<void> savePlaylist(ExtendedPlaylist playlist) async {
    logger.d("Called savePlaylist for $playlist");

    final Isar isar = await _getIsar();

    await isar.writeTxn(() async {
      await isar.dBPlaylists.put(
        DBPlaylist.fromExtended(playlist),
      );
    });
  }

  /// Сохраняет список из плейлистов пользователя в БД.
  ///
  /// Отличие этого метода от [savePlaylist] в том, что он массово сохраняет сразу много плейлистов, что может быть быстрее, нежели использование `for`-цикла с [savePlaylist].
  Future<void> savePlaylists(List<ExtendedPlaylist> playlists) async {
    logger.d("Called savePlaylist for ${playlists.length} playlists");

    final Isar isar = await _getIsar();

    await isar.writeTxn(() async {
      await isar.dBPlaylists.putAll(
        playlists
            .map(
              (playlist) => DBPlaylist.fromExtended(playlist),
            )
            .toList(),
      );
    });
  }

  /// Удаляет все плейлисты пользователя, заменяя их на новые [playlists].
  Future<void> replaceAllPlaylists(List<ExtendedPlaylist> playlists) async {
    await replaceAllDBPlaylists(
      playlists
          .map(
            (playlist) => DBPlaylist.fromExtended(playlist),
          )
          .toList(),
    );
  }

  /// Удаляет все плейлисты пользователя, заменяя их на новые [playlists].
  Future<void> replaceAllDBPlaylists(List<DBPlaylist> playlists) async {
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

  /// Запускает миграцию базы данных Isar.
  ///
  /// При вызове, проверяет текущую версию БД, и если она не равна максимальной ([maxDBVersion]), то начинает миграцию.
  Future<void> migrate() async {
    logger.d("Called migrate");

    final preferences = ref.read(preferencesProvider);
    final preferencesNotifier = ref.read(preferencesProvider.notifier);

    Future<void> resetDB() async {
      logger.i("Resetting database...");

      await resetDB();
      preferencesNotifier.setDBVersion(maxDBVersion);
    }

    int currentDBVersion = preferences.dbVersion;
    try {
      // Если версия БД больше максимальной, то это значит, что пользователь запустил
      // старую версию Flutter VK при новой версии БД. В таком случае, нам нужно
      // полностью сбросить БД, что бы предотвратить возможные ошибки.
      if (currentDBVersion > maxDBVersion) {
        logger.w(
          "DB version ($currentDBVersion) is greater than supported version ($maxDBVersion), resetting DB",
        );

        await resetDB();
        currentDBVersion = maxDBVersion;
      }

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
          await PlayerLocalServer.getOldTrackStorageDirectories();
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
      if (migrationMethods.length != maxDBVersion - currentDBVersion) {
        throw Exception(
          "Not all migration methods are implemented. Expected ${maxDBVersion - currentDBVersion}, got ${migrationMethods.length}",
        );
      }
      final Stopwatch migrationTimer = Stopwatch()..start();

      int curMigratedVersion = currentDBVersion;
      List<DBPlaylist> curPlaylists = await getDBPlaylists();
      for (final migrationMethod in migrationMethods) {
        logger.d("Migrating from v$curMigratedVersion...");

        final Stopwatch curMigrationTimer = Stopwatch()..start();
        curPlaylists = await migrationMethod([...curPlaylists]);

        // Миграция для текущей версии завершена.
        // Сохраняем плейлисты и увеличиваем версию БД.
        currentDBVersion++;
        await replaceAllDBPlaylists(curPlaylists);
        preferencesNotifier.setDBVersion(curMigratedVersion + 1);

        curMigrationTimer.stop();
        logger.d(
          "Migration from v$curMigratedVersion completed in ${curMigrationTimer.elapsedMilliseconds}ms",
        );
      }

      // Общая миграция завершена.
      if (currentDBVersion != maxDBVersion) {
        throw Exception(
          "Database migration failed: expected version $maxDBVersion, got $currentDBVersion",
        );
      }

      migrationTimer.stop();
      logger.i(
        "DB migration completed in ${migrationTimer.elapsedMilliseconds}ms to v$currentDBVersion",
      );
    } catch (error, stackTrace) {
      logger.e(
        "Failed to perform migration from v$currentDBVersion to $maxDBVersion.",
        error: error,
        stackTrace: stackTrace,
      );

      // Сбрасываем БД.
      currentDBVersion = maxDBVersion;
      await resetDB();
    }
  }

  /// Миграция базы данных с версии 0.
  ///
  /// Данная миграция удаляет старый кэш треков, ранее хранившийся в папке `tracks` или `audios`.
  Future<ListOfPlaylists> _migrateV0(ListOfPlaylists playlists) async {
    final int userID = ref.read(userProvider).id;

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
        await PlayerLocalServer.getOldTrackStorageDirectories();
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
                  (audio) => audio.copyWith(
                    isCached: false,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }
}
