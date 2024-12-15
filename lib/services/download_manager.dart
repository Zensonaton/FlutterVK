import "dart:async";
import "dart:io";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:queue/queue.dart";

import "../api/deezer/search.dart";
import "../api/lrclib/get.dart";
import "../api/lrclib/search.dart";
import "../api/lrclib/shared.dart";
import "../api/vk/audio/get_lyrics.dart";
import "../main.dart";
import "../provider/playlists.dart";
import "../provider/user.dart";
import "../provider/vk_api.dart";
import "../utils.dart";
import "audio_player.dart";
import "cache_manager.dart";
import "logger.dart";

/// [DownloadTask], загружающий треки из [playlist], делая их доступными для прослушивания в оффлайне.
///
/// Используйте [PlaylistCacheDownloadItem] для кэширования отдельных треков.
class PlaylistCacheDownloadTask extends DownloadTask {
  /// [Ref], используемый для доступа к контексту и другим важным объектам.
  final Ref ref;

  /// Плейлист, который будет кэшироваться.
  final ExtendedPlaylist playlist;

  @override
  Future<void> download() async {
    await super.download();

    // Сохраняем новую версию плейлиста. Для начала, нам нужно извлечь актуальную версию плейлиста.
    final newPlaylist = ref
        .read(playlistsProvider.notifier)
        .getPlaylist(playlist.ownerID, playlist.id);
    if (newPlaylist == null) return;

    // Сохраняем изменения плейлиста.
    ref.read(playlistsProvider.notifier).saveDBPlaylist(newPlaylist);
  }

  PlaylistCacheDownloadTask({
    required this.ref,
    required this.playlist,
    required super.id,
    required super.smallTitle,
    required super.longTitle,
    required super.tasks,
  });
}

/// [DownloadItem] для удаления кэша у отдельного трека для [PlaylistCacheDeleteDownloadTask].
class PlaylistCacheDeleteDownloadItem extends DownloadItem {
  static final AppLogger logger = getLogger("PlaylistCacheDeleteDownloadItem");

  /// Плейлист, в котором находится данный трек.
  final ExtendedPlaylist playlist;

  /// Трек, кэш которого будет удалён.
  final ExtendedAudio audio;

  /// Указывает, будет ли удаление кэша вызывать методы [playlistsProvider.updatePlaylist].
  final bool updatePlaylist;

  /// Указывает, что помимо самого кэша трека, будут удалены и его обложки.
  final bool removeThumbnails;

  PlaylistCacheDeleteDownloadItem({
    required super.ref,
    required this.playlist,
    required this.audio,
    this.updatePlaylist = true,
    this.removeThumbnails = false,
  });

  @override
  Future<void> download() async {
    final file =
        await CachedStreamAudioSource.getCachedAudioByKey(audio.mediaKey);

    // Если файл есть на диске, то удаляем его.
    if (file.existsSync()) {
      await file.delete();

      // Удаляем папку, хранящую кэшированный файл, если она пуста.
      // Здесь используется try-catch, так как .delete() может вызвать ошибку, если папка не пуста.
      try {
        await file.parent.delete();
      } catch (e) {
        // No-op.
      }

      // Если это необходимо, то удаляем обложки.
      if (removeThumbnails) {
        final manager = CachedAlbumImagesManager.instance;
        final smallKey = "${audio.mediaKey}small";
        final maxKey = "${audio.mediaKey}max";

        await Future.wait([
          manager.removeFile(smallKey),
          manager.removeFile(maxKey),
        ]);
      }
    } else {
      if (audio.isCached ?? false) {
        logger.w("Found ghost track (marked as cached, no file): $audio");
      }
    }

    progress.value = 1.0;

    // Сохраняем изменения плейлиста.
    if (updatePlaylist) {
      // Получаем новый объект плейлиста.
      //
      // FIXME: Этот костыль свзяан с тем, что copyWithNewAudio копирует даже старые треки.
      // Из-за этого при кэшировании иногда происходит перезапись старых треков, и это плохо.
      final newPlaylist =
          ref.read(getPlaylistProvider(playlist.ownerID, playlist.id));
      if (newPlaylist == null) return;

      ref.read(playlistsProvider.notifier).updatePlaylist(
            newPlaylist.basicCopyWith(
              audiosToUpdate: [
                audio.basicCopyWith(
                  isCached: false,
                ),
              ],
            ),
          );
    }
  }
}

/// [DownloadItem] для кэширования отдельного трека для [PlaylistCacheDownloadTask].
class PlaylistCacheDownloadItem extends DownloadItem {
  static final AppLogger logger = getLogger("PlaylistCacheDownloadItem");

  /// Определяет количество треков, которое требуется сохранить на диск, прежде чем вызвать [playlistsProvider.updatePlaylist].
  static const int saveInDBCount = 5;

  /// Плейлист, в котором находится данный трек.
  final ExtendedPlaylist playlist;

  /// Трек, который будет кэшироваться.
  final ExtendedAudio audio;

  /// Указывает, будет ли удаление кэша вызывать методы [playlistsProvider.updatePlaylist].
  final bool updatePlaylist;

  /// Индекс трека в плейлисте, который будет кэшироваться.
  ///
  /// Используется при [updatePlaylist], что бы не перегружать БД постоянными сохранениями на диск. Если не указано, то индекс будет найден автоматически.
  final int? index;

  /// Определяет, будет ли загружаться аудио-файл трека.
  final bool downloadAudio;

  /// Определяет, будет ли загружаться обложки трека.
  final bool downloadThumbnails;

  /// Определяет, будет ли загружаться текст песни трека.
  final bool downloadLyrics;

  /// Определяет, будет ли загружаться обложки трека с Deezer.
  final bool deezerThumbnails;

  /// Определяет, будет ли загружаться текст песни трека с LRCLIB.
  final bool lrcLibLyricsEnabled;

  PlaylistCacheDownloadItem({
    required super.ref,
    required this.playlist,
    required this.audio,
    this.updatePlaylist = true,
    this.index,
    this.downloadAudio = true,
    this.downloadThumbnails = true,
    this.downloadLyrics = true,
    this.deezerThumbnails = false,
    this.lrcLibLyricsEnabled = false,
  });

  /// Загружает трек, возвращая его размер в байтах, если он был успешно загружен.
  Future<int?> _downloadAudio() async {
    final file =
        await CachedStreamAudioSource.getCachedAudioByKey(audio.mediaKey);

    // Если файл уже загружен, то не загружаем его.
    if (!file.existsSync() && audio.url != null) {
      final response = await dio.get(
        audio.url!,
        options: Options(
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: (int received, int total) {
          progress.value = received / total;
        },
      );

      await file.create(recursive: true);
      await file.writeAsBytes(response.data);

      return response.data.length;
    }

    progress.value = 1.0;
    return null;
  }

  /// Внутренний метод, который загружает обложки с передаваемого объекта [ExtendedThumbnails], и помещает их в [CachedAlbumImagesManager]. Если оказывается, что обложка уже кэширована, то ничего не делается.
  ///
  /// Вероятнее всего, вместо этого метода вам нужен [_downloadThumbnails] либо [_downloadDeezerThumbnails].
  Future<void> _downloadAndCacheThumbnails(
    ExtendedThumbnails thumbnails,
  ) async {
    final manager = CachedAlbumImagesManager.instance;
    final smallKey = "${audio.mediaKey}small";
    final maxKey = "${audio.mediaKey}max";

    final thumbSmall = await manager.getFileFromCache(smallKey);
    final thumbMax = await manager.getFileFromCache(maxKey);

    // Если обложки уже загружены, то ничего не делаем.
    if (thumbSmall != null && thumbMax != null) return;

    await Future.wait([
      manager.downloadFile(thumbnails.photoSmall, key: smallKey),
      manager.downloadFile(thumbnails.photoMax, key: maxKey),
    ]);
  }

  /// Загружает обложки трека с ВКонтакте, либо с Deezer, если они есть, и помещает их в [CachedAlbumImagesManager].
  ///
  /// Если [deezer] равен true, то также пытается загрузить обложки с Deezer при помощи метода [_downloadDeezerThumbnails].
  Future<ExtendedAudio?> _downloadThumbnails({
    bool vk = true,
    bool deezer = true,
  }) async {
    ExtendedThumbnails? vkThumbnails;
    ExtendedThumbnails? deezerThumbnails;

    // Обложки с ВКонтакте.
    if (vk) {
      vkThumbnails ??= audio.vkThumbs;
    }

    // Обложки с Deezer.
    if (deezer) {
      deezerThumbnails ??= audio.deezerThumbs;

      // Если обложек с Deezer нет, то пытаемся узнать URL на обложки, что бы их потом загрузить.
      if (deezerThumbnails == null) {
        final results = await deezer_search_sorted(
          audio.artist,
          audio.title,
          subtitle: audio.subtitle,
          duration: audio.duration,
          album: audio.album?.title,
        );
        final match = results.firstOrNull;
        if (match == null) return null;

        // В очень редких случаях Deezer возвращает альбом, но не возвращает обложки.
        if (match.album.coverSmall == null) {
          logger.w("Deezer returned album without cover: ${match.toJson()}");

          return null;
        }

        deezerThumbnails = ExtendedThumbnails.fromDeezerTrack(match);
      }
    }

    // Загружаем обложки как изображения, если мы их смогли найти.
    ExtendedThumbnails? thumbsToCache = vkThumbnails ?? deezerThumbnails;
    if (thumbsToCache != null) {
      await _downloadAndCacheThumbnails(thumbsToCache);

      return audio.basicCopyWith(
        vkThumbs: vkThumbnails,
        deezerThumbs: deezerThumbnails,
      );
    }

    return null;
  }

  /// Загружает текст песни с ВКонтакте, и возвращает объект [Lyrics] с текстом песни.
  Future<Lyrics?> _downloadLyrics() async {
    if (!(audio.hasLyrics ?? false) || audio.vkLyrics != null) return null;

    final APIAudioGetLyricsResponse response =
        await ref.read(vkAPIProvider).audio.getLyrics(audio.mediaKey);

    return response.lyrics;
  }

  /// Ищет тексты песен с сервиса LRCLIB, и загружает их, если они есть, возвращая объект [Lyrics].
  Future<Lyrics?> _downloadLRCLIBLyrics() async {
    if (audio.lrcLibLyrics != null) return null;

    try {
      // Пытаемся получить текст песни с LRCLib, передавая длительность трека и его альбом (при наличии).
      final response = await lrcLib_get(
        audio.title,
        audio.artist,
        album: audio.album?.title,
        duration: audio.duration,
      );

      return response.asLyrics;
    } on LRCLIBException {
      // No-op.
    } catch (error, stackTrace) {
      logger.w(
        "[get] LRCLib error:",
        error: error,
        stackTrace: stackTrace,
      );
    }

    // Если мы здесь, то значит, что мы не получили информацию по тексту, передавая альбом и длительность трека.
    // В таком случае, используем API search (поиска). Он хуже, поскольку get может искать тексты с других источников.
    //
    // В документации LRCLib написано, что search стоит использовать лишь как fallback, что мы и делаем здесь.
    // https://lrclib.net/docs

    try {
      // Производим поиск.
      final response = await lrcLib_search(
        audio.title,
        artist: audio.artist,
        album: audio.album?.title,
      );

      return response.firstOrNull?.asLyrics;
    } on LRCLIBException {
      // No-op.
    } catch (error, stackTrace) {
      logger.w(
        "[search] LRCLib error:",
        error: error,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  /// Загружает сам трек, его обложки, текст песни и прочую информацию для передаваемого [audio].
  ///
  /// Возвращает изменённую версию [audio] типа [ExtendedAudio], если хотя бы один из элементов был загружен, иначе null.
  static Future<ExtendedAudio?> downloadWithMetadata(
    Ref ref,
    ExtendedPlaylist playlist,
    ExtendedAudio audio, {
    PlaylistCacheDownloadItem? downloadItem,
    bool downloadAudio = true,
    bool downloadThumbnails = true,
    bool downloadLyrics = true,
    bool deezerThumbnails = false,
    bool lrcLibLyricsEnabled = false,
  }) async {
    final item = downloadItem ??
        PlaylistCacheDownloadItem(
          playlist: playlist,
          audio: audio,
          ref: ref,
        );

    // Здесь мы ждём завершения всех трёх загрузок, и возвращаем true, если хотя бы одна из них была выполнена.
    //
    // Если аргументом функции указано, что что-то выключено, то вместо Future мы делаем null,
    //  который заменяется пустым Future.wait() внутри Future.wait().
    final result = await Future.wait(
      [
        // [0]: Сам трек.
        if (downloadAudio) item._downloadAudio() else null,

        // [1]: Обложки с ВКонтакте, Deezer.
        if (downloadThumbnails || deezerThumbnails)
          item._downloadThumbnails(
            vk: downloadThumbnails,
            deezer: deezerThumbnails,
          )
        else
          null,

        // [2]: Текст песни с ВКонтакте.
        if (downloadLyrics) item._downloadLyrics() else null,

        // [3]: Текст песни с LRCLIB.
        if (lrcLibLyricsEnabled) item._downloadLRCLIBLyrics() else null,
      ].map((element) async {
        final future = element ?? Future.value();

        try {
          return await future;
        } catch (error, stackTrace) {
          logger.e(
            "Error while downloading metadata for $audio:",
            error: error,
            stackTrace: stackTrace,
          );

          return null;
        }
      }),
    );

    // Если ничего не изменилось, просто выходим без сохранений.
    final bool isAnyDownloaded = result.any((element) => element != null);
    if (!isAnyDownloaded) return null;

    // Извлекаем результаты.
    final audioSize = result[0] as int?;
    final audiosWithThumbs = result[1] as ExtendedAudio?;
    final lyricsDownloaded = result[2] as Lyrics?;
    final lrcLibLyrics = result[3] as Lyrics?;

    return audio.basicCopyWith(
      isCached: downloadAudio ? true : null,
      cachedSize: audioSize,
      vkLyrics: lyricsDownloaded,
      deezerThumbs: audiosWithThumbs?.deezerThumbs,
      lrcLibLyrics: lrcLibLyrics,
    );
  }

  @override
  Future<void> download() async {
    final playlists = ref.read(playlistsProvider.notifier);

    final newAudio = await downloadWithMetadata(
      ref,
      playlist,
      audio,
      downloadItem: this,
      downloadAudio: downloadAudio,
      downloadThumbnails: downloadThumbnails,
      downloadLyrics: downloadLyrics,
      deezerThumbnails: deezerThumbnails,
      lrcLibLyricsEnabled: lrcLibLyricsEnabled,
    );

    // Если ничего не поменялось, то ничего не делаем.
    if (newAudio == null) return;

    // Сохраняем новую версию трека.
    if (updatePlaylist) {
      final int foundIndex = index ??
          playlist.audios!.indexWhere((item) {
            return item.id == audio.id;
          });

      // Сохраняем изменения в БД (т.е., на диск) не постоянно, что бы не вызывать сильные нагрузки на диск.
      final bool saveInDB = foundIndex % saveInDBCount == 0;

      await playlists.updatePlaylist(
        playlist.basicCopyWith(
          audiosToUpdate: [newAudio],
        ),
        saveInDB: saveInDB,
      );
    }
  }

  @override
  Future<void> cancel() async => dio.close(force: true);
}

/// [DownloadTask], загружающий обновление для Flutter VK.
///
/// Используйте [UrlDownloadItem] для загрузки файла обновления.
class AppUpdaterDownloadTask extends DownloadTask {
  /// [Ref], используемый для доступа к контексту и другим важным объектам.
  final Ref ref;

  /// Url на загрузку данного файла.
  final String url;

  /// Полный путь, куда будет сохранён данный файл после загрузки.
  final File file;

  AppUpdaterDownloadTask({
    required this.ref,
    required super.id,
    required super.smallTitle,
    required super.longTitle,
    required this.url,
    required this.file,
  }) : super(
          tasks: [
            UrlDownloadItem(
              url: url,
              file: file,
              ref: ref,
            ),
          ],
        );
}

/// [DownloadItem], используемый для фейковой задачи, которая ничего не делает.
class FakeDownloadItem extends DownloadItem {
  static const double step = 0.01;
  static const Duration delay = Duration(milliseconds: 100);

  FakeDownloadItem({
    required super.ref,
  });

  @override
  Future<void> download() async {
    while (progress.value + step < 1.0) {
      progress.value += step;

      await Future.delayed(
        delay,
      );
    }
  }

  @override
  Future<void> cancel() async {
    progress.value = 1.0;
  }
}

/// [DownloadItem], загружающий файл обновления по передаваемому [url], и дальше сохраняет его в [file] после успешной загрузки.
class UrlDownloadItem extends DownloadItem {
  /// Url на загрузку данного файла.
  final String url;

  /// Полный путь, куда будет сохранён данный файл после загрузки.
  final File file;

  UrlDownloadItem({
    required this.url,
    required this.file,
    required super.ref,
  });

  @override
  Future<void> download() async {
    final response = await dio.get(
      url,
      options: Options(
        responseType: ResponseType.bytes,
      ),
      onReceiveProgress: (int received, int total) {
        progress.value = received / total;
      },
    );

    await file.writeAsBytes(response.data);
  }

  @override
  Future<void> cancel() async {
    // TODO: Не закрывать объект dio, поскольку он используется где-то ещё.

    dio.close(force: true);
  }
}

/// Отдельная, под-задача для [DownloadTask], олицетворяющая маленькую задачу для загрузки чего-либо.
///
/// К примеру, здесь может быть задача по загрузке отдельного трека в плейлисте.
class DownloadItem {
  static final AppLogger logger = getLogger("DownloadTaskItem");

  /// [Ref], используемый для доступа к контексту и другим важным объектам.
  final Ref ref;

  /// [ValueNotiifer], показывающий прогресс загрузки, где `0.0` - 0%, `1.0` - 100%.
  final ValueNotifier<double> progress = ValueNotifier(0.0);

  /// Метод, вызываемый при загрузке данной задачи.
  Future<void> download() async {
    throw UnimplementedError();
  }

  /// Метод, вызываемый при остановке данной задачи.
  Future<void> cancel() async {
    throw UnimplementedError();
  }

  @override
  String toString() =>
      "DownloadItem, ${(progress.value * 100).round()}% completed";

  DownloadItem({
    required this.ref,
  });
}

/// Отдельная, глобальная задача по загрузке чего-либо для DownloadManager'а.
///
/// В данной задаче может быть множество под-задач ([DownloadItem]), к примеру, данная задача может использоваться для кэширования целого плейлиста, а под-задачами будет кэширование каждого отдельного трека внутри этого плейлиста.
class DownloadTask {
  static final AppLogger logger = getLogger("DownloadTask");

  /// ID данной задачи.
  final String id;

  /// Маленькое название у данной задачи, отображаемое при наведении на [DownloadManagerIconWidget].
  ///
  /// Содержимое данное переменной должно быть максимально кратким, что бы оно с большей вероятностью вместилось в [DownloadManagerIconWidget]. Пример: "Любимая музыка" или "Обновление".
  final String smallTitle;

  /// Более длинное название у данной задачи, отображаемое в других местах, например, уведомлении на OS Android.
  ///
  /// Пример: "Кэширование плейлиста 'Любимая музыка'" или "Обновление Flutter VK v1.2.3".
  final String longTitle;

  /// Общий список из всех задач типа [DownloadItem].
  final List<DownloadItem> tasks;

  /// [ValueNotifier], возвращающий общий прогресс по всем задачам.
  final ValueNotifier<double> progress = ValueNotifier(0.0);

  /// [Queue], используемый для одновременной загрузки задач из [tasks].
  final Queue _queue = Queue(parallel: isDesktop ? 5 : 3);

  /// Указывает, запущена ли загрузка.
  bool _downloading = false;

  Future<void> _queueItemWrapper(DownloadItem item) async {
    void listener() {
      progress.value = tasks.fold(
            0.0,
            (total, item) => total + item.progress.value,
          ) /
          tasks.length;
    }

    return await _queue.add(() async {
      item.progress.addListener(listener);

      await item.download();
    }).onError((error, stackTrace) {
      if (error is QueueCancelledException) return;

      logger.e(
        "Download error for $item:",
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      item.progress.value = 1.0;
      item.progress.removeListener(listener);
    });
  }

  /// Начинает задачу по загрузке всех [tasks].
  Future<void> download() async {
    if (_downloading) {
      throw StateError("Download already started");
    }
    _downloading = true;

    for (DownloadItem item in [...tasks]) {
      _queueItemWrapper(item);
    }
    await _queue.onComplete;

    _downloading = false;
  }

  @override
  String toString() =>
      "DownloadTask \"$smallTitle\" id $id with ${tasks.length} tasks, ${(progress.value * 100).round()}% completed";

  DownloadTask({
    required this.id,
    required this.smallTitle,
    required this.longTitle,
    required this.tasks,
  });
}
