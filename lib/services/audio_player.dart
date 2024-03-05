import "dart:async";
import "dart:collection";
import "dart:convert";
import "dart:io";

import "package:audio_service/audio_service.dart";
import "package:audio_session/audio_session.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:crypto/crypto.dart";
import "package:discord_rpc/discord_rpc.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:just_audio/just_audio.dart";
import "package:palette_generator/palette_generator.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:provider/provider.dart";
import "package:smtc_windows/smtc_windows.dart";

import "../api/vk/shared.dart";
import "../consts.dart";
import "../main.dart";
import "../provider/user.dart";
import "../routes/home.dart";
import "../utils.dart";
import "cache_manager.dart";
import "logger.dart";

/// enum, перечисляющий действия в уведомлениях над треком.
enum MediaNotificationAction {
  /// Переключение состояния shuffle.
  shuffle,

  /// Переключение состояния "нравится" у трека.
  favorite,
}

/// Расширение [StreamAudioSource] для `just_audio`, который воспроизводит аудио по передаваемому [Uri], а после загрузки аудио сохраняет его в кэш.
class CachedStreamedAudio extends StreamAudioSource {
  /// [AppLogger] для этого класса.
  static AppLogger logger = getLogger("CachedStreamedAudio");

  /// Map из [StreamSubscription], который защищает от повторной загрузки одного и того же трека.
  static LinkedHashMap<String, StreamSubscription<List<int>>> downloadQueue =
      LinkedHashMap();

  /// Максимальное значение одновременных загрузок треков в фоне. При превышении этого порога, записи из [downloadQueue] будут отменяться.
  static int maxConcurrentDownloads = 5;

  /// [Uri], введущий к треку.
  ///
  /// Не указав [uri], загрузка происходить не будет. Произойдёт исключение в случае, если [uri] не указан, а [cacheKey] введёт на несуществующий файл.
  final Uri? uri;

  /// Ключ, который будет использоваться для кэширования полностью загруженных треков. Если его не указать, то класс не будет пытаться найти трек в кэше.
  final String cacheKey;

  /// Обложки трека. Если не указывать, кэширование обложек происходить не будет. Указывая это поле, [albumID] не может быть null;
  final Thumbnails? thumbnails;

  /// ID альбома, который ассоциирован с данным треком.
  final int? albumID;

  /// Указывает, будет ли данный трек кэшироваться.
  final bool cacheTrack;

  /// Callback-метод, вызываемый после успешного кэширования этого трека (т.е., сохранения его на диск). Рекомендуется использовать этот метод для сохранения информации о кэшированности на диск.
  final VoidCallback? onCached;

  CachedStreamedAudio({
    required this.cacheKey,
    this.uri,
    this.thumbnails,
    this.albumID,
    this.cacheTrack = false,
    this.onCached,
  });

  /// Возвращает путь к корневой папке, хранящий в себе кэшированные треки.
  static Future<String> getTrackStorageDirectory() async => join(
        (await getApplicationSupportDirectory()).path,
        "audios",
      );

  /// Возвращает объект типа [File] по передаваемому [ExtendedAudio.mediaKey].
  static Future<File> getCachedAudioByKey(String mediaKey) async {
    final String hash = sha512
        .convert(
          utf8.encode(mediaKey),
        )
        .toString();

    return File(
      join(
        await getTrackStorageDirectory(),
        hash.substring(0, 2),
        hash.substring(0, 32),
      ),
    );
  }

  /// Возвращает объект типа [File], либо null, если [cacheKey] не указан.
  Future<File?> getCachedAudio() => getCachedAudioByKey(cacheKey);

  /// Удаляет кэшированный трек из кэша.
  Future<void> delete() async {
    final File cacheFile = (await getCachedAudio())!;

    try {
      cacheFile.deleteSync();
    } catch (e) {
      // No-op.
    }
  }

  /// Загружает обложки и прочую информацию о треке.
  ///
  /// Данный метод обычно вызывается после загрузки самого трека. Данный метод загружает изображения треков разных размеров, помещая их в [CachedNetworkImagesManager].
  static Future<void> downloadThumbnails({
    int? albumID,
    Thumbnails? thumbnails,
  }) async {
    final List<Future> tasks = [];

    // Если файлы обложек уже загружены, то ничего не делаем.
    if (albumID != null && thumbnails != null) {
      final FileInfo? cachedThumb =
          await CachedAlbumImagesManager.instance.getFileFromCache(
        "${albumID}1200",
      );

      if (cachedThumb == null) {
        // Загружаем обложки.
        tasks.add(
          CachedAlbumImagesManager.instance.downloadFile(
            thumbnails.photo68!,
            key: "${albumID}68",
          ),
        );
        tasks.add(
          CachedAlbumImagesManager.instance.downloadFile(
            thumbnails.photo1200!,
            key: "${albumID}1200",
          ),
        );
      }
    }

    await Future.wait(tasks);
  }

  @override
  Future<StreamAudioResponse> request([
    int? start,
    int? end,
  ]) async {
    if (thumbnails != null) {
      assert(
        albumID != null,
        "thumbnails set, but albumID isn't given",
      );
    }

    final File? cacheFile = await getCachedAudio();

    // Если файл кэша уже существует, то мы должны вернуть его, не делая никаких запросов.
    if (cacheFile != null && cacheFile.existsSync()) {
      logger.d(
        "Cache file exists for $cacheKey (${cacheFile.path})",
      );

      final int sourceLength = cacheFile.lengthSync();

      // Запускаем фоновую задачу по получению обложек трека.
      downloadThumbnails(
        albumID: albumID,
        thumbnails: thumbnails,
      );

      return StreamAudioResponse(
        sourceLength: start != null ? sourceLength : null,
        contentLength: (end ?? sourceLength) - (start ?? 0),
        offset: start,
        contentType: "audio/mpeg",
        stream: cacheFile
            .openRead(
              start,
              end,
            )
            .asBroadcastStream(),
      );
    }

    // Кэшированный трек не был найден, загружаем его, и после чего кэшируем.

    if (uri == null) {
      throw Exception(
        "uri is not passed and audio key $cacheKey haven't been yet cached",
      );
    }

    // Создаём HTTPClient, а так же HTTP-запрос.
    // Загрузка содержимого трека находится ниже.
    final HttpClient httpClient = HttpClient();
    final HttpClientRequest request = (await httpClient.getUrl(uri!))
      ..maxRedirects = 20;
    final List<int> trackBytes = [];
    final response = await request.close();
    if (response.statusCode != 200) {
      httpClient.close();

      throw Exception("HTTP Status Error: ${response.statusCode}");
    }

    final Stream<List<int>> responseStream = response.asBroadcastStream();
    final int sourceLength = response.contentLength;

    // Если объектов в очереди загрузки слишком много, то прерываем загрузку самых "старых" записей.
    while (downloadQueue.isNotEmpty &&
        downloadQueue.length >= maxConcurrentDownloads) {
      logger.d(
        "Download queue is big enough (${downloadQueue.length}), cancelling old download for ${downloadQueue.keys.first}",
      );

      downloadQueue.values.first.cancel();
      downloadQueue.remove(downloadQueue.keys.first);
    }

    // Создаём задачу по загрузке данного трека, если таковой ещё не было.
    StreamSubscription<List<int>>? subscription = downloadQueue[cacheKey] ??
        responseStream.listen(
          (List<int> data) {
            trackBytes.addAll(data);
          },
          onDone: () async {
            logger.d(
              "Done downloading track $cacheKey, ${trackBytes.length} bytes",
            );

            // Проверяем длину полученного файла.
            if (trackBytes.length != sourceLength) {
              throw Exception(
                "Download file $cacheKey size mismatch: expected $sourceLength, but got ${trackBytes.length} instead",
              );
            }

            // Сохраняем трек на диск, если нам передан ключ для кэша.
            if (cacheFile != null) {
              cacheFile.createSync(recursive: true);
              cacheFile.writeAsBytesSync(trackBytes);
            }

            downloadQueue.remove(cacheKey);

            // Запускаем задачу по загрузке обложек.
            await downloadThumbnails(
              albumID: albumID,
              thumbnails: thumbnails,
            );

            // Трек был успешно полностью кэширован.
            onCached?.call();
          },
          onError: (Object e, StackTrace stackTrace) {
            logger.e(
              "Error while downloading/caching media $cacheKey",
              error: e,
              stackTrace: stackTrace,
            );

            downloadQueue.remove(cacheKey);
          },
          cancelOnError: true,
        );

    // Сохраняем текущий Stream, что бы в случае повторного запроса его можно было бы получить.
    downloadQueue[cacheKey] = subscription;

    // StreamAudioResponse глупенький: subscription.cancel() не отменяет запрос на стороне just_audio.
    // Ввиду этого, загрузка треков может происходить по несколько раз.
    //
    // FIXME: Пофиксить повторные HTTP-запросы к трекам после вызова subscription.cancel().

    return StreamAudioResponse(
      sourceLength: start != null ? sourceLength : null,
      contentLength: (end ?? sourceLength) - (start ?? 0),
      offset: start,
      contentType: "audio/mpeg",
      stream: responseStream,
    );
  }
}

/// Класс для работы с аудиоплеером.
class VKMusicPlayer {
  /// [AppLogger] для этого класса.
  static AppLogger logger = getLogger("VKMusicPlayer");

  final AudioPlayer _player = AudioPlayer(
    handleInterruptions: false,
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        backBufferDuration: Duration(
          seconds: 10,
        ),
      ),
    ),
  );
  late final List<StreamSubscription> _subscriptions;

  ExtendedPlaylist? _playlist;
  ConcatenatingAudioSource? _queue;
  List<ExtendedAudio>? _audiosQueue;

  VKMusicPlayer() {
    _subscriptions = [
      // События паузы/воспроизведения.
      _player.playingStream.listen(
        (bool playing) async {
          if (playing && !_loaded) {
            _setPlayerLoaded(true);

            await startMusicSession();
          }

          // Обновляем состояние воспроизведения.
          await updateMusicSession();
        },
      ),

      // Обработчик изменения текущего трека.
      sequenceStateStream.listen(
        (SequenceState? state) async {
          if (state == null || currentAudio == null) return;

          _fakeCurrentTrackIndex = null;

          await updateMusicSessionTrack();
          await updateMusicSession();
        },
      ),
    ];

    _initPlayer();
  }

  /// Объект [SMTCWindows] для управления воспроизведения музыкой при помощи глобальных клавиш на Windows.
  ///
  /// Данный объект инициализируется при вызове [_initPlayer], если приложение запущено на Windows.
  SMTCWindows? smtc;

  /// Сессия объекта [AudioSession], который позволяет указать операционным системам то, что воспроизводит данное приложение, а так же даёт возможность обрабатывать события "затыкания" приложения в случае, к примеру, звонка.
  ///
  /// Данный объект инициализируется при вызове [_initPlayer].
  AudioSession? audioSession;

  /// Список из значений [Audio.mediaKey], по которым была запущена задача по созданию цветовой схемы в методе [getColorSchemeAsync].
  final List<String> _colorSchemeItemsQueue = [];

  /// Кэш для объектов типа [ColorScheme] разных изображений по их [Audio.mediaKey].
  Map<String, (ColorScheme, ColorScheme)> imageColorSchemeCache = {};

  /// Флаг для [audioSession], устанавливаемый на значение true в случае, если плеер поставился на паузу из-за внешнего звонка или другой причины.
  bool _pausedExternally = false;

  /// Объект [DiscordRPC], который позволяет транслировать Rich Presence (надпись "сейчас слушает ...") в Discord.
  ///
  /// Инициализируется при вызове метода [_initPlayer]. Устанавливается лишь в случае, если [isDesktop] = true.
  DiscordRPC? discordRPC;

  bool _discordRPCEnabled = false;

  /// Указывает, что Discord Rich Presence включён.
  ///
  /// Для включения/отключения Discord RPC воспользуйтесь методом [setDiscordRPCEnabled];
  bool get discordRPCEnabled => _discordRPCEnabled;

  bool _loaded = false;

  /// [Duration], указывающий, через какое время будет вызван метод [stop], если пользователь не взаимодействовал с плеером указанное время.
  static Duration stopOnPauseTimerDuration = const Duration(minutes: 10);

  /// Указывает, будет ли плеер вызывать метод [stop], если после вызова [pause] не происходило никаких других взаимодействий с плеером.
  bool get allowStopOnPause => _allowStopOnPause;

  bool _allowStopOnPause = true;

  /// [Timer], используемый если [allowStopOnPause] не равен false, создаваемый после вызова [pause], и удаляемый после вызова [play].
  Timer? _pauseStopTimer;

  /// Фейковый индекс трека, который играет в данный момент. Используется, что бы изменение трека после вызовов типа [next] или [previous] происходило мгновенно.
  int? _fakeCurrentTrackIndex;

  /// Указывает, что аудио плеер загружен (т.е., был запущен хоть раз), и его стоит показать в интерфейсе.
  ///
  /// Данное поле всегда true после запуска воспроизведения любого трека, и false после вызова [stop].
  bool get loaded => _loaded;

  final StreamController<bool> _loadedStateController =
      StreamController.broadcast();

  /// Stream, указывающий то, загружен ли плеер или нет. Указывает состояние поля [loaded].
  Stream<bool> get loadedStateStream =>
      _loadedStateController.stream.asBroadcastStream();

  /// Информация о том, играет ли что-то сейчас у плеера или нет.
  ///
  /// Учтите, что это поле может быть true даже в том случае, если идёт буферизация (см. [buffering]).
  ///
  /// Если Вы желаете узнать, запущен или остановлен ли плеер (т.е., состоянеи stopped), то тогда обратитесь к полю [loaded], которое всегда true после запуска воспроизведения любого трека, и false после вызова [stop].
  bool get playing => _player.playing;

  /// Stream, указывающий текущее состояние воспроизведения плеера.
  Stream<bool> get playingStream => _player.playingStream.asBroadcastStream();

  /// Информация о том, идёт ли буферизация (или какая-либо другая загрузка, из-за которой воспроизведение может быть приостановлено).
  bool get buffering => const [
        ProcessingState.buffering,
        ProcessingState.loading,
      ].contains(
        player.playerState.processingState,
      );

  /// Информация о том, насколько был загружен буфер трека.
  Duration get bufferedPosition => _player.bufferedPosition;

  /// Stream, возвращающий информацию о том, насколько был загружен буфер трека.
  Stream<Duration> get bufferedPositionStream =>
      _player.bufferedPositionStream.asBroadcastStream();

  /// Состояние громкости плеера. Возвращает процент, где 0.0 указывает выключенную громкость, а 1.0 - самая высокая громкость.
  double get volume => _player.volume;

  /// Stream, возвращающий события изменения громкости плеера.
  Stream<double> get volumeStream => _player.volumeStream.asBroadcastStream();

  /// Возвращает прогресс воспроизведения текущего трека в виде процента, где 0.0 указывает начало трека, а 1.0 - его конец.
  ///
  /// Возвращает null, если сейчас ничего не играет.
  ///
  /// Если Вам необходим Stream для отслеживания изменения данного поля, то воспользуйтесь [positionStream].
  double get progress => _player.duration != null &&
          _player.duration != Duration.zero &&
          !buffering
      ? clampDouble(
          _player.position.inMilliseconds / _player.duration!.inMilliseconds,
          0.0,
          1.0,
        )
      : 0.0;

  /// Возвращает текущую позицию трека.
  ///
  /// Для полной длительности трека воспользуйтесь полем [duration]. Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  Duration get position => _player.position;

  /// Stream, возвращающий события о изменения текущей позиции воспроизведения.
  ///
  /// Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  Stream<Duration> get positionStream =>
      _player.positionStream.asBroadcastStream();

  /// Возвращает длительность трека.
  ///
  /// Для полной позиции трека воспользуйтесь полем [position]. Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  Duration? get duration => _player.duration;

  /// Stream, возвращающий события о изменения длительности данного трека.
  ///
  /// Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  Stream<Duration?> get durationStream =>
      _player.durationStream.asBroadcastStream();

  /// Возвращает текущее состояние плеера.
  PlayerState get playerState => _player.playerState;

  /// Stream, возвращающий события о изменении состояния плеера.
  Stream<PlayerState> get playerStateStream =>
      _player.playerStateStream.asBroadcastStream();

  /// Возвращет информацию о состоянии плейлиста.
  SequenceState? get sequenceState => _player.sequenceState;

  /// Stream, возвращающий события о изменении текущего плеера.
  Stream<SequenceState?> get sequenceStateStream =>
      _player.sequenceStateStream.asBroadcastStream();

  /// Возвращет информацию о состоянии shuffle.
  bool get shuffleModeEnabled => _player.shuffleModeEnabled;

  /// Stream, возвращающий события о изменении состояния shuffle.
  Stream<bool> get shuffleModeEnabledStream =>
      _player.shuffleModeEnabledStream.asBroadcastStream();

  /// Возвращет информацию о состоянии повтора плейлиста.
  LoopMode get loopMode => _player.loopMode;

  /// Stream, возвращающий события о изменении состояния повтора плейлиста.
  Stream<LoopMode> get loopModeStream =>
      _player.loopModeStream.asBroadcastStream();

  /// Указывает индекс предыдущего трека в очереди. Если очередь пуста, либо это самый первый трек в очереди, то возвращает null.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [previousAudio].
  int? get previousTrackIndex => _player.previousIndex;

  /// Указывает индекс текущего трека в очереди. Если очередь пуста, либо сейчас ничего не играет, то возвращает null.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [currentAudio].
  int? get trackIndex => _player.currentIndex;

  /// Указывает индекс следующего трека в очереди. Если очередь пуста, либо это самый последний трек в очереди, то возвращает null.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [nextAudio].
  int? get nextTrackIndex => _player.nextIndex;

  /// Указывает индекс предыдущего трека в очереди.
  ///
  /// В отличии от [previousTrackIndex], данный метод возвращает трек в зависимости от значений [LoopMode]: если включён повтор плейлиста ([LoopMode.all]), то данный метод будет возвращать последний трек из очереди, если текущий трек самый первый.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [smartPreviousAudio].
  int? get smartPreviousTrackIndex {
    if (loopMode == LoopMode.one) {
      return smartTrackIndex;
    }

    return previousTrackIndex ?? (_audiosQueue ?? []).length - 1;
  }

  /// Указывает индекс текущего трека в очереди.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [smartCurrentAudio].
  int? get smartTrackIndex {
    return _fakeCurrentTrackIndex ?? trackIndex;
  }

  /// Указывает индекс следующего трека в очереди.
  ///
  /// В отличии от [nextTrackIndex], данный метод возвращает трек в зависимости от значений [LoopMode]: если включён повтор плейлиста ([LoopMode.all]), то данный метод будет возвращать последний трек из очереди, если текущий трек самый первый.
  ///
  /// Для получения объекта типа [Audio] можно воспользоваться getter'ом [smartNextAudio].
  int? get smartNextTrackIndex {
    if (loopMode == LoopMode.one) {
      return smartTrackIndex;
    }

    return nextTrackIndex ?? 0;
  }

  /// Возвращает объект [ExtendedAudio] для трека, который находится предыдущим в очереди. Если очередь пуста, либо это самый первый трек в очереди, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [previousTrackIndex].
  ExtendedAudio? get previousAudio {
    if (previousTrackIndex == null) return null;

    return _audiosQueue?[previousTrackIndex!];
  }

  /// Возвращает объект [ExtendedAudio] для трека, который играет в данный момент. Если очередь пуста, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [trackIndex].
  ExtendedAudio? get currentAudio {
    if (trackIndex == null) return null;

    return _audiosQueue?[trackIndex!];
  }

  /// Возвращает объект [ExtendedAudio] для трека, который находится предыдущим в очереди. Если очередь пуста, либо это последний трек в очереди, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [nextTrackIndex].
  ExtendedAudio? get nextAudio {
    if (nextTrackIndex == null) return null;

    return _audiosQueue?[nextTrackIndex!];
  }

  /// Возвращает объект [ExtendedAudio] для трека, который находится предыдущим в очереди. Если очередь пуста, либо это самый первый трек в очереди, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [smartPreviousTrackIndex].
  ExtendedAudio? get smartPreviousAudio {
    if (smartPreviousTrackIndex == null) return null;

    return _audiosQueue?[smartPreviousTrackIndex!];
  }

  /// Возвращает объект [ExtendedAudio] для трека, который играет в данный момент. Если очередь пуста, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [smartTrackIndex].
  ExtendedAudio? get smartCurrentAudio {
    if (smartTrackIndex == null) return null;

    return _audiosQueue?[smartTrackIndex!];
  }

  /// Возвращает объект [ExtendedAudio] для трека, который находится предыдущим в очереди. Если очередь пуста, либо это последний трек в очереди, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [smartNextTrackIndex].
  ExtendedAudio? get smartNextAudio {
    if (smartNextTrackIndex == null) return null;

    return _audiosQueue?[smartNextTrackIndex!];
  }

  /// Возвращает текущий плейлист.
  ///
  /// Учтите, что список треков в этом плейлисте не меняется в зависимости от shuffle или вызова метода [addNextToQueue].
  ExtendedPlaylist? get currentPlaylist => _playlist;

  /// Инициализирует некоторые компоненты данного плеера.
  ///
  /// Данный метод должен быть вызван лишь один раз, при инициализации плеера.
  Future<void> _initPlayer() async {
    // Устанавливаем значение для LoopMode по-умолчанию.
    await setLoop(LoopMode.all);

    // Слушаем события от SMTC, если приложение запущено на Windows.
    if (Platform.isWindows) {
      smtc = SMTCWindows(
        config: const SMTCConfig(
          fastForwardEnabled: true,
          nextEnabled: true,
          pauseEnabled: true,
          playEnabled: true,
          rewindEnabled: true,
          prevEnabled: true,
          stopEnabled: true,
        ),
        enabled: false,
      );

      try {
        smtc!.buttonPressStream.listen((PressedButton event) async {
          switch (event) {
            case PressedButton.play:
              await play();

              break;
            case PressedButton.pause:
              await pause();

              break;
            case PressedButton.next:
              await next();

              break;
            case PressedButton.previous:
              await previous();

              break;
            case PressedButton.stop:
              await stop();

              break;
            default:
              break;
          }
        });
      } catch (e, stackTrace) {
        logger.e(
          "Ошибка при обработке события от SMTC: ",
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    // Инициализируем объект AudioSession, что бы ставить плеер на паузу в случае звонка или другого события.
    if (audioSession == null) {
      audioSession = await AudioSession.instance;

      await audioSession!.configure(
        const AudioSessionConfiguration.music(),
      );

      // События отключения наушников.
      audioSession?.becomingNoisyEventStream.listen((_) {
        player.pause();
      });

      // Другие события системы.
      //
      // К примеру, здесь обрабатываются события звонка на телефон (громкость понижается на 50%), а так же события запуска других аудио-приложений.
      audioSession?.interruptionEventStream.listen((
        AudioInterruptionEvent event,
      ) async {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await player.setVolume(0.5);

              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              if (!playing) return;

              await player.pause();

              // Здесь мы должны запомнить то, что пауза была установлена внешне.
              _pausedExternally = true;

              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await player.setVolume(1.0);

              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              // Мы имеем право на возобновление плеера только в том случае, если пауза была установлена внешне.
              if (!_pausedExternally) return;

              await player.play();
              _pausedExternally = false;

              break;
          }
        }
      });
    }

    // Инициализируем Discord Rich Presence на Desktop-системах.
    if (isDesktop) {
      DiscordRPC.initialize();

      discordRPC = DiscordRPC(
        applicationId: discordAppID.toString(),
      );
      discordRPC!.start(
        autoRegister: true,
      );
      discordRPC!.clearPresence();
    }
  }

  /// Указывает, загружен ли плеер.
  void _setPlayerLoaded(
    bool loaded,
  ) {
    if (loaded == _loaded) return;

    _loaded = loaded;
    _loadedStateController.add(_loaded);
  }

  /// Метод, вызываемый в случае, если плеер был неактивен [stopOnPauseTimerDuration], и [allowStopOnPause] равен true.
  void _stopOnPauseCallback() async {
    logger.d(
      "Forcibly calling stop, because player has been inactive for $stopOnPauseTimerDuration",
    );

    await stop();
  }

  /// Возобновляет воспроизведение музыки у плеера, ранее остановленной при помощи метода [pause].
  ///
  /// Если Вы хотите поставить музыку на паузу или начать воспроизведение в зависимости от значения переменной, то воспользуйтесь методом [playOrPause], который работает следующим образом:
  /// ```dart
  /// if (play) {
  ///   player.play();
  /// } else {
  ///   player.pause();
  /// }
  /// ```
  Future<void> play() async {
    // Если ничего не загружено, то мы не должны запускать воспроизведение.
    if (_queue == null) {
      return;
    }

    _setPlayerLoaded(true);

    return await _player.play();
  }

  /// Приостанавливает воспроизведение музыки, которая ранее была запущена при помощи методов по типу [play].
  ///
  /// Если Вы хотите поставить музыку на паузу или начать воспроизведение в зависимости от значения переменной, то воспользуйтесь методом [playOrPause], который работает следующим образом:
  /// ```dart
  /// if (play) {
  ///   player.play();
  /// } else {
  ///   player.pause();
  /// }
  /// ```
  Future<void> pause() async {
    return await _player.pause();
  }

  /// Вызывает метод [play] или [pause], в зависимости от передаваемого аргумента [playing], указывающий, будет ли плеер играть.
  ///
  /// Данный метод работает следующим образом:
  /// ```dart
  /// if (play) {
  ///   player.play();
  /// } else {
  ///   player.pause();
  /// }
  /// ```
  Future<void> playOrPause(bool playing) async {
    if (playing) {
      return await play();
    }

    return await pause();
  }

  /// Переключает паузу у плеера.
  ///
  /// Данный метод рекомендуется вызывать только в тех случаях, где текущее состояние плеера может быть неизвестным, к примеру, в интерфейсе, где не вызывался метод [setState], или в уведомлениях, которые могут не обновить своё состояние "проигрывания" из-за какой-то ошибки.
  Future<void> togglePlay() async {
    return await playOrPause(!playing);
  }

  /// "Перепрыгивает" на указанный момент в треке.
  ///
  /// Если [play] = true, то при перемотке плеер будет автоматически запущен, если он до этого был приостановлен.
  Future<void> seek(
    Duration position, {
    bool play = false,
  }) async {
    await _player.seek(position);

    if (play && !playing) await _player.play();
  }

  /// "Перепрыгивает" на указанный момент в треке по значению от 0.0 до 1.0.
  ///
  /// Если Вы желаете перепрыгнуть на момент в треке по его времени то воспользуйтесь методом [seek].
  ///
  /// Если [play] = true, то при перемотке плеер будет автоматически запущен, если он до этого был приостановлен.
  Future<void> seekNormalized(
    double position, {
    bool play = false,
  }) async {
    assert(
      volume >= 0.0 && volume <= 1.0,
      "seekNormalized position $position is not in range from 0.0 to 1.0",
    );

    return await seek(
      Duration(
        milliseconds: (duration!.inMilliseconds * position).toInt(),
      ),
      play: play,
    );
  }

  /// Переключает на трек с указанным индексом.
  Future<void> jump(
    int index,
  ) async {
    _fakeCurrentTrackIndex = index;

    return await _player.seek(
      null,
      index: index,
    );
  }

  /// Указывает громкость плеера. Передаваемое значение громкости [volume] обязано быть в пределах от 0.0 до 1.0.
  Future<void> setVolume(double volume) async {
    assert(
      volume >= 0.0 && volume <= 1.0,
      "setVolume given volume $volume is not in range from 0.0 to 1.0",
    );

    return await _player.setVolume(volume);
  }

  /// Останавливает плеер, освобождая ресурсы.
  ///
  /// Данный метод стоит вызывать только в случае, когда пользователь остановил воспроизведение, к примеру, убив приложение или свернув уведомление. Для паузы стоит воспользоваться методом [pause].
  Future<void> stop() async {
    _setPlayerLoaded(false);

    await _player.pause();
    await _player.stop();
    await stopMusicSession();

    _playlist = null;
    _queue = null;
    _audiosQueue = null;
  }

  /// Полностью освобождает ресурсы, занятые данным плеером.
  Future<void> dispose() async {
    await stop();

    for (StreamSubscription subscription in _subscriptions) {
      subscription.cancel();
    }

    return await _player.dispose();
  }

  /// Заставляет плеер "перепрыгнуть" ([seek]) на самое начало воспроизведение текущего трека.
  Future<void> seekToBeginning() async {
    return await seek(Duration.zero);
  }

  /// Запускает воспроизведение следующего трека. Если это последний трек в плейлисте, то ничего не делает.
  Future<void> next() async {
    await jump(nextTrackIndex!);

    if (!playing) await play();
  }

  /// Запускает воспроизведение предыдущего трека в очереди. Если это первый трек в плейлисте, то ничего не делает.
  ///
  /// Если [allowSeekToBeginning] указан как true, то плеер, в случае, если прошло не более 5 секунд воспроизведения, запустит воспроизведение с самого начала трека, вместо перехода на предыдущий.
  Future<void> previous({
    bool allowSeekToBeginning = false,
  }) async {
    if (allowSeekToBeginning && _player.position.inSeconds >= 5) {
      await seekToBeginning();
    } else {
      await jump(previousTrackIndex!);
    }

    if (!playing) await play();
  }

  /// Включает или отключает случайное перемешивание треков в данном плейлисте, в зависимости от аргумента [shuffle].
  Future<void> setShuffle(bool shuffle) async {
    return await _player.setShuffleModeEnabled(shuffle);
  }

  /// Переключает состояние shuffle.
  Future<void> toggleShuffle() async {
    return await setShuffle(!shuffleModeEnabled);
  }

  /// Меняет режим повтора текущего плейлиста/трека.
  Future<void> setLoop(LoopMode loopMode) async {
    return await _player.setLoopMode(loopMode);
  }

  /// Callback-метод, сохраняющий информацию о том, что трек был кэширован.
  void _onTrackCached(ExtendedAudio audio, ExtendedPlaylist playlist) {
    audio.isCached = true;

    final UserProvider user =
        Provider.of<UserProvider>(buildContext!, listen: false);

    user.updatePlaylist(playlist);
    user.markUpdated(false);
  }

  /// Устанавливает плейлист [playlist] для воспроизведения музыки, указывая при этом [index], начиная с которого будет запущено воспроизведение. Если [play] равен true, то при вызове данного метода плеер автоматически начнёт воспроизводить музыку.
  Future<void> setPlaylist(
    ExtendedPlaylist playlist, {
    bool play = true,
    ExtendedAudio? audio,
  }) async {
    assert(
      playlist.audios != null,
      "audios of ExtendedPlaylist is null",
    );

    // Создаём список из треков в плейлисте, которые можно воспроизвести.
    final List<ExtendedAudio> audios = playlist.audios!
        .where(
          (audio) => audio.canPlay,
        )
        .toList();

    // Обработка запуска пустого плейлиста.
    if (audios.isEmpty) return;

    _playlist = playlist;
    _audiosQueue = [...audios];
    _queue = ConcatenatingAudioSource(
      children: audios
          .map(
            (audio) => CachedStreamedAudio(
              cacheKey: audio.mediaKey,
              uri: audio.url != null
                  ? Uri.parse(
                      audio.url!,
                    )
                  : null,
              thumbnails: audio.album?.thumbnails,
              albumID: audio.album?.id,
              cacheTrack: playlist.cacheTracks ?? false,
              onCached: () => _onTrackCached(audio, playlist),
            ),
          )
          .toList(),
    );

    // Указываем, что плеер загружен.
    if (play) {
      _setPlayerLoaded(true);
    }

    // Отправляем плееру очередь из треков.
    await _player.setAudioSource(
      _queue!,
      initialIndex: audios.contains(audio) ? audios.indexOf(audio!) : 0,
    );

    // Если разрешено, сразу же запускаем воспроизведение.
    if (play) {
      await this.play();
    }
  }

  /// Добавляет указанный трек как следующий для воспроизведения.
  Future<void> addNextToQueue(
    ExtendedAudio audio,
  ) async {
    // На случай, если очередь пустая.
    _queue ??= ConcatenatingAudioSource(
      children: [],
    );
    _audiosQueue ??= [];

    _queue!.insert(
      nextTrackIndex ?? 0,
      CachedStreamedAudio(
        cacheKey: audio.mediaKey,
        uri: audio.url != null
            ? Uri.parse(
                audio.url!,
              )
            : null,
        thumbnails: audio.album?.thumbnails,
        albumID: audio.album?.id,
        onCached: () => _onTrackCached(audio, player.currentPlaylist!),
      ),
    );
    _audiosQueue!.insert(
      nextTrackIndex ?? 0,
      audio,
    );
  }

  /// Включает или отключает Discord Rich Presence.
  Future<void> setDiscordRPCEnabled(bool enabled) async {
    logger.d("Called setDiscordRPCEnabled($enabled)");

    if (enabled) {
      assert(
        isDesktop,
        "Discord RPC can only be enabled on Desktop-platforms.",
      );
    }

    if (enabled == _discordRPCEnabled) return;
    _discordRPCEnabled = enabled;

    if (enabled) {
      await updateMusicSession();
    } else {
      discordRPC?.clearPresence();
    }
  }

  /// Включает или отключает автоматический вызов метода [stop] после неактивности плеера ([pause] на длительное время).
  ///
  /// Время, через которое будет вызван [stop] в случае неактивности - [stopOnPauseTimerDuration].
  void setStopOnPauseEnabled(bool enabled) {
    logger.d("Called setStopOnPauseEnabled($enabled)");

    if (enabled == _allowStopOnPause) return;
    _allowStopOnPause = enabled;

    _pauseStopTimer?.cancel();
  }

  /// Запускает музыкальную сессию. При вызове данного метода, плеер активирует различные системы, по типу SMTC для Windows, Discord Rich Presence и прочие.
  ///
  /// Данный метод нужно вызвать после первого запуска плеера. После завершения музыкальной сессии, рекомендуется вызвать метод [stopMusicSession].
  Future<void> startMusicSession() async {
    logger.d("Called startMusicSession");

    // Указываем, что в данный момент идёт сессия музыки.
    await audioSession!.setActive(true);

    if (Platform.isWindows) {
      await smtc?.enableSmtc();
    }

    if (_loaded) return;
  }

  /// Метод, обновляющий данные о музыкальной сессии, отправляя новые данные по текущему треку после вызова метода [startMusicSession].
  ///
  /// Данный метод стоит вызывать после изменения текущего трека.
  Future<void> updateMusicSessionTrack() async {
    logger.d("Called updateMusicSessionTrack");

    if (currentAudio == null) return;

    // Если у пользователя Windows, то посылаем SMTC обновление.
    if (Platform.isWindows) {
      if (!smtc!.enabled) await smtc!.enableSmtc();

      await smtc?.updateMetadata(
        MusicMetadata(
          title: currentAudio!.title,
          artist: currentAudio!.artist,
          albumArtist: currentAudio!.artist,
          album: currentAudio!.album?.title,
          thumbnail: currentAudio!.album?.thumbnails?.photo1200,
        ),
      );
    }
  }

  /// Метод, обновляющий данные о музыкальной сессии после вызова метода [startMusicSession].
  ///
  /// Данный метод рекомендуется вызывать только при событиях изменения состояния плеера, например, начало буферизации, паузы/воспроизведения и/ли подобных.
  Future<void> updateMusicSession() async {
    logger.d("Called updateMusicSession");

    // Указываем, есть ли у нас в данный момент сессия музыки.
    await audioSession?.setActive(playing);

    // Если у пользователя Windows, то обновляем параметры SMTC.
    if (Platform.isWindows) {
      PlaybackStatus status = PlaybackStatus.Stopped;

      if (buffering) {
        status = PlaybackStatus.Changing;
      } else if (!loaded) {
        status = PlaybackStatus.Stopped;
      } else if (playing) {
        status = PlaybackStatus.Playing;
      } else if (!playing) {
        status = PlaybackStatus.Paused;
      }

      await smtc?.setPlaybackStatus(status);
    }

    // Обновляем Discord RPC, если это разрешено пользователем.
    if (discordRPCEnabled && currentAudio != null) {
      discordRPC?.updatePresence(
        DiscordPresence(
          state: currentAudio!.title,
          details: currentAudio!.artist,
          largeImageKey: "flutter-vk-logo",
          largeImageText: "Flutter VK",
          smallImageKey: playing ? "playing" : "paused",
          smallImageText: playing
              ? "${currentAudio!.artist} • ${currentAudio!.title}"
              : null,
          startTimeStamp: playing
              ? (DateTime.now().millisecondsSinceEpoch ~/ 1000) -
                  position.inSeconds
              : null,
        ),
      );
    }

    // Запускаем таймер паузы, если установлена пауза.
    _pauseStopTimer?.cancel();

    if (!playing && _loaded && _allowStopOnPause) {
      // Запускаем таймер.
      _pauseStopTimer = Timer(stopOnPauseTimerDuration, _stopOnPauseCallback);
    }
  }

  /// Останавливает текущую музыкальную сессию, ранее начатую вызовом метода [startMusicSession].
  ///
  /// Данный метод стоит вызывать только после остановки музыкальной сессии, т.е., после вызова метода [stop].
  Future<void> stopMusicSession() async {
    logger.d("Called stopMusicSession");

    if (Platform.isWindows) {
      await smtc?.disableSmtc();
    }

    await audioSession?.setActive(false);
    if (discordRPCEnabled) {
      discordRPC?.clearPresence();
    }

    _pauseStopTimer?.cancel();
  }

  /// Создаёт две цветовых схемы из цветов плеера: [Brightness.light] и [Brightness.dark].
  ///
  /// Данный метод при повторном вызове (если уже идёт процесс создания цветовой схемы) возвращает null. Результаты данного метода кэшируются, поэтому можно повторно вызывать этот метод, если [Audio.mediaKey] одинаков.
  Future<(ColorScheme, ColorScheme)?> getColorSchemeAsync() async {
    final AppLogger logger = getLogger("getColorSchemeAsync");
    final Stopwatch watch = Stopwatch()..start();

    // Если у изображения трека нету фотографии, либо задача уже запущена, то возвращаем null.
    if (player.currentAudio?.album?.thumbnails == null ||
        _colorSchemeItemsQueue.contains(
          player.currentAudio!.mediaKey,
        )) return null;

    final String cacheKey = "${player.currentAudio!.album!.id}68";

    // Пытаемся извлечь значение цветовых схем из кэша.
    if (imageColorSchemeCache.containsKey(cacheKey)) {
      return imageColorSchemeCache[cacheKey];
    }

    // Задача по созданию цветовой схемы не находится в очереди, поэтому помещаем задачу в очередь.
    _colorSchemeItemsQueue.add(cacheKey);

    logger.d("Creating ColorScheme for $cacheKey");

    // Извлекаем цвета из изображения, делая объект PaletteGenerator.
    final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
      CachedNetworkImageProvider(
        player.currentAudio!.album!.thumbnails!.photo68!,
        cacheKey: cacheKey,
        cacheManager: CachedNetworkImagesManager.instance,
      ),
    );

    // Превращаем наш PaletteGenerator в цветовые схемы.
    final ColorScheme lightScheme = palette.dominantColor != null
        ? ColorScheme.fromSeed(
            seedColor: palette.dominantColor!.color,
          )
        : fallbackLightColorScheme;
    final ColorScheme darkScheme = palette.dominantColor != null
        ? ColorScheme.fromSeed(
            seedColor: palette.dominantColor!.color,
            brightness: Brightness.dark,
          )
        : fallbackDarkColorScheme;

    imageColorSchemeCache[cacheKey] = (lightScheme, darkScheme);

    logger.d("Done building ColorScheme for $cacheKey, took ${watch.elapsed}");

    // Удаляем из очереди.
    _colorSchemeItemsQueue.remove(cacheKey);

    return imageColorSchemeCache[cacheKey];
  }
}

/// Расширение для класса [BaseAudioHandler], методы которого вызываются при взаимодействии с медиа-уведомлением.
class AudioPlayerService extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final VKMusicPlayer _player;

  AudioPlayerService(
    this._player,
  ) {
    // События состояния плеера.
    _player.playerStateStream.listen((PlayerState state) async {
      if (!player.playing) return;

      await _updateEvent();
    });

    // События паузы/воспроизведения/...
    _player.playingStream.listen((bool playing) async {
      if (!playing) return;

      await _updateEvent();
    });

    // События изменения позиции плеера.
    _player.positionStream.listen((Duration position) async {
      await _updateEvent();
    });

    // События изменения плейлиста.
    _player.sequenceStateStream.listen((SequenceState? state) async {
      if (state == null) return;

      await _updateTrack();
    });

    // События остановки/первого запуска (загрузки) плеера.
    _player.loadedStateStream.listen((bool loaded) async {
      await _updateEvent();
    });

    // События изменения состояния shuffle.
    _player.shuffleModeEnabledStream.listen((bool enabled) async {
      await _updateEvent();
    });
  }

  /// Отправляет изменения состояния воспроизведения в `audio_service`, обновляя информацию, отображаемую в уведомлении.
  Future<void> _updateEvent() async {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.custom(
            androidIcon: _player.shuffleModeEnabled
                ? "drawable/ic_shuffle_enabled"
                : "drawable/ic_shuffle",
            label: "Shuffle",
            name: MediaNotificationAction.shuffle.name,
          ),
          MediaControl.custom(
            androidIcon: _player.currentAudio?.isLiked ?? false
                ? "drawable/ic_favorite"
                : "drawable/ic_favorite_outline",
            label: "Favorite",
            name: MediaNotificationAction.favorite.name,
          ),
        ],
        systemActions: {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 2],
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        shuffleMode: player.shuffleModeEnabled == true
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        repeatMode: _player.loopMode == LoopMode.one
            ? AudioServiceRepeatMode.one
            : AudioServiceRepeatMode.none,
        processingState: _player.loaded
            ? _player.buffering
                ? AudioProcessingState.loading
                : AudioProcessingState.ready
            : AudioProcessingState.idle,
      ),
    );
  }

  /// Отправляет новый трек в уведомление.
  Future<void> _updateTrack() async {
    if (!_player.loaded) return;

    mediaItem.add(_player.currentAudio?.asMediaItem);
  }

  @override
  Future<void> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    final UserProvider user = Provider.of<UserProvider>(
      buildContext!,
      listen: false,
    );

    final MediaNotificationAction action =
        MediaNotificationAction.values.firstWhere(
      (action) => action.name == name,
    );

    switch (action) {
      case (MediaNotificationAction.shuffle):
        await _player.toggleShuffle();

        user.settings.shuffleEnabled = _player.shuffleModeEnabled;
        user.markUpdated(false);

        break;

      case (MediaNotificationAction.favorite):
        if (!connectivityManager.hasConnection) return;

        await toggleTrackLike(
          user,
          _player.currentAudio!,
          !_player.currentAudio!.isLiked,
        );

        await _updateEvent();

        user.updatePlaylist(player.currentPlaylist!);
        user.markUpdated(false);

        break;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> onTaskRemoved() => _player.stop();

  @override
  Future<void> onNotificationDeleted() => _player.stop();

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await super.setShuffleMode(shuffleMode);

    await _player.setShuffle(
      shuffleMode == AudioServiceShuffleMode.all,
    );
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await super.setRepeatMode(repeatMode);

    await _player.setLoop(
      repeatMode == AudioServiceRepeatMode.one ? LoopMode.one : LoopMode.all,
    );
  }

  @override
  Future<void> skipToNext() async {
    await _player.next();

    await super.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.previous(
      allowSeekToBeginning: true,
    );

    await super.skipToPrevious();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}
