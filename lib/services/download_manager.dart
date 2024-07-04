import "dart:async";
import "dart:io";

import "package:collection/collection.dart";
import "package:queue/queue.dart";

import "../main.dart";
import "../provider/user.dart";
import "audio_player.dart";
import "logger.dart";

/// Класс, используемый в [DownloadManager], хранящий задачу по загрузке/удаления плейлиста.
class CacheItem {
  static AppLogger logger = getLogger("DownloadItem");

  /// Плейлист типа [ExtendedPlaylist], список треков которого будет загружаться и кэшироваться, либо удаляться.
  final ExtendedPlaylist playlist;

  /// Указывает, что данный плейлист будет именно кэшироваться, а не удаляться из памяти устройства.
  final bool cache;

  // /// Объект пользователя, благодаря чему будет извлекаться текст песни.
  // final UserProvider user;

  /// Очередь по кэшированию треков.
  ///
  /// Значение переменной устанавливается только после вызова метода [startCaching].
  Queue? _queue;

  /// Callback-метод, вызываемый при успешной полной загрузке трека.
  static Future<void> _onTrackDownloaded(
    ExtendedAudio audio,
    ExtendedPlaylist playlist,
    List<int> trackBytes,
    File trackFile,
    // UserProvider user,
  ) async {
    // Сохраняем трек на диск.
    trackFile.createSync(recursive: true);
    trackFile.writeAsBytesSync(trackBytes);

    // // Загружаем информацию по треку.
    // await CachedStreamedAudio.downloadTrackData(
    //   audio,
    //   playlist,
    //   user,
    //   allowDeezer: user.settings.deezerThumbnails,
    //   allowSpotifyLyrics:
    //       user.settings.spotifyLyrics && user.spDCcookie != null,
    // );

    // Запоминаем то, что трек кэширован.
    audio.isCached = true;
    audio.downloadProgress.value = 0.0;

    // Сохраняем изменения.
    appStorage.savePlaylist(playlist.asDBPlaylist);
  }

  /// Внутренняя задача по кэшированию отдельного трека в плейлисте. [cache] указывает, что трек будет именно кэширован, вместо его удаления.
  static Future<void> cacheTrack(
    ExtendedAudio audio,
    ExtendedPlaylist playlist,
    bool cache,
    // UserProvider user,
  ) async {
    final File trackFile =
        await CachedStreamedAudio.getCachedAudioByKey(audio.mediaKey);
    final bool trackFileExists = trackFile.existsSync();

    if (!cache) {
      // Если нам нужно удалить трек из памяти устройства, то делаем это.

      logger.d("Deleting $audio from cache");
      if (trackFileExists) {
        trackFile.deleteSync();
      }

      // Запоминаем то, что трек удалён из кэша.
      audio.isCached = false;
      audio.downloadProgress.value = 0.0;

      return;
    }

    // Если трек уже загружен, то запоминаем это.
    if (trackFileExists) {
      // Запоминаем то, что трек кэширован.
      audio.isCached = true;
      audio.downloadProgress.value = 0.0;

      return;
    }

    // Трек не существует, загружаем его.
    logger.d("Downloading $audio");

    final Completer<void> completer = Completer();

    final HttpClient httpClient = HttpClient();
    final HttpClientRequest request =
        (await httpClient.getUrl(Uri.parse(audio.url!)));
    final List<int> trackBytes = [];
    int trackLength = 0;

    final response = await request.close();
    if (response.statusCode != 200) {
      httpClient.close();

      throw Exception("HTTP Status Error: ${response.statusCode}");
    }

    final int trackFullLength = response.contentLength;

    // Начинаем загрузку трека.
    response.asBroadcastStream().listen(
      (List<int> data) {
        trackBytes.addAll(data);
        trackLength += data.length;

        audio.downloadProgress.value = trackLength / trackFullLength;
      },
      onDone: () async {
        logger.d(
          "Done downloading $audio, ${trackBytes.length} bytes",
        );

        // Проверяем длину полученного файла.
        if (trackBytes.length != trackFullLength) {
          throw Exception(
            "Download file $audio size mismatch: expected $trackFullLength, but got ${trackBytes.length} instead",
          );
        }

        // // Трек успешно загружен, вызываем callback-метод.
        // await _onTrackDownloaded(
        //   audio,
        //   playlist,
        //   trackBytes,
        //   trackFile,
        //   user,
        // );

        completer.complete();
      },
      onError: (Object e, StackTrace stackTrace) {
        logger.e(
          "Error while downloading/caching media $audio:",
          error: e,
          stackTrace: stackTrace,
        );

        audio.downloadProgress.value = 0.0;

        completer.complete();
      },
      cancelOnError: true,
    );

    // Дожидаемся конца загрузки.
    return await completer.future;
  }

  /// Начинает задачу по загрузке/удалению плейлиста.
  ///
  /// После вызова, можно отменить задачу по загрузке методом [cancelCaching].
  ///
  /// [onTrackCached] - callback метод, вызываемый при завершении процесса кэширования отдельного трека. Вызывается лишь в случае, если [cache] равен true.
  Future<void> startCaching({
    bool saveInDB = true,
    Function(ExtendedAudio)? onTrackCached,
  }) async {
    logger.d("Called startCaching for $this");

    assert(
      playlist.audios != null,
      "ExtendedPlaylist audios are null",
    );

    // Если уже запущена задача, то ничего не делаем.
    if (_queue != null) return;

    // Создаём очередь и помещаем задачи по загрузке.
    _queue = Queue(
      parallel: 3,
    );
    int queueItems = 0;

    for (ExtendedAudio audio in playlist.audios!) {
      if (audio.isCached == cache) continue;

      if (cache && audio.url == null) continue;

      _queue!.add(() => cacheTrack(audio, playlist, cache)).then((_) async {
        // Если мы загружаем треки, то после каждой загрузки сохраняем изменени в БД.
        if (!cache) return;

        // Сохраняем изменения в БД.
        if (saveInDB) {
          await appStorage.savePlaylist(
            playlist.asDBPlaylist,
          );
        }

        await onTrackCached?.call(audio);
      }).onError((
        error,
        stackTrace,
      ) {
        if (error is QueueCancelledException) return;

        logger.e(
          "Cache/download error:",
          error: error,
          stackTrace: stackTrace,
        );
      });
      queueItems += 1;
    }

    // К сожалению, метод Queue.onComplete будет висеть бесконечно, если очередь пустая.
    // Именно поэтому здесь и есть проверка перед тем, как запустить .onComplete.
    if (queueItems > 0) {
      logger.d("startCaching will work with $queueItems items");

      await _queue!.onComplete;
    }

    logger.d("Completed startCaching for $this with $queueItems items");
  }

  /// Отменяет задачу по загрузке.
  ///
  /// Если вызвать данный метод до вызова метода [startCaching], то произойдёт исключение.
  Future<void> cancelCaching() async {
    logger.d("Called cancelCaching for $this");

    assert(
      _queue != null,
      "Called cancelCaching before calling download",
    );

    // Задача по загрузке ещё идёт, поэтому нам нужно её отменить и дождаться окончания.
    _queue!.cancel();
    await _queue!.onComplete;
  }

  @override
  String toString() =>
      "CacheItem ${playlist.mediaKey} ${cache ? 'download' : 'delete'} task";

  CacheItem({
    required this.playlist,
    this.cache = true,
    // required this.user,
  });
}

/// Класс-менеджер загрузок, используемый для загрузки и кэширования плейлистов ВКонтакте.
class DownloadManager {
  static AppLogger logger = getLogger("DownloadManager");

  /// List, содержащий в себе задачи по кэшированию плейлистов.
  final List<CacheItem> _tasks = [];

  /// Возвращает [CacheItem] по передаваемому [playlist]. Возвращает null, если ничего не было найдено.
  CacheItem? getCacheTask(ExtendedPlaylist playlist) => _tasks.firstWhereOrNull(
        (item) => item.playlist == playlist,
      );

  /// Указывает, запущена ли задача по кэшированию передаваемого [playlist].
  bool isTaskRunningFor(ExtendedPlaylist playlist) =>
      getCacheTask(playlist) != null;

  /// Запускает задачу по кэшированию плейлиста [playlist]. Если данный метод вызвать несколько раз, то ничего не будет происходить лишь в случае, если [cache] не менялся. [cache] указывает, что треки в плейлисте будут кэшироваться, а не удаляться из памяти устройства.
  Future<void> cachePlaylist(
    ExtendedPlaylist playlist, {
    bool cache = true,
    bool saveInDB = true,
    // required UserProvider user,
    Function(ExtendedAudio)? onTrackCached,
  }) async {
    final CacheItem? pendingItem = getCacheTask(playlist);

    assert(
      playlist.audios != null,
      "ExtendedPlaylist audios are null",
    );

    // Если такая задача уже есть, и переменная cache отличается, то мы должны отменить предыдущую задачу.
    if (pendingItem != null && pendingItem.cache != cache) {
      logger.d("Force cancelling task $pendingItem");

      await pendingItem.cancelCaching();
      _tasks.remove(pendingItem);
    } else if (pendingItem != null) {
      // Такая задача с такими же параметрами уже есть, так что ничего не делаем.
      return;
    }

    // Создаём новую задачу по кэшированию, и запускаем её.
    final CacheItem cacheTask = CacheItem(
      playlist: playlist,
      cache: cache,
      // user: user,
    );

    _tasks.add(cacheTask);
    await cacheTask.startCaching(
      saveInDB: saveInDB,
      onTrackCached: onTrackCached,
    );

    // Дожидаемся, когда задача завершится, после чего удаляем её.
    _tasks.remove(cacheTask);
  }
}
