import "dart:async";
import "dart:io";
import "dart:math";

import "package:audio_service/audio_service.dart";
import "package:audio_session/audio_session.dart";
import "package:collection/collection.dart";
import "package:discord_rpc/discord_rpc.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:just_audio/just_audio.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:smtc_windows/smtc_windows.dart";

import "../api/vk/shared.dart";
import "../consts.dart";
import "../enums.dart";
import "../main.dart";
import "../provider/dio.dart";
import "../provider/player.dart";
import "../provider/playlists.dart";
import "../provider/preferences.dart";
import "../provider/user.dart";
import "../routes/home/music.dart";
import "../utils.dart";
import "cache_manager.dart";
import "logger.dart";

/// enum, перечисляющий действия в уведомлениях над треком.
enum MediaNotificationAction {
  /// Переключение состояния shuffle. Показывается у не-рекомендуемых треках.
  shuffle,

  /// Переключение состояния "нравится" у трека.
  favorite,

  /// Установка "дизлайка" у трека. Показывается только у рекомендуемых треков.
  dislike,
}

/// Расширение [StreamAudioSource] для `just_audio`, который воспроизводит аудио по передаваемому [Uri], а после загрузки аудио сохраняет его в кэш.
class CachedStreamAudioSource extends StreamAudioSource {
  static final AppLogger logger = getLogger("CachedStreamedAudio");

  /// Размер `.mp3`-файла в байтах, который считается повреждённым.
  static const int corruptedFileSizeBytes = 100 * 1024;

  /// [Ref] для определения того, будет ли трек кэшироваться после загрузки плеером.
  final Ref _ref;

  /// Трек, данные которого будут загружаться.
  final ExtendedAudio audio;

  /// Плейлист, в котором находится данный трек.
  final ExtendedPlaylist playlist;

  /// Возвращает путь к корневой папке, хранящий в себе кэшированные треки.
  ///
  /// К примеру, на Windows это `%APPDATA%/com.zensonaton/Flutter VK/audios-v2`.
  static Future<String> getTrackStorageDirectory() async => join(
        (await getApplicationSupportDirectory()).path,
        "audios-v2",
      );

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
        hash.substring(0, 2), // Папка
        hash.substring(0, 32), // Файл
      ),
    );
  }

  /// Возвращает объект типа [File], олицетворяющий файл кэша для данного трека.
  ///
  /// Учтите, что данный метод не проверяет на существование файла. Для проверки на существование файла воспользуйтесь методом [File.existsSync].
  Future<File> getAudioCacheFile() => getCachedAudioByKey(audio.mediaKey);

  CachedStreamAudioSource({
    required Ref ref,
    required this.audio,
    required this.playlist,
  }) : _ref = ref;

  /// Загружает трек из кэша, и возвращает [StreamAudioResponse]. Если кэшированного трека нет, то возвращает null.
  ///
  /// Если по какой-то причине кэш поломан (скажем, [ExtendedAudio.isCached] но файла нет или наоборот), то данный метод может пометить трек как (не-)кэшированный.
  Future<StreamAudioResponse?> acquireCache({int? start, int? end}) async {
    final playlists = _ref.read(playlistsProvider.notifier);
    final file = await getAudioCacheFile();
    final fileExists = file.existsSync();
    final markedAsCached =
        audio.isCached == true || audio.replacedLocally == true;
    bool? newCachedState;
    int? newFileSize;

    // Логирование и обработка странных случаев:
    //  1. Трек помечен как кэшированный, но файл кэша не найден.
    //  2. Трек не помечен как кэшированный, но файл кэша найден.
    //
    // Ниже есть ещё один случай, если файл, вероятнее всего, повреждён.
    if (markedAsCached && !fileExists) {
      logger.w(
        "Expected audio ${audio.mediaKey} to have cache file; will mark as not cached",
      );

      newCachedState = false;
    } else if (!markedAsCached && fileExists) {
      logger.w(
        "Audio ${audio.mediaKey} is not marked as cached, but cache file was found; will mark as cached",
      );
      logger.d(
        "Cache file: ${file.path}",
      );

      newCachedState = true;
      newFileSize ??= file.lengthSync();
    }

    // Случай, если по какой-то причине файл кэша повреждён (например, его размер не соответствует длине трека).
    //
    // Данный случай был реализован, поскольку Flutter VK кэшировал .m3u8 как .mp3, и это было ошибкой.
    // Здесь мы будем считать, что если файл имеет размер менее 100 КБ, то он повреждён.
    if ((markedAsCached && newCachedState != false) || newCachedState == true) {
      newFileSize ??= file.lengthSync();

      final bool smallSize = newFileSize <= corruptedFileSizeBytes;
      final bool sizeMismatch =
          audio.cachedSize != null && newFileSize != audio.cachedSize;

      if (smallSize || sizeMismatch) {
        if (sizeMismatch) {
          logger.e(
            "Found audio ${audio.mediaKey} with size mismatch ($newFileSize real vs ${audio.cachedSize} as reported by DB); file ${file.path} will be deleted",
          );
        } else {
          logger.w(
            "Found audio ${audio.mediaKey} with suspiciously small size ($newFileSize bytes); file ${file.path} will be deleted",
          );
        }

        newCachedState = false;
        newFileSize = null;
        try {
          await file.delete();
        } catch (e) {
          // No-op.
        }
      }
    }

    // Изменяем состояние кэша трека, если он ранее изменился.
    if (newCachedState != null) {
      playlists.updatePlaylist(
        playlist.basicCopyWith(
          audiosToUpdate: [
            audio.basicCopyWith(
              isCached: newCachedState,
              cachedSize: newFileSize,
            ),
          ],
        ),
        saveInDB: true,
      );
    }

    // Файл кэша не существует.
    if (!fileExists || newCachedState == false) return null;

    final int length = newFileSize ?? file.lengthSync();

    return StreamAudioResponse(
      sourceLength: start != null ? length : null,
      contentLength: (end ?? length) - (start ?? 0),
      offset: start,
      contentType: "audio/mpeg",
      stream: file.openRead(start, end).asBroadcastStream(),
    );
  }

  /// Загружает трек, и возвращает [StreamAudioResponse].
  Future<StreamAudioResponse> fetch({int? start, int? end}) async {
    if (audio.url == null) {
      throw Exception("Audio URL is null");
    }
    if (!audio.url!.contains(".mp3")) {
      throw Exception("Expected audio URL to be mp3 file");
    }

    // Подготавливаем запрос на загрузку трека.
    // Здесь трек не загружется, а просто извлекается информация по его размеру.
    final request = await httpClient.getUrl(Uri.parse(audio.url!))
      ..headers.add("Range", "bytes=${start ?? 0}-");
    final response = await request.close();
    if (response.statusCode >= 300) {
      throw Exception("HTTP Status Error: ${response.statusCode}");
    }

    // Извлекаем размер.
    final int length = response.contentLength + (start ?? 0);
    // logger.d(
    //   "Content length for ${audio.mediaKey}: $length, range: $start-$end",
    // );

    return StreamAudioResponse(
      sourceLength: start != null ? length : null,
      contentLength: (end ?? length) - (start ?? 0),
      offset: start,
      contentType: "audio/mpeg",
      stream: response.asBroadcastStream(),
    );
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // Пытаемся загрузить трек из кэша.
    final cacheFile = await acquireCache();
    if (cacheFile != null) {
      return cacheFile;
    }

    // Загружаем трек.
    return await fetch(start: start, end: end);
  }
}

/// Класс для работы с аудиоплеером.
class VKMusicPlayer {
  static final AppLogger logger = getLogger("VKMusicPlayer");

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

  final VkMusicPlayerRef ref;

  VKMusicPlayer({
    required this.ref,
  }) {
    _subscriptions = [
      // События паузы/воспроизведения.
      _player.playingStream.listen(
        (bool playing) async {
          if (!playing) return;

          // Убираем флаг, установленный функцией "пауза при миниамльной громкости".
          _pausedDueMute = false;

          // Если мы запустили воспроизведение, но плеер ещё не был загружен, то помечаем это.
          if (!loaded) {
            _setPlayerLoaded(true);

            await startMusicSession();
          }
        },
      ),

      // Обработчик изменения текущего трека.
      currentIndexStream.listen(
        (int? index) async {
          if (index == null || currentAudio == null) return;

          await updateMusicSessionTrack();
        },
      ),

      // Обработчик изменения состояния плеера (пауза, воспроизведение, буферизация).
      playerStateStream.listen((PlayerState state) async {
        _fakeCurrentPosition = null;

        await updateMusicSession();
      }),

      // Обработчик громкости.
      _player.volumeStream.listen((double volume) async {
        // Если включена опция "пауза при минимальной громкости".
        if (_pauseOnMuteEnabled) {
          if (playing && volume == 0.0) {
            logger.d("Player is muted, pausing");
            _pausedDueMute = true;

            await pause();
          } else if (!playing && _pausedDueMute && volume > 0.0) {
            await play();

            _pausedDueMute = false;
          }
        }

        // Запускаем таймер для сохранения громкости на диск, если плеер загружен.
        _volumeSaveTimer?.cancel();
        if (loaded) {
          _volumeSaveTimer = Timer(
            const Duration(seconds: 2),
            () {
              logger.d("Will save player volume ($volume) to disk");

              ref.read(preferencesProvider.notifier).setVolume(volume);
            },
          );
        }
      }),

      // Обработчик событий плеера.
      _player.playbackEventStream.listen(
        (event) {},
        onError: (Object error, StackTrace stackTrace) {
          if (error is PlatformException) {
            logger.e(
              "Player platform exception, code ${error.code}, message: ${error.message}:",
              error: error,
              stackTrace: stackTrace,
            );
          } else {
            logger.e(
              "Player non-platform exception:",
              error: error,
              stackTrace: stackTrace,
            );
          }

          // TODO: Останавливать плеер, если что-то пошло не так при воспроизведении.
        },
      ),

      // Обработчик событий изменения плейлистов.
      PlaylistsState.playlistModificationsStream.listen((playlist) {
        final bool isCurrent = playlist.ownerID == currentPlaylist?.ownerID &&
            playlist.id == currentPlaylist?.id;

        // Если играет не этот плейлист, то ничего не делаем.
        if (!isCurrent) return;

        logger.d("Player detected playlist modification");

        // Устанавливаем новый плейлист.
        _silentSetPlaylist(
          playlist,
          mergeWithOldQueue: true,
        );

        // Создаём событие об изменении текущего трека.
        _playlistModificationsController.add(playlist);

        // Обновляем информацию о треке.
        updateMusicSessionTrack();
      }),
    ];

    _initPlayer();
  }

  /// Объект [SMTCWindows] для управления воспроизведения музыкой при помощи глобальных клавиш на Windows.
  ///
  /// Данный объект инициализируется при вызове [_initPlayer], если приложение запущено на Windows.
  SMTCWindows? _smtc;

  /// Сессия объекта [AudioSession], который позволяет указать операционным системам то, что воспроизводит данное приложение, а так же даёт возможность обрабатывать события "затыкания" приложения в случае, к примеру, звонка.
  ///
  /// Данный объект инициализируется при вызове [_initPlayer].
  AudioSession? _audioSession;

  /// Объект типа [AudioPlayerService], создающий медиа-уведомление для Android с кнопками для управления воспроизведения.
  ///
  /// Данный объект инициализируется при вызове [_initPlayer].
  AudioPlayerService? _audioService;

  /// Флаг для [_audioSession], устанавливаемый на значение true в случае, если плеер поставился на паузу из-за внешнего звонка или другой причины.
  bool _pausedExternally = false;

  /// Указывает, что Discord Rich Presence включён.
  ///
  /// Для включения/отключения Discord RPC воспользуйтесь методом [setDiscordRPCEnabled];
  bool get discordRPCEnabled => _discordRPCEnabled;

  bool _discordRPCEnabled = false;

  /// Объект [DiscordRPC], который позволяет транслировать Rich Presence (надпись "сейчас слушает ...") в Discord.
  ///
  /// Инициализируется при вызове метода [_initPlayer]. Устанавливается лишь в случае, если [isDesktop] = true.
  DiscordRPC? _discordRPC;

  bool _loaded = false;

  /// [Duration], указывающий, через какое время будет вызван метод [stop], если пользователь не взаимодействовал с плеером указанное время.
  static Duration stopOnPauseTimerDuration = const Duration(minutes: 10);

  /// Указывает, будет ли плеер вызывать метод [stop], если после вызова [pause] не происходило никаких других взаимодействий с плеером.
  bool get allowStopOnPause => _allowStopOnPause;

  bool _allowStopOnPause = false;

  /// [Timer], используемый если [allowStopOnPause] не равен false, создаваемый после вызова [pause], и удаляемый после вызова [play].
  Timer? _pauseStopTimer;

  /// Фейковый индекс трека, который играет в данный момент. Используется, что бы изменение трека после вызовов типа [next] или [previous] происходило мгновенно.
  int? _fakeCurrentTrackIndex;

  /// Указывает, будет ли плеер вызывать паузу ([pause]) в том случае, если громкость ([volume]) была установлена на минимум.
  bool get pauseOnMute => _pauseOnMuteEnabled;

  bool _pauseOnMuteEnabled = false;

  bool _pausedDueMute = false;

  /// [Timer], создаваемый после вызова [setVolume], сохраняющий громкость плеера на диск после вызова.
  Timer? _volumeSaveTimer;

  bool _shouldRestoreShuffle = false;

  /// Указывает, что аудио плеер загружен (т.е., был запущен хоть раз), и его стоит показать в интерфейсе.
  ///
  /// Данное поле всегда true после запуска воспроизведения любого трека, и false после вызова [stop].
  bool get loaded => _loaded;

  final StreamController<bool> _loadedStateController =
      StreamController.broadcast();

  /// {@template VKMusicPlayer.loadedStateStream}
  /// Stream, указывающий то, загружен ли плеер или нет. Указывает состояние поля [loaded].
  /// {@endtemplate}
  Stream<bool> get loadedStateStream =>
      _loadedStateController.stream.asBroadcastStream();

  final StreamController<ExtendedPlaylist> _playlistModificationsController =
      StreamController.broadcast();

  /// {@template VKMusicPlayer.playlistModificationsStream}
  /// Stream, указывающий то, что произошло событие изменения текущего плейлиста.
  /// {@endtemplate}
  Stream<ExtendedPlaylist> get playlistModificationsStream =>
      _playlistModificationsController.stream.asBroadcastStream();

  /// Фейковое время для [seek]'а. Используется, что бы значение прослушанности трека после вызова [seek] происходило мгновенно.
  Duration? _fakeCurrentPosition;

  final StreamController<Duration> _seekStateController =
      StreamController.broadcast();

  /// {@template VKMusicPlayer.seekStateStream}
  /// Stream, указывающий события вызова метода [seek].
  /// {@endtemplate}
  Stream<Duration> get seekStateStream =>
      _seekStateController.stream.asBroadcastStream();

  /// Информация о том, играет ли что-то сейчас у плеера или нет.
  ///
  /// Учтите, что это поле может быть true даже в том случае, если идёт буферизация (см. [buffering]).
  ///
  /// Если Вы желаете узнать, запущен или остановлен ли плеер (т.е., состоянии stopped), то тогда обратитесь к полю [loaded], которое всегда true после запуска воспроизведения любого трека, и false после вызова [stop].
  bool get playing => _player.playing;

  /// {@template VKMusicPlayer.playingStream}
  /// Stream, указывающий текущее состояние воспроизведения плеера.
  /// {@endtemplate}
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

  /// {@template VKMusicPlayer.bufferedPositionStream}
  /// Stream, возвращающий информацию о том, насколько был загружен буфер трека.
  /// {@endtemplate}
  Stream<Duration> get bufferedPositionStream =>
      _player.bufferedPositionStream.asBroadcastStream();

  /// Состояние громкости плеера. Возвращает процент, где 0.0 указывает выключенную громкость, а 1.0 - самая высокая громкость.
  double get volume => _player.volume;

  /// {@template VKMusicPlayer.volumeStream}
  /// Stream, возвращающий события изменения громкости плеера.
  /// {@endtemplate}
  Stream<double> get volumeStream => _player.volumeStream.asBroadcastStream();

  /// Возвращает прогресс воспроизведения текущего трека в виде процента, где 0.0 указывает начало трека, а 1.0 - его конец.
  ///
  /// Возвращает null, если сейчас ничего не играет.
  ///
  /// Если Вам необходим Stream для отслеживания изменения данного поля, то воспользуйтесь [positionStream].
  double get progress {
    if (_player.duration == null || _player.duration == Duration.zero) {
      return 0.0;
    }

    final position = _fakeCurrentPosition ?? _player.position;
    final duration = _player.duration!;

    return (position.inMilliseconds / duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  /// Возвращает текущую позицию воспроизведения трека. Данное поле может возвращать слегка другое значение, если был вызван метод [seek] или ему подобные, что бы мгновенно изменить позицию воспроизведения после вызова. Если Вам нужно истинное значение, то воспользуйтесь полем [realPosition], которое возвращает реальное значение позиции воспроизведения даже если был вызван метод [seek].
  ///
  /// Для полной длительности трека воспользуйтесь полем [duration]. Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  Duration get position => _fakeCurrentPosition ?? _player.position;

  /// Возвращает реальное значение позиции воспроизведения даже если был вызван метод [seek].
  Duration get realPosition => _player.position;

  /// {@template VKMusicPlayer.positionStream}
  /// Stream, возвращающий события о изменения текущей позиции воспроизведения.
  ///
  /// Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  /// {@endtemplate}
  Stream<Duration> get positionStream => _player.positionStream;

  /// Возвращает длительность трека.
  ///
  /// Для полной позиции трека воспользуйтесь полем [position]. Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  Duration? get duration => _player.duration;

  /// {@template VKMusicPlayer.durationStream}
  /// Stream, возвращающий события о изменения длительности данного трека.
  ///
  /// Если Вам необходим процент (число от 0.0 до 1.0), отображающий прогресс прослушивания текущего трека, то для этого есть поле [progress].
  /// {@endtemplate}
  Stream<Duration?> get durationStream =>
      _player.durationStream.asBroadcastStream();

  /// Возвращает текущее состояние плеера.
  PlayerState get playerState => _player.playerState;

  /// {@template VKMusicPlayer.playerStateStream}
  /// Stream, возвращающий события о изменении состояния плеера.
  /// {@endtemplate}
  Stream<PlayerState> get playerStateStream =>
      _player.playerStateStream.asBroadcastStream();

  /// Возвращет информацию о состоянии плейлиста.
  SequenceState? get sequenceState => _player.sequenceState;

  /// {@template VKMusicPlayer.sequenceStateStream}
  /// Stream, возвращающий события о изменении параметров плейлиста, играющего в данный момент.
  ///
  /// Если Вам нужен Stream, возвращающий события при изменении текущего трека то воспользуйтесь [currentIndexStream].
  /// {@endtemplate}
  Stream<SequenceState?> get sequenceStateStream =>
      _player.sequenceStateStream.asBroadcastStream();

  /// {@template VKMusicPlayer.currentIndexStream}
  /// Stream, возвращающий события о изменении индекса текущего трека.
  /// {@endtemplate}
  Stream<int?> get currentIndexStream =>
      _player.currentIndexStream.asBroadcastStream();

  /// Возвращет информацию о состоянии shuffle.
  bool get shuffleModeEnabled => _player.shuffleModeEnabled;

  /// {@template VKMusicPlayer.shuffleModeEnabledStream}
  /// Stream, возвращающий события о изменении состояния shuffle.
  /// {@endtemplate}
  Stream<bool> get shuffleModeEnabledStream =>
      _player.shuffleModeEnabledStream.asBroadcastStream();

  /// Возвращет информацию о состоянии повтора плейлиста.
  LoopMode get loopMode => _player.loopMode;

  /// {@template VKMusicPlayer.loopModeStream}
  /// Stream, возвращающий события о изменении состояния повтора плейлиста.
  /// {@endtemplate}
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

    return _audiosQueue?.elementAtOrNull(smartPreviousTrackIndex!);
  }

  /// Возвращает объект [ExtendedAudio] для трека, который играет в данный момент. Если очередь пуста, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [smartTrackIndex].
  ExtendedAudio? get smartCurrentAudio {
    if (smartTrackIndex == null) return null;

    return _audiosQueue?.elementAtOrNull(smartTrackIndex!);
  }

  /// Возвращает объект [ExtendedAudio] для трека, который находится предыдущим в очереди. Если очередь пуста, либо это последний трек в очереди, то возвращает null.
  ///
  /// Для получения индекса этого трека можно воспользоваться getter'ом [smartNextTrackIndex].
  ExtendedAudio? get smartNextAudio {
    if (smartNextTrackIndex == null) return null;

    return _audiosQueue?.elementAtOrNull(smartNextTrackIndex!);
  }

  final StreamController<ExtendedPlaylist?> _currentPlaylistStateController =
      StreamController.broadcast();

  /// {@template VKMusicPlayer.currentPlaylistStream}
  /// [Stream], возвращающий события об изменении текущего плейлиста.
  /// {@endtemplate}
  ///
  /// Не путайте с [playlistModificationsStream], который возвращает события об *изменении* текущего плейлиста (например, изменения трека), этот [Stream] возвращает события о *установке* текущего плейлиста.
  Stream<ExtendedPlaylist?> get currentPlaylistStream =>
      _currentPlaylistStateController.stream.asBroadcastStream();

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

    // Регистрируем AudioHandler для управления музыки при помощи медиа-уведомления на OS Android.
    _audioService = await AudioService.init(
      builder: () => AudioPlayerService(player, ref),
      config: const AudioServiceConfig(
        androidNotificationChannelName: "Flutter VK",
        androidNotificationChannelId: "com.zensonaton.fluttervk",
        androidNotificationIcon: "drawable/ic_music_note",
        androidStopForegroundOnPause: false,
        preloadArtwork: true,
      ),
      cacheManager: CachedAlbumImagesManager.instance,
      cacheKeyResolver: (MediaItem item) => "${item.extras!["mediaKey"]!}max",
    );

    // Слушаем события от SMTC, если приложение запущено на Windows.
    if (Platform.isWindows) {
      _smtc = SMTCWindows(
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
        _smtc!.buttonPressStream.listen((PressedButton button) async {
          switch (button) {
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
              await smartPrevious(viaNotification: true);

              break;
            case PressedButton.stop:
              await stop();

              break;
            default:
              break;
          }
        });
      } catch (error, stackTrace) {
        logger.e(
          "SMTC event error: ",
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    // Инициализируем объект AudioSession, что бы ставить плеер на паузу в случае звонка или другого события.
    if (_audioSession == null) {
      _audioSession = await AudioSession.instance;

      await _audioSession!.configure(
        const AudioSessionConfiguration.music(),
      );

      // События отключения наушников.
      _audioSession?.becomingNoisyEventStream.listen((_) {
        logger.d("Becoming noisy, calling pause");

        player.pause();
      });

      // Другие события системы.
      //
      // К примеру, здесь обрабатываются события звонка на телефон (громкость понижается на 50%), а так же события запуска других аудио-приложений.
      _audioSession?.interruptionEventStream.listen((
        AudioInterruptionEvent event,
      ) async {
        logger.d(
          "Interruption event! ${event.type}, beginning: ${event.begin}",
        );

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

      _discordRPC = DiscordRPC(
        applicationId: discordAppID.toString(),
      );
      _discordRPC!.start(
        autoRegister: true,
      );
      _discordRPC!.clearPresence();
    }
  }

  /// Указывает, загружен ли плеер.
  void _setPlayerLoaded(bool loaded) {
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
    if (_queue == null || playing) return;

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
    if (!playing) return;

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
    _fakeCurrentPosition = position;
    _seekStateController.add(position);

    await _player.seek(position);
    _fakeCurrentPosition = null;

    if (play && !playing) await _player.play();
  }

  /// "Перепрыгивает" на указанный момент в треке по значению от 0.0 до 1.0.
  ///
  /// Если Вы желаете перепрыгнуть на момент в треке по его времени ([Duration]) то воспользуйтесь методом [seek]. Если сейчас ничего не играет, либо трек ещё не загружен, то данный метод ничего не сделает.
  ///
  /// Если [play] = true, то при перемотке плеер будет автоматически запущен, если он до этого был приостановлен.
  Future<void> seekNormalized(
    double position, {
    bool play = false,
  }) async {
    if (position < 0.0 || position > 1.0) {
      throw ArgumentError(
        "seekNormalized position $position is not in range from 0.0 to 1.0",
      );
    }

    // Если нам неизвестна длительность трека, то мы не можем перемотать на указанный момент.
    if (duration == null) return;

    return await seek(
      Duration(
        milliseconds: (duration!.inMilliseconds * position).toInt(),
      ),
      play: play,
    );
  }

  /// Добавляет к текущему времени трека указанное количество времени.
  ///
  /// Если [play] = true, то при перемотке плеер будет автоматически запущен, если он до этого был приостановлен.
  Future<void> seekBy(
    Duration duration, {
    bool play = false,
  }) async {
    return await seek(
      realPosition + duration,
      play: play,
    );
  }

  /// Переключает на трек с указанным индексом.
  Future<void> jump(int index) async {
    _fakeCurrentTrackIndex = index;

    return await _player.seek(
      null,
      index: index,
    );
  }

  /// Указывает громкость плеера. Передаваемое значение громкости [value] обязано быть в пределах от 0.0 до 1.0.
  Future<void> setVolume(double value) async {
    if (value < 0.0 || value > 1.0) {
      throw ArgumentError(
        "setVolume given volume $value is not in range from 0.0 to 1.0",
      );
    }

    if (value == volume) return;

    return await _player.setVolume(value);
  }

  /// Останавливает плеер, освобождая ресурсы.
  ///
  /// Данный метод стоит вызывать только в случае, когда пользователь остановил воспроизведение, к примеру, убив приложение или свернув уведомление. Для паузы стоит воспользоваться методом [pause].
  Future<void> stop() async {
    _playlist = null;
    _queue = null;
    _audiosQueue = null;
    _setPlayerLoaded(false);

    await pause();
    await _player.stop();
    await stopMusicSession();
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

  /// Запускает воспроизведение следующего трека. Если это последний трек в плейлисте, то ставит плеер на паузу.
  Future<void> next() async {
    if (nextTrackIndex == null) {
      await pause();

      return;
    }

    await jump(nextTrackIndex!);

    if (!playing) await play();
  }

  /// Запускает воспроизведение трека, который был воспроизведён перед текущим треком, либо паузу, если это первый трек в очереди, либо же перематывает в начало текущего трека, если прошло не более 5 секунд воспроизведения и [allowSeekToBeginning] правдив.
  ///
  /// Вместо этого метод стоит воспользоваться методом [smartPrevious], который учитывает значение настройки [UserPreferences.rewindOnPreviousBehavior].
  Future<void> previous({
    bool allowSeekToBeginning = false,
  }) async {
    if (previousTrackIndex == null) {
      await pause();

      return;
    }

    if (allowSeekToBeginning && _player.position.inSeconds >= 5) {
      await seekToBeginning();
    } else {
      await jump(previousTrackIndex!);
    }

    if (!playing) await play();
  }

  /// Запускает воспроизведение трека, который был воспроизведён перед текущим треком, либо паузу, если это первый трек в очереди, либо же перематывает в начало текущего трека в зависимости от источника вызова этого метода (UI либо медиа-уведомление) и значения пользовательской настройки [UserPreferences.rewindOnPreviousBehavior].
  ///
  /// Если вам нужно проигнорировать текущее значение настройки [UserPreferences.rewindOnPreviousBehavior], то воспользуйтесь методом [previous].
  Future<void> smartPrevious({
    bool viaNotification = false,
  }) async {
    final setting = ref.read(preferencesProvider).rewindOnPreviousBehavior;
    final allowSeekToBeginning = setting == RewindBehavior.always ||
        (viaNotification && setting == RewindBehavior.onlyViaNotification) ||
        (!viaNotification && setting == RewindBehavior.onlyViaUI);

    logger.d(
      "Called smartPrevious($viaNotification), current setting: ${setting.name}, should allow seek to beginning: $allowSeekToBeginning",
    );

    return await previous(
      allowSeekToBeginning: allowSeekToBeginning,
    );
  }

  /// Включает или отключает случайное перемешивание треков в данном плейлисте, в зависимости от аргумента [shuffle].
  ///
  /// [shuffle] не может быть true, если [currentPlaylist] является плейлистом типа VK Mix ([ExtendedPlaylist.isAudioMixPlaylist]).
  Future<void> setShuffle(
    bool shuffle, {
    bool disableAudioMixCheck = false,
  }) async {
    if (shuffle &&
        !disableAudioMixCheck &&
        currentPlaylist?.type == PlaylistType.audioMix) {
      throw Exception("Attempted to enable shuffle for audio mix");
    }

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

  /// Указывает, будет ли включён повтор текущего трека.
  ///
  /// Тоже самое что и [setLoop], но этот метод принимает булево значение, вместо [LoopMode].
  Future<void> setLoopModeEnabled(bool loop) async {
    return await setLoop(loop ? LoopMode.one : LoopMode.all);
  }

  /// Переключает состояние повтора текущего трека.
  Future<void> toggleLoopMode() async {
    return await setLoopModeEnabled(loopMode == LoopMode.all);
  }

  /// Тихо устанавливает плейлист [playlist], не передавая изменения в низкоуровневый плеер. [mergeWithOldQueue] указывает, что очередь из треков (отвечающая за отображение треков в UI) будет заменена таким образом, что бы индексы не смешивались.
  ///
  /// Вместо этого метода стоит воспользоваться методом [setPlaylist].
  void _silentSetPlaylist(
    ExtendedPlaylist playlist, {
    bool mergeWithOldQueue = false,
  }) async {
    if (playlist.audios == null) {
      throw Exception("audios of ExtendedPlaylist is null");
    }

    // Создаём список из треков в плейлисте, которые можно воспроизвести.
    final List<ExtendedAudio> audios = playlist.audios!
        .where(
          (audio) => audio.canPlay,
        )
        .toList();

    // Обработка запуска пустого плейлиста.
    if (audios.isEmpty) return;

    _currentPlaylistStateController.add(playlist);
    _playlist = playlist;

    // Если нам нужно объеденить со старой очередью треков, то делаем это.
    if (mergeWithOldQueue && _audiosQueue != null) {
      for (int index = 0; index < _audiosQueue!.length; index++) {
        final ExtendedAudio oldAudio = _audiosQueue![index];

        final ExtendedAudio? newAudio = audios.firstWhereOrNull(
          (ExtendedAudio item) =>
              item.ownerID == oldAudio.ownerID && item.id == oldAudio.id,
        );
        if (newAudio != null) {
          _audiosQueue![index] = newAudio;
        }
      }
    } else {
      _audiosQueue = [...audios];
    }
  }

  /// Устанавливает плейлист [playlist] для воспроизведения музыки, указывая при этом [selectedTrack], начиная с которого будет запущено воспроизведение, либо же рандомный трек, если [randomTrack] правдив.
  ///
  /// Если [play] равен true, то при вызове данного метода плеер автоматически начнёт воспроизводить музыку.
  Future<void> setPlaylist(
    ExtendedPlaylist playlist, {
    bool play = true,
    ExtendedAudio? selectedTrack,
    bool randomTrack = false,
    bool setLoopAll = true,
  }) async {
    if (randomTrack && selectedTrack != null) {
      throw ArgumentError("randomTrack and index cannot be specified together");
    }

    final bool isAudioMix = playlist.mixID != null;

    _silentSetPlaylist(playlist);
    _queue = ConcatenatingAudioSource(
      children: _audiosQueue!
          .map(
            (ExtendedAudio audio) => CachedStreamAudioSource(
              ref: ref,
              audio: audio,
              playlist: playlist,
            ),
          )
          .toList(),
    );

    // Указываем, что плеер загружен.
    if (play) {
      _setPlayerLoaded(true);
    }

    // Возвращаем повтор треков в плейлисте, если это нужно.
    if (setLoopAll && player.loopMode == LoopMode.off) {
      await player.setLoop(LoopMode.all);
    } else if (isAudioMix && player.loopMode != LoopMode.off) {
      await player.setLoop(LoopMode.off);
    }

    // Выключаем shuffle, если это плейлист VK Mix.
    if (isAudioMix && shuffleModeEnabled) {
      await setShuffle(
        false,
        disableAudioMixCheck: true,
      );

      _shouldRestoreShuffle = true;

      logger.d("Disabled shuffle for VK Mix; will restore later");
    } else if (_shouldRestoreShuffle && !isAudioMix) {
      await setShuffle(true);

      _shouldRestoreShuffle = false;

      logger.d("Restored shuffle after VK Mix");
    }

    // Отправляем плееру очередь из треков.
    await _player.setAudioSource(
      _queue!,
      initialIndex: selectedTrack != null
          ? _audiosQueue!.indexOf(selectedTrack)
          : randomTrack && playlist.audios != null
              ? Random().nextInt(_audiosQueue!.length)
              : 0,
    );

    // Если разрешено, сразу же запускаем воспроизведение.
    if (play) {
      await this.play();
    }
  }

  /// Добавляет указанный трек как следующий для воспроизведения.
  Future<void> addNextToQueue(ExtendedAudio audio) async {
    if (_queue == null) {
      throw Exception("Queue cannot be empty");
    }

    await _queue!.insert(
      nextTrackIndex!,
      CachedStreamAudioSource(
        ref: ref,
        audio: audio,
        playlist: currentPlaylist!,
      ),
    );
    _audiosQueue!.insert(
      nextTrackIndex ?? 0,
      audio,
    );
  }

  /// Добавляет указанный трек в конец очереди воспроизведения.
  Future<void> addToQueueEnd(ExtendedAudio audio) async {
    if (_queue == null) {
      throw Exception("Queue cannot be empty");
    }

    await _queue!.add(
      CachedStreamAudioSource(
        ref: ref,
        audio: audio,
        playlist: currentPlaylist!,
      ),
    );
    _audiosQueue!.add(
      audio,
    );
  }

  /// Включает или отключает Discord Rich Presence.
  Future<void> setDiscordRPCEnabled(bool enabled) async {
    logger.d("Called setDiscordRPCEnabled($enabled)");

    if (enabled && !isDesktop) {
      throw Exception("Discord RPC can only be enabled on Desktop-platforms.");
    }

    if (enabled == _discordRPCEnabled) return;
    _discordRPCEnabled = enabled;

    if (enabled) {
      await updateMusicSession();
    } else {
      _discordRPC?.clearPresence();
    }
  }

  /// Включает или отключает настройку "пауза при отключении громкости".
  Future<void> setPauseOnMuteEnabled(bool enabled) async {
    logger.d("Called setPauseOnMuteEnabled($enabled)");

    if (enabled && !isDesktop) {
      throw Exception(
        "setPauseOnMuteEnabled can only be enabled on Desktop-platforms.",
      );
    }

    if (enabled == _pauseOnMuteEnabled) return;
    _pauseOnMuteEnabled = enabled;

    if (enabled && volume == 0.0) {
      await pause();
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
    // Указываем, что в данный момент идёт сессия музыки.
    await _audioSession!.setActive(true);

    if (Platform.isWindows) {
      await _smtc?.enableSmtc();
    }
  }

  /// Метод, обновляющий данные о музыкальной сессии, отправляя новые данные по текущему треку после вызова метода [startMusicSession].
  ///
  /// Данный метод стоит вызывать после изменения текущего трека.
  ///
  /// Не стоит путать с [updateMusicSession]: Данный метод обновляет трек, который играет в данный момент.
  Future<void> updateMusicSessionTrack() async {
    if (currentAudio == null) return;

    // Забываем индекс фейкового трека.
    _fakeCurrentTrackIndex = null;

    // Если у пользователя Windows, то посылаем SMTC обновление.
    if (Platform.isWindows) {
      if (!_smtc!.enabled) await _smtc!.enableSmtc();

      await _smtc?.updateMetadata(
        MusicMetadata(
          title: currentAudio!.title,
          artist: currentAudio!.artist,
          albumArtist: currentAudio!.artist,
          album: currentAudio!.album?.title,
          thumbnail: currentAudio!.smallestThumbnail,
        ),
      );
    }

    // Делаем обновление трека в медиа-уведомлении.
    await _audioService?._updateTrack();
  }

  /// Метод, обновляющий данные о музыкальной сессии после вызова метода [startMusicSession].
  ///
  /// Данный метод рекомендуется вызывать только при событиях изменения состояния плеера, например, начало буферизации, паузы/воспроизведения и/ли подобных.
  ///
  /// Не стоит путать с [updateMusicSessionTrack]: Данный метод лишь обновляет состояние воспроизведения.
  Future<void> updateMusicSession() async {
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

      await _smtc?.setPlaybackStatus(status);
    }

    // Обновляем Discord RPC, если это разрешено пользователем.
    if (discordRPCEnabled && currentAudio != null) {
      _discordRPC?.updatePresence(
        DiscordPresence(
          state: currentAudio!.title,
          details: currentAudio!.artist,
          largeImageKey: "flutter-vk-logo",
          largeImageText: "Flutter VK",
          smallImageKey: playing ? "playing" : "paused",
          smallImageText: playing
              ? "${currentAudio!.artist} • ${currentAudio!.title}"
              : null,
          startTimeStamp:
              playing ? getUnixTimestamp() - position.inSeconds : null,
        ),
      );
    }

    // Запускаем таймер паузы, если установлена пауза.
    _pauseStopTimer?.cancel();

    if (_allowStopOnPause && _loaded && !playing) {
      // logger.d("Starting stopOnPause timer for $stopOnPauseTimerDuration");

      // Запускаем таймер.
      _pauseStopTimer = Timer(
        stopOnPauseTimerDuration,
        _stopOnPauseCallback,
      );
    }
  }

  /// Останавливает текущую музыкальную сессию, ранее начатую вызовом метода [startMusicSession].
  ///
  /// Данный метод стоит вызывать только после остановки музыкальной сессии, т.е., после вызова метода [stop].
  Future<void> stopMusicSession() async {
    if (Platform.isWindows) {
      await _smtc?.disableSmtc();
    }

    await _audioSession?.setActive(false);
    if (discordRPCEnabled) {
      _discordRPC?.clearPresence();
    }

    _pauseStopTimer?.cancel();
  }
}

/// Расширение для класса [BaseAudioHandler], методы которого вызываются при взаимодействии с медиа-уведомлением.
class AudioPlayerService extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  static final AppLogger logger = getLogger("AudioPlayerService");

  final VKMusicPlayer _player;
  final Ref _ref;

  AudioPlayerService(
    this._player,
    this._ref,
  ) {
    // События состояния плеера.
    _player.playerStateStream.listen((PlayerState state) async {
      await _updateEvent();
    });

    // События изменения позиции плеера.
    _player.seekStateStream.listen((Duration position) async {
      await _updateEvent();
    });

    // События остановки/первого запуска (загрузки) плеера.
    _player.loadedStateStream.listen((bool loaded) async {
      await _updateEvent();
    });

    // События изменения состояния shuffle.
    _player.shuffleModeEnabledStream.listen((bool enabled) async {
      await _updateEvent();
    });

    // События изменения индекса трека.
    _player.currentIndexStream.listen((int? index) async {
      await _updateEvent();
    });
  }

  /// Отправляет изменения состояния воспроизведения в `audio_service`, обновляя информацию, отображаемую в уведомлении.
  Future<void> _updateEvent() async {
    final ExtendedPlaylist? playlist = _player.currentPlaylist;
    final ExtendedAudio? audio = _player.smartCurrentAudio;
    final bool isLiked = audio?.isLiked ?? false;
    final bool isAudioMix = playlist?.type == PlaylistType.audioMix;
    final bool isRecommended = playlist?.isRecommendationTypePlaylist ?? false;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,

          // Кнопка для shuffle, если у нас не аудио микс.
          if (!isAudioMix && !isRecommended)
            MediaControl.custom(
              androidIcon: _player.shuffleModeEnabled
                  ? "drawable/ic_shuffle_enabled"
                  : "drawable/ic_shuffle",
              label: "Shuffle",
              name: MediaNotificationAction.shuffle.name,
            ),

          // Кнопка для дизлайка трека, если это рекомендуемый плейлист.
          if (isRecommended)
            MediaControl.custom(
              androidIcon: "drawable/ic_dislike",
              label: "Dislike",
              name: MediaNotificationAction.dislike.name,
            ),

          // Кнопка для сохранения трека как лайкнутый.
          MediaControl.custom(
            androidIcon: isLiked
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
        shuffleMode: _player.shuffleModeEnabled
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
    // TODO: Сделать очередь вместо обновления текущего трека.

    mediaItem.add(_player.currentAudio?.asMediaItem);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    final action = MediaNotificationAction.values.firstWhere(
      (action) => action.name == name,
    );

    switch (action) {
      case (MediaNotificationAction.shuffle):
        await setShuffleMode(
          _player.shuffleModeEnabled
              ? AudioServiceShuffleMode.group
              : AudioServiceShuffleMode.all,
        );

        break;

      case (MediaNotificationAction.favorite):
        if (!connectivityManager.hasConnection) return;

        await toggleTrackLike(
          _ref,
          _player.currentAudio!,
        );
        await _updateEvent();

        break;

      case (MediaNotificationAction.dislike):
        if (!connectivityManager.hasConnection) return;

        await dislikeTrack(
          _ref,
          _player.currentAudio!,
        );
        await _updateEvent();

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
  Future<void> onTaskRemoved() {
    final keepPlayingOnClose =
        _ref.read(preferencesProvider).androidKeepPlayingOnClose;

    // Если пользователь хочет, чтобы музыка продолжала играть после закрытия приложения, то не останавливаем плеер.
    if (_player.playing && keepPlayingOnClose) {
      logger.d("User removed task, but I'm still alive, ha-ha!");

      return Future.value();
    }

    return _player.stop();
  }

  @override
  Future<void> onNotificationDeleted() => _player.stop();

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await super.setShuffleMode(shuffleMode);

    // Не позволяем включить Shuffle при включённом аудио миксе.
    if (_player.currentPlaylist?.type == PlaylistType.audioMix) return;

    await _player.setShuffle(
      shuffleMode == AudioServiceShuffleMode.all,
    );

    _ref
        .read(preferencesProvider.notifier)
        .setShuffleEnabled(_player.shuffleModeEnabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await super.setRepeatMode(repeatMode);

    final bool enabled = repeatMode == AudioServiceRepeatMode.one;

    await _player.setLoopModeEnabled(enabled);

    _ref.read(preferencesProvider.notifier).setLoopModeEnabled(enabled);
  }

  @override
  Future<void> skipToNext() async {
    await _player.next();

    await super.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.smartPrevious(
      viaNotification: true,
    );

    await super.skipToPrevious();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}
