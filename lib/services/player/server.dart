import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:collection/collection.dart";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";

import "../../main.dart";
import "../../provider/dio.dart";
import "../../provider/playlists.dart";
import "../../provider/user.dart";
import "../../utils.dart";
import "../logger.dart";

/// enum, перечисляющий то, откуда был получен трек.
enum ServedSource {
  /// Трек был получен из кэша.
  cache,

  /// Трек был получен с серверов ВКонтакте.
  network,

  /// Placeholder-аудио.
  placeholder,
}

/// Класс, репрезентирующий отдельный served-трек.
class ServedAudio {
  /// ID владельца плейлиста, в котором находится этот трек.
  final int playlistOwnerID;

  /// ID плейлиста, в котором находится этот трек.
  final int playlistID;

  /// ID владельца трека.
  final int ownerID;

  /// ID трека.
  final int id;

  /// Уникальный ключ трека.
  final String key;

  /// Последнее время доступа к этому треку.
  final DateTime lastAccessed;

  /// Байтовое содержимое этого трека. Может отсутствовать, если трек не был загружен.
  final Uint8List? bytes;

  /// Источник, с которого был получен этот трек. Может отсутствовать, если трек не был загружен.
  final ServedSource? source;

  ServedAudio({
    required this.playlistOwnerID,
    required this.playlistID,
    required this.ownerID,
    required this.id,
    required this.key,
    required this.lastAccessed,
    this.bytes,
    this.source,
  });

  /// Возвращает копию этого объекта, но с указанными полями.
  ServedAudio copyWith({
    int? playlistOwnerID,
    int? playlistID,
    int? ownerID,
    int? id,
    String? key,
    DateTime? lastAccessed,
    Uint8List? bytes,
    ServedSource? source,
  }) {
    return ServedAudio(
      playlistOwnerID: playlistOwnerID ?? this.playlistOwnerID,
      playlistID: playlistID ?? this.playlistID,
      ownerID: ownerID ?? this.ownerID,
      id: id ?? this.id,
      key: key ?? this.key,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      bytes: bytes ?? this.bytes,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ServedAudio &&
        other.playlistOwnerID == playlistOwnerID &&
        other.playlistID == playlistID &&
        other.ownerID == ownerID &&
        other.id == id;
  }

  @override
  int get hashCode =>
      playlistOwnerID.hashCode ^
      playlistID.hashCode ^
      ownerID.hashCode ^
      id.hashCode;
}

/// Класс, содержащий в себе [ServedAudio], удаляющий записи из списка и добавляющий их.
class ServedAudioList {
  static final AppLogger logger = getLogger("ServedAudioList");

  /// Максимальное количество кэшированных треков.
  static const int maxCachedAudios = 6;

  /// Максимальное время, которое может находиться трек в кэше.
  static const Duration maxCachedAudioDuration = Duration(minutes: 15);

  /// Максимальный размер кэша в байтах (50 МБ).
  static const int maxCachedAudioSize = 50 * 1024 * 1024;

  /// Минимальное количество треков, которое обязано быть в данном списке, даже если оно не подходит по условиям.
  static const int minCachedAudios = 2;

  final List<ServedAudio> _audios = [];

  /// Размер данного кэша в байтах.
  int get totalSize {
    int totalSize = 0;

    for (final audio in _audios) {
      totalSize += audio.bytes?.length ?? 0;
    }
    return totalSize;
  }

  /// Количество элементов в данном кэше.
  int get length => _audios.length;

  /// Добавляет трек в список кэшированных треков. Если трек уже есть в списке, то он будет обновлён.
  void add(ServedAudio audio) {
    if (_audios.contains(audio)) {
      _audios.remove(audio);
    }
    _audios.add(audio);
    _enforceConstraints();
  }

  /// Удаляет трек из списка кэшированных треков.
  void remove(ServedAudio audio) {
    _audios.remove(audio);
  }

  /// Извлекает запись по ключу.
  ServedAudio? get(
    String key, {
    bool touch = true,
  }) {
    final servedAudio = _audios.firstWhereOrNull(
      (audio) => audio.key == key,
    );
    if (servedAudio == null) return null;

    if (touch) {
      _audios.remove(servedAudio);
      _audios.add(
        servedAudio.copyWith(
          lastAccessed: DateTime.now(),
        ),
      );
    }

    return servedAudio;
  }

  /// Извлекает запись по переданным [playlist] и [audio].
  ServedAudio? getByAudio(
    ExtendedAudio audio,
    ExtendedPlaylist playlist, {
    bool touch = true,
  }) {
    final servedAudio = _audios.firstWhereOrNull(
      (item) =>
          item.playlistOwnerID == playlist.ownerID &&
          item.playlistID == playlist.id &&
          item.ownerID == audio.ownerID &&
          item.id == audio.id,
    );
    if (servedAudio == null) return null;

    return get(
      servedAudio.key,
      touch: touch,
    );
  }

  /// Удаляет все треки из списка кэшированных треков.
  void clear() {
    _audios.clear();
  }

  /// Возвращает список всех кэшированных треков.
  List<ServedAudio> get audios => List.unmodifiable(_audios);

  /// Применяет ограничения на количество, размер и время кэшированных треков.
  void _enforceConstraints() {
    // Удаляем треки, если их слишком много, либо если слишком большой размер.
    for (int i = 0; i < _audios.length; i++) {
      if (_audios.length > maxCachedAudios || totalSize > maxCachedAudioSize) {
        if (_audios.length - 1 <= minCachedAudios) break;

        logger.d("Removing audio ${_audios[i].key}");
        _audios.removeAt(i);
      }
    }

    // Удаляем старые аудио.
    for (int i = 0; i < _audios.length; i++) {
      final isOld = DateTime.now().difference(_audios[i].lastAccessed) >
          maxCachedAudioDuration;

      if (isOld) {
        logger.d("Removing old audio ${_audios[i].key}");
        _audios.removeAt(i);
        i--;
      }
    }
  }
}

/// Класс, предоставляющий доступ к локальному HTTP-серверу для получения музыки.
///
/// Данный сервер автоматически предоставляет доступ к .mp3-файлам треков, которые воспроизводятся в данный момент.
/// Сервер запускается лишь в том случае, если у одного из [PlayerBackend]'ов есть поле [PlayerBackend.localServerRequired] равное true. В ином случае, попытка получения этого объекта будет вызывать ошибку.
class PlayerLocalServer {
  static final AppLogger logger = getLogger("PlayerLocalServer");

  /// Размер `.mp3`-файла в байтах, который считается повреждённым.
  static const int corruptedFileSizeBytes = 100 * 1024;

  /// Размер названия папки, в которой хранятся кэшированные треки.
  static const int cacheFolderNameLength = 2;

  /// Размер названия файла, в котором хранится кэшированный трек.
  static const int cacheFileNameLength = 32;

  /// Размер ключа, по которому трек возвращается с HTTP-сервера.
  static const int cacheKeyLength = 12;

  HttpServer? _server;
  final ServedAudioList _servedAudios = ServedAudioList();
  final Ref _ref;

  PlayerLocalServer({
    required Ref ref,
  }) : _ref = ref;

  /// Возвращает IP локального сервера.
  ///
  /// Чаще всего, возвращает `127.0.0.1`.
  String get address => _server!.address.address;

  /// Порт, на котором запущен локальный сервер.
  int get port => _server!.port;

  /// Возвращает адрес и порт локального сервера в формате `address:port`.
  String get addressAndPort => "$address:$port";

  /// Возвращает HTTP URL к локальному серверу.
  String get url => "http://$addressAndPort";

  /// Возвращает путь к корневой папке, хранящий в себе кэшированные треки.
  ///
  /// К примеру, на Windows это `%APPDATA%/com.zensonaton/Flutter VK/audios-v2`.
  static Future<String> getTrackStorageDirectory() async {
    return join(
      (await getApplicationSupportDirectory()).path,
      "audios-v2",
    );
  }

  /// Возвращает пути к старым папкам, которые ранее использовались для хранения кэшированных треков. Учтите, что данный метод не проверяет на существование папок.
  ///
  /// Если Вам нужна новая папка для хранения кэшированных треков, то воспользуйтесь методом [getTrackStorageDirectory].
  static Future<List<Directory>> getOldTrackStorageDirectories() async {
    final rootDir = (await getApplicationSupportDirectory()).path;

    return [
      "tracks",
      "audios",
    ]
        .map(
          (item) => Directory(join(rootDir, item)),
        )
        .toList();
  }

  /// Возвращает объект типа [File] по передаваемому [ExtendedAudio.mediaKey], в котором хранится кэшированный трек.
  ///
  /// Учтите, что данный метод не проверяет на существование файла. Для проверки на существование файла воспользуйтесь методом [File.existsSync].
  static Future<File> getCachedAudioByKey(String mediaKey) async {
    final hash = sha256String(mediaKey);

    return File(
      join(
        await getTrackStorageDirectory(), // Корень (папка с треками)
        hash.substring(0, cacheFolderNameLength), // Папка
        hash.substring(0, cacheFileNameLength), // Файл
      ),
    );
  }

  /// Возвращает уникальный ключ, по которому трек возвращается с HTTP-сервера.
  static String getLocalServerAudioKey(String mediaKey) {
    return sha256String(mediaKey).substring(0, cacheKeyLength);
  }

  /// Запускает локальный HTTP-сервер.
  ///
  /// Данный метод не делает ничего если приложение запущено в Web.
  Future<void> start() async {
    if (isWeb) {
      logger.d("Local HTTP server is not supported on Web");

      return;
    }

    logger.d("Starting local HTTP server...");

    final stopWatch = Stopwatch()..start();

    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    _server!.forEach(_onServerRequest);

    logger.d(
      "Local HTTP server started in ${stopWatch.elapsedMilliseconds}ms on ${_server!.address.address}:${_server!.port}",
    );
  }

  /// Останавливает локальный HTTP-сервер.
  Future<void> stop() async {
    logger.d("Stopping local HTTP server...");

    await _server?.close(force: true);
    _server = null;
    clear();

    logger.d("Local HTTP server stopped");
  }

  /// Очищает кэш треков.
  Future<void> clear() async {
    _servedAudios.clear();
  }

  /// Обработчик HTTP-запросов к локальному серверу.
  Future<void> _onServerRequest(HttpRequest request) async {
    final StreamController<Uint8List> bytesController = StreamController();
    final Stream<Uint8List> bytesStream =
        bytesController.stream.asBroadcastStream();
    int? size;
    ServedSource? source;

    void setHeaders({bool fromMemoryCache = false}) {
      if (source == null) {
        throw StateError("Source is not set");
      }
      if (size == null) {
        throw StateError("Size is not set");
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.headers
        ..contentType = ContentType("audio", "mpeg")
        ..contentLength = size
        ..add("Access-Control-Allow-Origin", "*")
        ..add("X-Audio-Source", source.name)
        ..add("X-From-Memory", fromMemoryCache.toString());
    }

    void printMemoryStats() {
      if (!kDebugMode) return;

      final currentSizeMB = _servedAudios.totalSize / (1024 * 1024);
      const totalSizeMB = ServedAudioList.maxCachedAudioSize / (1024 * 1024);

      logger.d(
        "Audios memory cache stats: ${_servedAudios.length} / ${ServedAudioList.maxCachedAudios} items, ${currentSizeMB.round()} / ${totalSizeMB.round()} MB",
      );
      for (var index = 0; index < _servedAudios.length; index++) {
        final audio = _servedAudios.audios[index];

        final timePassed = durationAsString(
          DateTime.now().difference(audio.lastAccessed),
        );
        final sizeMB = ((audio.bytes?.length ?? 0) / (1024 * 1024)).round();

        logger.d(
          "[$index] ${audio.ownerID}_${audio.id}, touched $timePassed ago: ~$sizeMB MB",
        );
      }
    }

    // Проверяем валидность хэша.
    final hash = request.uri.pathSegments.first;
    if (hash.length != cacheKeyLength) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write("Bad data")
        ..close();

      return;
    }

    // Находим трек по хэшу.
    final ServedAudio? servAudio = _servedAudios.get(hash);
    if (servAudio == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write("Not found")
        ..close();

      return;
    }

    // Если этот трек уже загружен, то просто возвращаем его.
    if (servAudio.bytes != null) {
      try {
        source = servAudio.source;
        size = servAudio.bytes!.length;
        setHeaders(fromMemoryCache: true);

        request.response.add(servAudio.bytes!);

        await request.response.close();

        printMemoryStats();
      } catch (error, stackTrace) {
        logger.e(
          "Failed to retrieve audio from memory cache",
          error: error,
          stackTrace: stackTrace,
        );
      }

      return;
    }

    // Находим ExtendedAudio.
    final ExtendedPlaylist? playlist = _ref
        .read(playlistsProvider.notifier)
        .getPlaylist(servAudio.playlistOwnerID, servAudio.playlistID);
    final ExtendedAudio? audio = playlist?.audios?.firstWhereOrNull(
      (element) =>
          element.ownerID == servAudio.ownerID && element.id == servAudio.id,
    );
    if (audio == null) {
      logger.w(
        "Audio ${servAudio.ownerID}_${servAudio.id} not found in playlist ${servAudio.playlistOwnerID}_${servAudio.playlistID}",
      );

      request.response
        ..statusCode = HttpStatus.notFound
        ..write("Not found")
        ..close();

      return;
    }

    final BytesBuilder bytesBuilder = BytesBuilder();
    bytesStream.listen(
      (Uint8List data) {
        request.response.add(data);
        bytesBuilder.add(data);
      },
      onDone: () async {
        await request.response.close();

        // Если нам это нужно, то обновляем трек в памяти.
        if ([ServedSource.network, ServedSource.cache].contains(source)) {
          _servedAudios.add(
            servAudio.copyWith(
              bytes: Uint8List.fromList(bytesBuilder.toBytes()),
              source: source,
              lastAccessed: DateTime.now(),
            ),
          );
        }

        printMemoryStats();
      },
    );

    // Загружаем кэшированный трек с диска.
    try {
      size = await acquireAudioFromCache(audio, playlist!, bytesController);

      if (size != null) {
        source = ServedSource.cache;
        setHeaders();
      }
    } catch (error, stackTrace) {
      logger.e(
        "Failed to acquire audio from cache",
        error: error,
        stackTrace: stackTrace,
      );
    }

    // Пытаемся загрузить трек с серверов ВКонтакте.
    if (audio.url != null && source == null) {
      try {
        size =
            await acquireFromNetwork(audio, playlist, request, bytesController);

        if (size != null) {
          source = ServedSource.network;
          setHeaders();
        }
      } catch (error, stackTrace) {
        logger.e(
          "Failed to acquire audio from VK",
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    // Ничего не удалось загрузить, грузим placeholder-аудио.
    if (source == null) {
      size = await acquirePlaceholderAudio(bytesController);

      source = ServedSource.placeholder;
      setHeaders();
    }
  }

  /// Пытается загрузить трек [audio] из кэша (если он был кэширован ранее). Во время загрузки аудио с диска, байты трека передаются в [bytesController].
  /// Если что-то идёт не так, и трек оказывается повреждённым, то данный метод попытается исправить метаданные трека.
  /// Данный метод сразу же возвращает размер файла в байтах (если всё прошло успешно), до полной загрузки файла.
  Future<int?> acquireAudioFromCache(
    ExtendedAudio audio,
    ExtendedPlaylist playlist,
    StreamController<Uint8List> bytesController,
  ) async {
    final playlists = _ref.read(playlistsProvider.notifier);

    final file = await getCachedAudioByKey(audio.mediaKey);
    final markedAsCached =
        audio.isCached == true || audio.replacedLocally == true;

    // Узнаём размер файла.
    //
    // Если мы не смогли получить размер файла, то мы предполагаем,
    // что у нас нет доступа к нему, либо же он попросту отсутствует.
    int? fileSize;
    try {
      fileSize = await file.length();
    } catch (error, stackTrace) {
      if (markedAsCached) {
        logger.e(
          "${audio.mediaKey} cached without file present!",
          error: error,
          stackTrace: stackTrace,
        );
        playlists.updatePlaylist(
          playlist.basicCopyWith(
            audiosToUpdate: [
              audio.basicCopyWith(
                isCached: false,
                replacedLocally: false,
              ),
            ],
          ),
          saveInDB: true,
        );
      }

      return null;
    }

    // Здесь мы можем быть почти полностью уверены, что трек и вправду
    // существует на диске, и мы можем его прочитать.
    file.openRead().listen(
      (data) {
        bytesController.add(Uint8List.fromList(data));
      },
      onDone: () async {
        await bytesController.close();

        // Проверки странных случаев:
        //  1. Трек существует, но в БД он помечен словно не кэширован.
        //  2. Трек существует, но в БД имеет неверный размер.
        //  3. Трек существует, но он имеет слишком маленький размер.
        final isNotCached = !markedAsCached;
        final isSizeMismatch =
            audio.cachedSize != null && fileSize != audio.cachedSize;
        final isSmallSize = fileSize! <= corruptedFileSizeBytes;

        if (isNotCached) {
          logger.w("${audio.mediaKey} is not cached");

          playlists.updatePlaylist(
            playlist.basicCopyWith(
              audiosToUpdate: [
                audio.basicCopyWith(
                  isCached: true,
                  cachedSize: fileSize,
                ),
              ],
            ),
            saveInDB: true,
          );
        } else if (isSmallSize || isSizeMismatch) {
          if (isSizeMismatch) {
            logger.e(
              "${audio.mediaKey} file size mismatched: $fileSize vs ${audio.cachedSize}",
            );
          } else {
            logger.w("${audio.mediaKey} has suspicious file size: $fileSize");
          }

          playlists.updatePlaylist(
            playlist.basicCopyWith(
              audiosToUpdate: [
                audio.basicCopyWith(
                  isCached: false,
                  replacedLocally: false,
                ),
              ],
            ),
            saveInDB: true,
          );
          try {
            await file.delete();
          } catch (e) {
            // No-op.
          }
        }
      },
    );

    return fileSize;
  }

  /// Пытается загрузить трек [audio] с серверов ВКонтакте, и передаёт его байты в [bytesController].
  /// После получения информации о размере аудио, метод возвращает его размер в байтах.
  Future<int?> acquireFromNetwork(
    ExtendedAudio audio,
    ExtendedPlaylist? playlist,
    HttpRequest request,
    StreamController<Uint8List> bytesController,
  ) async {
    final dio = _ref.read(dioProvider);
    // TODO: Реализовать систему по парсингу range-request'а, дальше загружать весь трек полностью (одним запросом), но отдавать только часть трека, которая была запрошена.

    final range = request.headers.value("Range");
    final isFullRange = range == null || range == "bytes=0-";
    if (!isFullRange) {
      logger.w("Unexpected range request: \"$range\"");
    }

    // Делаем запрос на сервер ВКонтакте, узнавая размер аудио без его загрузки.
    final Response response = await dio.get(
      audio.url!,
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          "Range": range,
        },
      ),
    );
    final contentLength = int.parse(response.headers.value("content-length")!);

    // Пытаемся загрузить трек.
    response.data!.stream.listen(
      (Uint8List data) {
        bytesController.add(data);
      },
      onDone: () async {
        await bytesController.close();
      },
    );

    return contentLength;
  }

  /// Загружает placeholder-аудио в случае, если при загрузке трека произошла ошибка, и передаёт его байты в [bytesController], возвращая размер файла в байтах.
  ///
  /// Placeholder-аудио используется для того, что бы плеер не останавливался, если произошла ошибка при загрузке трека.
  Future<int> acquirePlaceholderAudio(
    StreamController<Uint8List> bytesController,
  ) async {
    final String? uiLang = navigatorKey.currentContext != null
        ? Localizations.localeOf(navigatorKey.currentContext!).languageCode
        : null;
    final String phLang = uiLang ?? "en";

    final ByteData placeholder = await rootBundle.load(
      "assets/audios/playback-error-$phLang.mp3",
    );
    final Uint8List bytes = placeholder.buffer.asUint8List();
    // TODO: Обработка случая, если placeholder-аудио не найдено.

    bytesController.add(bytes);

    return bytes.length;
  }

  /// Загружает трек [audio] на локальный сервер, после чего выдаёт URL для доступа к этому треку.
  ///
  /// Трек может загружен с памяти, если он уже кэширован, либо же получен с серверов ВКонтакте.
  String fromAudio(
    ExtendedAudio audio,
    ExtendedPlaylist playlist,
  ) {
    if (isWeb) {
      if (audio.url == null) {
        throw UnsupportedError("No audio url is present");
      }

      return audio.url!;
    }

    // Пытаемся найти данный трек в кэше.
    ServedAudio? servedAudio = _servedAudios.getByAudio(audio, playlist);
    if (servedAudio == null) {
      servedAudio ??= ServedAudio(
        playlistOwnerID: playlist.ownerID,
        playlistID: playlist.id,
        ownerID: audio.ownerID,
        id: audio.id,
        key: getLocalServerAudioKey(
          audio.mediaKey + DateTime.now().microsecondsSinceEpoch.toString(),
        ),
        lastAccessed: DateTime.now(),
      );
      _servedAudios.add(servedAudio);
    }

    return Uri.parse(url)
        .replace(
          path: servedAudio.key,
          queryParameters: kDebugMode
              ? {
                  "audio": "${audio.artist} - ${audio.title}",
                  "key": audio.mediaKey,
                }
              : null,
        )
        .toString();
  }
}
