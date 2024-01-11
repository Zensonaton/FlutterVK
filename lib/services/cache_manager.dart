// ignore_for_file: implementation_imports

import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:flutter_cache_manager/src/storage/file_system/file_system_io.dart";

/// Класс типа [CacheManager], который выполняет работу по кэшированию треков из ВКонтакте.
class VKMusicCacheManager {
  /// Ключ, по которому сохраняются кэшированные треки.
  static const String key = "vkflutter-music";

  static CacheManager instance = CacheManager(
    Config(
      key,
      repo: JsonCacheInfoRepository(
        databaseName: key,
      ),
      fileSystem: IOFileSystem(
        key,
      ),
      fileService: HttpFileService(),
    ),
  );
}
