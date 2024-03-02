// ignore_for_file: implementation_imports

import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:flutter_cache_manager/src/storage/file_system/file_system_io.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:file/src/backends/local/local_file_system.dart";
import "package:file/src/interface/file.dart";

import "../utils.dart";

/// Расширение класса [IOFileSystem] с целью изменения папки для хранения файлов.
class IOCacheManagerExtended extends IOFileSystem {
  /// Название папки, в которой будет храниться содержимое кэшированных файлов.
  final String _cacheKey;

  /// Указывает, что для файлов кэша будет использоваться [getApplicationCacheDirectory] вместо [getApplicationSupportDirectory].
  final bool storeInCacheDirectory;

  IOCacheManagerExtended(
    super.cacheKey, {
    this.storeInCacheDirectory = true,
  }) : _cacheKey = cacheKey;

  @override
  Future<File> createFile(String name) async {
    final baseDir = storeInCacheDirectory
        ? await getApplicationCacheDirectory()
        : await getApplicationSupportDirectory();

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

/// Класс типа [CacheManager], который используется в [CachedNetworkImage].
///
/// Этот [CacheManager] используется для хранения обычных изображений. Для изображений треков используется [CachedAlbumImagesManager].
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
        storeInCacheDirectory: isMobile,
      ),
      fileService: HttpFileService(),
      maxNrOfCacheObjects: 100,
    ),
  );
}

/// Класс типа [CacheManager], который используется в [CachedNetworkImage].
///
/// Этот [CacheManager] используется для изображений треков. Для обычных изображений используется [CachedNetworkImagesManager].
class CachedAlbumImagesManager {
  static const String key = "album-images";

  static CacheManager instance = CacheManager(
    Config(
      key,
      repo: JsonCacheInfoRepository(
        databaseName: key,
      ),
      fileSystem: IOCacheManagerExtended(
        key,
        storeInCacheDirectory: false,
      ),
      fileService: HttpFileService(),
      maxNrOfCacheObjects: 3000,
    ),
  );
}
