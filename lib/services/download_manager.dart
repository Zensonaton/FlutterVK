import "dart:async";
import "dart:io";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:queue/queue.dart";

import "../api/vk/audio/get_lyrics.dart";
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

    // Сохраняем новую версию плейлиста. Для начала, нам нужно извлечь актуальную версию плейлиста.
    if (updatePlaylist) {
      final newPlaylist = ref
          .read(playlistsProvider.notifier)
          .getPlaylist(playlist.ownerID, playlist.id);
      assert(newPlaylist != null, "Playlist is null");

      // Сохраняем изменения плейлиста.
      ref.read(playlistsProvider.notifier).updatePlaylist(
            newPlaylist!.copyWithNewAudio(
              audio.copyWith(isCached: false),
            ),
          );
    }
  }
}

/// [DownloadItem] для кэширования отдельного трека для [PlaylistCacheDownloadTask].
class PlaylistCacheDownloadItem extends DownloadItem {
  // TODO: Использовать глобальный Dio.
  final Dio dio = Dio(
    BaseOptions(
      responseType: ResponseType.bytes,
    ),
  );

  /// Плейлист, в котором находится данный трек.
  final ExtendedPlaylist playlist;

  /// Трек, который будет кэшироваться.
  final ExtendedAudio audio;

  /// Указывает, будет ли удаление кэша вызывать методы [playlistsProvider.updatePlaylist].
  final bool updatePlaylist;

  PlaylistCacheDownloadItem({
    required super.ref,
    required this.playlist,
    required this.audio,
    this.updatePlaylist = true,
  });

  /// Загружает трек, возвращая его размер в байтах, если он был успешно загружен.
  Future<int?> _downloadAudio() async {
    final file =
        await CachedStreamAudioSource.getCachedAudioByKey(audio.mediaKey);

    // Если файл уже загружен, то не загружаем его.
    if (!file.existsSync() && audio.url != null) {
      final response = await dio.get(
        audio.url!,
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

  /// Загружает обложки трека
  Future<void> _downloadThumbnails() async {
    // Если у самого трека нет обложек, то ничего не загружаем.
    if (audio.thumbnail == null) return;

    final manager = CachedAlbumImagesManager.instance;
    final smallKey = "${audio.mediaKey}small";
    final maxKey = "${audio.mediaKey}max";

    final thumbSmall = await manager.getFileFromCache(smallKey);
    final thumbMax = await manager.getFileFromCache(maxKey);

    // Если обложки уже загружены, то ничего не делаем.
    if (thumbSmall != null && thumbMax != null) return;

    // Загружаем обложки трека, если таковые ещё не были загружены.
    await Future.wait([
      manager.downloadFile(audio.thumbnail!.photoSmall, key: smallKey),
      manager.downloadFile(audio.thumbnail!.photoMax, key: maxKey),
    ]);
  }

  /// Загружает текст песни с ВКонтакте, и возвращает объект [Lyrics] с текстом песни.
  Future<Lyrics?> _downloadLyrics() async {
    final api = ref.read(vkAPIProvider);

    // Если мы знаем, что у трека нету текста, либо он уже загружен, то ничего не делаем.
    if (!(audio.hasLyrics ?? false) || audio.lyrics != null) return null;

    // Загружаем текст песни.
    final APIAudioGetLyricsResponse response =
        await api.audio.getLyrics(audio.mediaKey);

    return response.lyrics;
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
        if (downloadAudio) item._downloadAudio() else null,
        if (downloadThumbnails) item._downloadThumbnails() else null,
        if (downloadLyrics) item._downloadLyrics() else null,
      ].map((element) => element ?? Future.value()),
    );

    // Если ничего не изменилось, просто выходим без сохранений.
    final bool isAnyDownloaded = result.any((element) => element != null);
    if (!isAnyDownloaded) return null;

    // Извлекаем результаты.
    final audioSize = result[0] as int?;
    final lyricsDownloaded = result[2] as Lyrics?;

    return audio.copyWith(
      isCached: true,
      cachedSize: audioSize,
      lyrics: lyricsDownloaded,
    );
  }

  @override
  Future<void> download() async {
    final newAudio = await downloadWithMetadata(
      ref,
      playlist,
      audio,
      downloadItem: this,
    );

    // Если ничего не поменялось, то ничего не делаем.
    if (newAudio == null) return;

    // Сохраняем новую версию трека. Для начала, нам нужно извлечь актуальную версию плейлиста.
    if (updatePlaylist) {
      final newPlaylist = ref
          .read(playlistsProvider.notifier)
          .getPlaylist(playlist.ownerID, playlist.id);
      assert(newPlaylist != null, "Playlist is null");

      // Определяем, нужно ли нам сохранять изменения в БД.
      // Мы сохраняем изменения каждые 5 треков.
      final saveInDB = newPlaylist!.audios!.indexOf(audio) % 5 == 0;

      ref.read(playlistsProvider.notifier).updatePlaylist(
            newPlaylist.copyWithNewAudio(newAudio),
            saveInDB: saveInDB,
          );
    }
  }

  @override
  Future<void> cancel() async => dio.close(force: true);
}

/// [DownloadTask], загружающий обновление для Flutter VK.
///
/// Используйте [AppUpdaterDownloadItem] для загрузки файла обновления.
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
            AppUpdaterDownloadItem(
              url: url,
              file: file,
              ref: ref,
            ),
          ],
        );
}

/// [DownloadItem], загружающий файл обновления по передаваемому [url], и дальше сохраняет его в [file] после успешной загрузки.
class AppUpdaterDownloadItem extends DownloadItem {
  /// Url на загрузку данного файла.
  final String url;

  /// Полный путь, куда будет сохранён данный файл после загрузки.
  final File file;

  final Dio dio = Dio(
    BaseOptions(
      responseType: ResponseType.bytes,
    ),
  );

  AppUpdaterDownloadItem({
    required this.url,
    required this.file,
    required super.ref,
  });

  @override
  Future<void> download() async {
    final response = await dio.get(
      url,
      onReceiveProgress: (int received, int total) {
        progress.value = received / total;
      },
    );

    await file.writeAsBytes(response.data);
  }

  @override
  Future<void> cancel() async => dio.close(force: true);
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
  final Queue _queue = Queue(parallel: isDesktop ? 5 : 2);

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
      item.progress.removeListener(listener);
    }).onError((error, stackTrace) {
      if (error is QueueCancelledException) return;

      logger.e(
        "Download error:",
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  /// Начинает задачу по загрузке всех [tasks].
  Future<void> download() async {
    assert(!_downloading, "Download already started");
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
