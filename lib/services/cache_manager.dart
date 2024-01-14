// ignore_for_file: implementation_imports

import "dart:io";

import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:flutter_cache_manager/src/storage/file_system/file_system_io.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:file/src/backends/local/local_file_system.dart";
import "package:file/src/interface/file.dart";

/// Расширение класса [IOFileSystem] с целью изменения папки для хранения файлов.
class IOCacheManagerExtended extends IOFileSystem {
  final String _cacheKey;
  final bool allowStoreInAppDir;

  IOCacheManagerExtended(
    super.cacheKey, {
    this.allowStoreInAppDir = true,
  }) : _cacheKey = cacheKey;

  @override
  Future<File> createFile(String name) async {
    final baseDir = (allowStoreInAppDir && Platform.isWindows)
        ? await getApplicationSupportDirectory()
        : await getApplicationCacheDirectory();
    final path = join(
      baseDir.path,
      _cacheKey,
    );

    const fs = LocalFileSystem();
    final directory = fs.directory(path);
    await directory.create(recursive: true);

    return directory.childFile(name);
  }
}

/// Класс типа [CacheManager], который выполняет работу по кэшированию треков из ВКонтакте.
class VKMusicCacheManager {
  static const String key = "tracks";

  static CacheManager instance = CacheManager(
    Config(
      key,
      repo: JsonCacheInfoRepository(
        databaseName: key,
      ),
      fileSystem: IOCacheManagerExtended(
        key,
      ),
      fileService: HttpFileService(),
      maxNrOfCacheObjects: 50000,
    ),
  );
}

/// Класс типа [CacheManager], который используется в [CachedNetworkImage].
class CachedNetworkImagesManager {
  static const String key = "images";

  static CacheManager instance = CacheManager(
    Config(
      key,
      repo: JsonCacheInfoRepository(
        databaseName: key,
      ),
      fileSystem: IOCacheManagerExtended(
        key,
      ),
      fileService: HttpFileService(),
    ),
  );
}
