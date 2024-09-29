import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../api/vk/catalog/get_audio.dart";
import "../api/vk/execute/mass_get_audio.dart";
import "../api/vk/shared.dart";
import "../db/schemas/playlists.dart";
import "../enums.dart";
import "../main.dart";
import "../services/download_manager.dart";
import "../services/logger.dart";
import "../utils.dart";
import "auth.dart";
import "download_manager.dart";
import "l18n.dart";
import "user.dart";
import "vk_api.dart";

part "playlists.g.dart";

/// Создаёт задачу [PlaylistCacheDownloadTask] по кэшированию плейлиста [playlist]. После вызова этого метода, будет создана задача для [DownloadManager], которая будет кэшировать треки плейлиста, и так же очищать данные для удалённых треков [deletedAudios].
Future<void> createPlaylistCacheTask(
  Ref ref,
  ExtendedPlaylist playlist, {
  List<ExtendedAudio> deletedAudios = const [],
}) async {
  assert(
    playlist.audios != null,
    "Expected playlist audios to be loaded",
  );

  final downloadManager = ref.read(downloadManagerProvider.notifier);
  final l18n = ref.read(l18nProvider);
  final playlistName =
      playlist.title ?? l18n.music_fullscreenFavoritePlaylistName;

  // Создаём задачу по кэшированию треков плейлиста (и удалению старых, при наличии).
  await downloadManager.newTask(
    PlaylistCacheDownloadTask(
      ref: downloadManager.ref,
      id: playlist.mediaKey,
      playlist: playlist,
      longTitle: l18n.music_playlistCachingTitle(playlistName),
      smallTitle: playlistName,
      tasks: [
        // Удалённые треки.
        ...deletedAudios.map(
          (audio) => PlaylistCacheDeleteDownloadItem(
            ref: ref,
            playlist: playlist,
            audio: audio,
            updatePlaylist: false,
            removeThumbnails: true,
          ),
        ),

        // Некэшированные треки.
        //
        // Мы кэшируем те, которые:
        // - Не кэшированы, но есть ссылка на скачивание (трек доступен).
        // - Имеют текст песни, но текст не загружен.
        if (playlist.cacheTracks ?? false)
          ...playlist.audios!
              .where(
                (audio) =>
                    (!(audio.isCached ?? false) && audio.url != null) ||
                    ((audio.hasLyrics ?? false) && audio.vkLyrics == null),
              )
              .map(
                (audio) => PlaylistCacheDownloadItem(
                  ref: ref,
                  playlist: playlist,
                  audio: audio,
                ),
              ),
      ],
    ),
  );
}

/// Хранит в себе состояние загруженности плейлистов.
class PlaylistsState {
  static final StreamController<ExtendedPlaylist>
      playlistModificationsController = StreamController.broadcast();

  /// Stream, указывающий события изменения плейлиста.
  static Stream<ExtendedPlaylist> get playlistModificationsStream =>
      playlistModificationsController.stream.asBroadcastStream();

  /// Указывает, загружены ли плейлисты через API ВКонтакте.
  ///
  /// Если false, то значит, что плейлисты кэшированы.
  final bool fromAPI;

  /// [List] из всех плейлистов у пользователя.
  final List<ExtendedPlaylist> playlists;

  /// Количество всех созданых плейлистов пользователя (те, что находятся в разделе "Ваши плейлисты").
  final int? playlistsCount;

  /// Делает копию этого класа с новыми передаваемыми значениями.
  PlaylistsState copyWith({
    bool? fromAPI,
    List<ExtendedPlaylist>? playlists,
    int? playlistsCount,
  }) =>
      PlaylistsState(
        fromAPI: fromAPI ?? this.fromAPI,
        playlists: playlists ?? this.playlists,
        playlistsCount: playlistsCount ?? this.playlistsCount,
      );

  @override
  bool operator ==(covariant PlaylistsState other) {
    return other.fromAPI == fromAPI &&
        other.playlistsCount == playlistsCount &&
        listEquals(other.playlists, playlists);
  }

  @override
  int get hashCode =>
      playlists.hashCode ^ fromAPI.hashCode ^ playlistsCount.hashCode;

  PlaylistsState({
    this.fromAPI = false,
    required this.playlists,
    this.playlistsCount,
  });
}

/// Класс, характеризующий результат работы метода [Playlists.updatePlaylist].
class PlaylistUpdateResult {
  /// Плейлист, который был модифицирован.
  final ExtendedPlaylist playlist;

  /// Указывает, был ли изменён плейлист.
  final bool changed;

  /// Указывает, какие треки были удалены из плейлиста.
  final List<ExtendedAudio> deletedAudios;

  PlaylistUpdateResult({
    required this.playlist,
    required this.changed,
    this.deletedAudios = const [],
  });
}

/// [Provider], загружающий информацию о плейлистах пользователя из локальной БД.
@Riverpod(keepAlive: true)
Future<PlaylistsState?> dbPlaylists(DbPlaylistsRef ref) async {
  // final AppLogger logger = getLogger("DBPlaylistsProvider");

  // logger.d("Loading cached playlists from Isar DB");

  final List<ExtendedPlaylist> playlists = (await appStorage.getPlaylists())
      .where((DBPlaylist? playlist) => playlist != null)
      .map((DBPlaylist? dbPlaylist) => dbPlaylist!.asExtendedPlaylist)
      .toList();

  // Если плейлистов нету, то ничего не делаем.
  if (playlists.isEmpty) return null;

  return PlaylistsState(
    playlists: playlists,
  );
}

/// [Provider], хранящий в себе информацию о плейлистах пользователя.
///
/// Так же стоит обратить внимание на следующие [Provider]'ы, упрощающие доступ к получению плейлистов:
/// - [favoritesPlaylistProvider].
/// - [userPlaylistsProvider].
/// - [mixPlaylistsProvider].
/// - [moodPlaylistsProvider].
/// - [recommendedPlaylistsProvider].
/// - [simillarPlaylistsProvider].
/// - [madeByVKPlaylistsProvider].
@Riverpod(keepAlive: true)
class Playlists extends _$Playlists {
  static final AppLogger logger = getLogger("PlaylistsProvider");

  @override
  Future<PlaylistsState?> build() async {
    // FIXME: Неиспользованные ключи локализации: music_basicDataLoadError, music_recommendationsDataLoadError.

    // Если у пользователя нет Access-токена, то ничего не делаем.
    if (ref.read(tokenProvider) == null) return null;

    // Если же плейлисты не были загружены через API, то пытаемся загрузить их из БД.
    if (state.value == null) {
      final Stopwatch watch = Stopwatch()..start();
      final PlaylistsState? playlistsState =
          await ref.read(dbPlaylistsProvider.future);

      watch.stop();
      final int elapsedMs = watch.elapsedMilliseconds;

      if (playlistsState != null) {
        logger.d(
          "Took ${elapsedMs}ms to load playlists from Isar DB",
        );

        // Если плейлисты долго грузились, то логируем это.
        if (elapsedMs >= 500 && !kDebugMode) {
          logger.w(
            "Took a very long time (${elapsedMs}ms) to load playlists from Isar DB",
          );
        }

        state = AsyncData(playlistsState);
      }
    }

    // Пытаемся получить список плейлистов при помощи API, если у нас есть доступ к интернету.
    if (connectivityManager.hasConnection) {
      await _loadAPIPlaylists();
    }

    return state.value;
  }

  /// Пытается загрузить все плейлисты пользователя, а так же рекомендуемые плейлисты.
  ///
  /// Вызывает [_loadUserPlaylists] и [_loadRecommendedPlaylists].
  Future<void> _loadAPIPlaylists() async {
    try {
      final results = await Future.wait([
        _loadUserPlaylists(),
        _loadRecommendedPlaylists(),
      ]);

      final (List<ExtendedPlaylist>, int) userPlaylists =
          results[0] as (List<ExtendedPlaylist>, int);
      final List<ExtendedPlaylist> recommendedPlaylists =
          results[1] as List<ExtendedPlaylist>;

      // Если state не был установлен, то устанавливаем его.
      if (state.value == null) {
        state = AsyncData(
          PlaylistsState(
            playlists: state.value?.playlists ?? [],
            fromAPI: true,
            playlistsCount: userPlaylists.$2,
          ),
        );
      }

      // Обновляем плейлисты. Данный метод обновит UI и сохранит в БД, если плейлисты отличаются от тех, что уже есть.
      final List<PlaylistUpdateResult> updatedPlaylists = await updatePlaylists(
        [...userPlaylists.$1, ...recommendedPlaylists],
        saveInDB: true,
        fromAPI: true,
        playlistsCount: userPlaylists.$2,
      );

      // Проходимся по всем модифицированным плейлистам, и запускаем задачи по их кэшированию.
      for (PlaylistUpdateResult result in updatedPlaylists) {
        if (!result.changed || result.playlist.areTracksCached) continue;

        final ExtendedPlaylist playlist = result.playlist;
        createPlaylistCacheTask(
          ref,
          playlist,
          deletedAudios: result.deletedAudios,
        );
      }

      // Проходимся по всем существующим плейлистам (в том числе и рекомендованным, ...), и смотрим, у каких включено кэширование.
      // Загружаем данные таковых плейлистов, что бы дополнительно создались задачи по их кэшированию.
      for (ExtendedPlaylist playlist in state.value!.playlists) {
        if ([PlaylistType.favorites, PlaylistType.searchResults]
                .contains(playlist.type) ||
            !(playlist.cacheTracks ?? false)) {
          continue;
        }

        logger.d("Found playlist with caching enabled: $playlist");
        await loadPlaylist(playlist);
      }
    } catch (e, stackTrace) {
      logger.e(
        "Failed to load playlists via API",
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Загружает пользовательские плейлисты, а так же содержимое фейкового плейлиста "любимые треки".
  Future<(List<ExtendedPlaylist>, int)> _loadUserPlaylists() async {
    // logger.d("Loading basic playlists info via API");

    final user = ref.read(userProvider);
    final api = ref.read(vkAPIProvider);

    final APIMassAudioGetResponse regularPlaylists =
        await api.audio.getWithAlbums(user.id);

    return (
      [
        // Фейковый плейлист "Любимая музыка", который отображает лайкнутые пользователем треки.
        ExtendedPlaylist(
          id: 0,
          ownerID: user.id,
          type: PlaylistType.favorites,
          count: regularPlaylists.audioCount,
          audios: regularPlaylists.audios
              .map(
                (Audio audio) => ExtendedAudio.fromAPIAudio(
                  audio,
                  isLiked: true,
                ),
              )
              .toList(),
          isLiveData: true,
          areTracksLive: true,
        ),

        // Все остальные плейлисты пользователя.
        // Мы помечаем что плейлисты являются кэшированными.
        ...regularPlaylists.playlists.map(
          (playlist) => ExtendedPlaylist.fromAudioPlaylist(
            playlist,
            PlaylistType.regular,
          ),
        ),
      ],
      regularPlaylists.playlistsCount,
    );
  }

  /// Загружает список из рекомендуемых плейлистов пользователя.
  Future<List<ExtendedPlaylist>> _loadRecommendedPlaylists() async {
    final user = ref.read(userProvider);
    final secondaryToken = ref.read(secondaryTokenProvider);

    // Если у пользователя нет второго токена, то ничего не делаем.
    if (secondaryToken == null) return [];

    // logger.d("Loading recommended playlists via API");

    /// Парсит список из плейлистов, возвращая список плейлистов из раздела "Какой сейчас вайб?".
    ///
    /// Сейчас этот метод возвращает null, поскольку ВК перестал
    /// передавать раздел "какой сейчас вайб" для VK Admin.
    List<ExtendedPlaylist>? parseMoodPlaylists(
      APICatalogGetAudioResponse response,
    ) {
      final Section mainSection = response.catalog.sections[0];

      // Ищем блок с рекомендуемыми плейлистами.
      SectionBlock? moodPlaylistsBlock = mainSection.blocks!.firstWhereOrNull(
        (SectionBlock block) =>
            block.dataType == "music_playlists" &&
            block.layout["style"] == "unopenable",
      );

      if (moodPlaylistsBlock == null) return null;

      // Извлекаем список ID плейлистов из этого блока.
      final List<String> moodPlaylistIDs = moodPlaylistsBlock.playlistIDs!;

      // Достаём те плейлисты, которые рекомендуются нами ВКонтакте.
      // Превращаем объекты типа AudioPlaylist в ExtendedPlaylist.
      return response.playlists
          .where(
            (Playlist playlist) => moodPlaylistIDs.contains(playlist.mediaKey),
          )
          .map(
            (Playlist playlist) => ExtendedPlaylist.fromAudioPlaylist(
              playlist,
              PlaylistType.mood,
            ),
          )
          .toList();
    }

    /// Парсит список из аудио миксов.
    List<ExtendedPlaylist> parseAudioMixPlaylists(
      APICatalogGetAudioResponse response,
    ) {
      final List<ExtendedPlaylist> playlists = [];

      // Проходимся по списку аудио миксов, создавая из них плейлисты.
      for (AudioMix mix in response.audioStreamMixes) {
        playlists.add(
          ExtendedPlaylist(
            id: -fastHash(mix.id),
            ownerID: user.id,
            type: PlaylistType.audioMix,
            title: mix.title,
            description: mix.description,
            backgroundAnimationUrl: mix.backgroundAnimationUrl,
            mixID: mix.id,
            count: 0,
          ),
        );
      }

      return playlists;
    }

    /// Парсит список из плейлистов, возвращая только список из рекомендуемых плейлистов ("Для вас" и подобные).
    List<ExtendedPlaylist>? parseRecommendedPlaylists(
      APICatalogGetAudioResponse response,
    ) {
      final Section mainSection = response.catalog.sections[0];

      // Ищем блок с рекомендуемыми плейлистами.
      SectionBlock? recommendedPlaylistsBlock =
          mainSection.blocks!.firstWhereOrNull(
        (SectionBlock block) => block.dataType == "music_playlists",
      );

      if (recommendedPlaylistsBlock == null) {
        logger.w("Recommended playlists block was not found");

        return null;
      }

      // Извлекаем список ID плейлистов из этого блока.
      final List<String> recommendedPlaylistIDs =
          recommendedPlaylistsBlock.playlistIDs!;

      // Достаём те плейлисты, которые рекомендуются нами ВКонтакте.
      // Превращаем объекты типа AudioPlaylist в ExtendedPlaylist.
      return response.playlists
          .where(
            (Playlist playlist) =>
                recommendedPlaylistIDs.contains(playlist.mediaKey),
          )
          .map(
            (Playlist playlist) => ExtendedPlaylist.fromAudioPlaylist(
              playlist,
              PlaylistType.recommendations,
            ),
          )
          .toList();
    }

    /// Парсит список из плейлистов, возвращая только список из плейлистов раздела "Совпадения по вкусам".
    List<ExtendedPlaylist> parseSimillarPlaylists(
      APICatalogGetAudioResponse response,
    ) {
      final List<ExtendedPlaylist> playlists = [];

      // Проходимся по списку рекомендуемых плейлистов.
      for (SimillarPlaylist playlist in response.recommendedPlaylists) {
        final fullPlaylist = response.playlists.firstWhere(
          (Playlist fullPlaylist) => fullPlaylist.mediaKey == playlist.mediaKey,
        );

        playlists.add(
          ExtendedPlaylist.fromAudioPlaylist(
            fullPlaylist,
            PlaylistType.simillar,
            simillarity: playlist.percentage,
            color: playlist.color,
            isLiveData: false,
            knownTracks: response.audios
                .where(
                  (Audio audio) => playlist.audios.contains(audio.mediaKey),
                )
                .map(
                  (Audio audio) => ExtendedAudio.fromAPIAudio(audio),
                )
                .toList(),
          ),
        );
      }

      return playlists;
    }

    /// Парсит список из плейлистов, возвращая только список из плейлистов раздела "Собрано редакцией".
    List<ExtendedPlaylist>? parseMadeByVKPlaylists(
      APICatalogGetAudioResponse response,
    ) {
      final Section mainSection = response.catalog.sections[0];

      // Ищем блок с плейлистами "Собрано редакцией". Данный блок имеет [SectionBlock.dataType] == "music_playlists", но он расположен в конце.
      SectionBlock? madeByVKPlaylistsBlock =
          mainSection.blocks!.lastWhereOrNull(
        (SectionBlock block) => block.dataType == "music_playlists",
      );

      if (madeByVKPlaylistsBlock == null) {
        logger.w("Made by VK playlists block was not found");

        return null;
      }

      // Извлекаем список ID плейлистов из этого блока.
      final List<String> recommendedPlaylistIDs =
          madeByVKPlaylistsBlock.playlistIDs!;

      // Достаём те плейлисты, которые рекомендуются нами ВКонтакте.
      // Превращаем объекты типа AudioPlaylist в ExtendedPlaylist.
      return response.playlists
          .where(
            (Playlist playlist) =>
                recommendedPlaylistIDs.contains(playlist.mediaKey),
          )
          .map(
            (Playlist playlist) => ExtendedPlaylist.fromAudioPlaylist(
              playlist,
              PlaylistType.madeByVK,
            ),
          )
          .toList();
    }

    final APICatalogGetAudioResponse response =
        await ref.read(vkAPIProvider).catalog.getAudio();

    // Создаём список из всех рекомендуемых плейлистов, а так же добавляем их в память.
    return [
      ...parseMoodPlaylists(response) ?? [],
      ...parseAudioMixPlaylists(response),
      ...parseRecommendedPlaylists(response) ?? [],
      ...parseSimillarPlaylists(response),
      ...parseMadeByVKPlaylists(response) ?? [],
    ];
  }

  /// Сохраняет передаваемый [playlist] в БД.
  ///
  /// Если Вам нужен метод для обновления плейлиста, то воспользуйтесь методом [updatePlaylist]; он так же может сохранить плейлист в БД.
  Future<void> saveDBPlaylist(ExtendedPlaylist playlist) async =>
      appStorage.savePlaylist(playlist.asDBPlaylist);

  /// Обновляет состояние данного Provider, объединяя новую и старую версию плейлиста, а после чего сохраняет его в БД, если [saveInDB] правдив.
  Future<PlaylistUpdateResult> updatePlaylist(
    ExtendedPlaylist newPlaylist, {
    bool saveInDB = false,
    bool fromAPI = false,
    int? userOwnedPlaylistsCount,
  }) async {
    assert(
      state.value != null,
      "State was not set before calling updatePlaylist",
    );

    final List<ExtendedPlaylist> allPlaylists = state.value?.playlists ?? [];
    final ExtendedPlaylist? oldPlaylist = allPlaylists.firstWhereOrNull(
      (ExtendedPlaylist existing) =>
          existing.ownerID == newPlaylist.ownerID &&
          existing.id == newPlaylist.id,
    );

    // Если мы вызвали плейлист, которого нету в списке плейлистов, то просто добавляем его, без лишних проверок.
    if (oldPlaylist == null) {
      allPlaylists.add(newPlaylist);

      // Обновляем состояние.
      state = AsyncData(
        state.value?.copyWith(
          playlists: allPlaylists,
        ),
      );

      // Сохраняем в БД.
      if (saveInDB) {
        await saveDBPlaylist(newPlaylist);
      }

      return PlaylistUpdateResult(
        playlist: newPlaylist,
        changed: true,
      );
    }

    // Мы получили уже существующий плейлист, поэтому проводим объединение таковых.

    // Для начала, нам нужно понять, поменялся ли плейлист по базовым параметрам.
    bool playlistChanged = !oldPlaylist.isEquals(newPlaylist);

    // Проходимся по новому списку треков. Для справки:
    // - audios хранит актуальный список треков.
    // - audiosToUpdate хранит обновления треков (например, изменился текст песни).
    //
    // Если в audios нет того или иного трека, то это значит, что трек был удалён.
    // В audiosToUpdate могут быть только те треки, которые были обновлены, но не удалены.
    List<ExtendedAudio> newAudios = [...(oldPlaylist.audios ?? [])];
    List<ExtendedAudio> deletedAudios = [];

    /// Метод, обновляющий либо добавляющий трек в список треков.
    void updateOrAddAudio(
      ExtendedAudio newAudio,
      bool removeNonPresent,
    ) {
      final index = newAudios.indexWhere(
        (old) => old.ownerID == newAudio.ownerID && old.id == newAudio.id,
      );

      // Если трек отсутствует, то просто добавляем его.
      if (index == -1) {
        // logger.d("[$index] [${newAudio.title}]: add (non-present)");

        newAudios.add(newAudio);
        playlistChanged = true;

        return;
      }

      // Если трек ничем не отличается (кроме URL), то ничего не делаем.
      final ExtendedAudio oldAudio = newAudios[index];
      if ((oldAudio.url != null) == (newAudio.url != null) &&
          oldAudio.isEquals(newAudio)) {
        // logger.d("[$index] [${newAudio.title}]: skip");

        return;
      }

      // Если трек отличается, то обновляем его.
      // logger.d("[$index] [${newAudio.title}]: replace");

      newAudios[index] = oldAudio.copyWith(
        title: newAudio.title,
        artist: newAudio.artist,
        url: newAudio.url,
        isCached: newAudio.isCached,
        cachedSize: newAudio.cachedSize,
        album: newAudio.album,
        hasLyrics: newAudio.hasLyrics,
        vkLyrics: newAudio.vkLyrics,
        lrcLibLyrics: newAudio.lrcLibLyrics,
        vkThumbs: newAudio.vkThumbs,
        deezerThumbs: newAudio.deezerThumbs,
        forceDeezerThumbs: newAudio.forceDeezerThumbs,
        isLiked: newAudio.isLiked,
        colorCount: newAudio.colorCount,
        colorInts: newAudio.colorInts,
        scoredColorInts: newAudio.scoredColorInts,
        frequentColorInt: newAudio.frequentColorInt,
      );

      playlistChanged = true;
    }

    // Для начала, проходимся по списку из новых audios.
    //
    // В нём находится "актуальный" список из треков.
    // Если такой список передаётся во второй раз, то информация должна обновиться.
    if (newPlaylist.audios != null) {
      for (var newAudio in newPlaylist.audios!) {
        updateOrAddAudio(
          newAudio,
          true,
        );
      }

      // Ищем удалённые треки. Если мы находим хотя бы один, то считаем, что плейлист изменился.
      deletedAudios.addAll(
        oldPlaylist.audios!.where(
          (audio) => newPlaylist.audios!.every(
            (newAudio) =>
                newAudio.ownerID != audio.ownerID || newAudio.id != audio.id,
          ),
        ),
      );

      if (deletedAudios.isNotEmpty) {
        newAudios.removeWhere(
          (audio) => deletedAudios.any(
            (deleted) =>
                deleted.ownerID == audio.ownerID && deleted.id == audio.id,
          ),
        );

        playlistChanged = true;
      }
    }

    // Проходимся по списку из "обновлённых" треков. Здесь используется другая логика:
    // - трек есть -> обновляем его.
    // - трека нет -> добавляем его.
    if (newPlaylist.audiosToUpdate != null) {
      for (var newAudio in newPlaylist.audiosToUpdate!) {
        updateOrAddAudio(
          newAudio,
          false,
        );
      }
    }

    // Мы закончили проходиться по списку треков.

    // Если плейлист, по-итогу, отличается, то обновляем state и сохраняем в БД.
    if (playlistChanged) {
      // Создаём копию плейлиста. Из-за reference'ов, мы должны создать новый ExtendedPlaylist.
      //
      // Если не делать копию плейлиста, то Riverpod сравнивает старую (но с новыми полями) и новую версию плейлистов,
      // и из-за этого происходит сравнение между совершенно одинаковыми полями, из-за чего Riverpod
      // отказывается обновлять свои provider'ы, и интерфейс не rebuild'ится, несмотря на то что изменения, очевидно, есть.
      final ExtendedPlaylist playlistToSave = oldPlaylist.copyWith(
        count: newPlaylist.count,
        title: newPlaylist.title,
        description: newPlaylist.description,
        subtitle: newPlaylist.subtitle,
        cacheTracks: newPlaylist.cacheTracks,
        photo: newPlaylist.photo,
        areTracksLive: newPlaylist.areTracksLive,
        backgroundAnimationUrl: newPlaylist.backgroundAnimationUrl,
        isLiveData: newPlaylist.isLiveData,
        colorInts: newPlaylist.colorInts,
        scoredColorInts: newPlaylist.scoredColorInts,
        frequentColorInt: newPlaylist.frequentColorInt,
        colorCount: newPlaylist.colorCount,
        audios: newAudios,
      );

      // Обновляем плейлист.
      allPlaylists[allPlaylists.indexWhere(
        (old) =>
            old.id == playlistToSave.id &&
            old.ownerID == playlistToSave.ownerID,
      )] = playlistToSave;

      // Обновляем состояние интерфейса.
      state = AsyncData(
        state.value!.copyWith(
          playlists: allPlaylists,
          fromAPI: fromAPI,
          playlistsCount: userOwnedPlaylistsCount,
        ),
      );

      // Отправляем событие об изменении плейлиста.
      PlaylistsState.playlistModificationsController.add(playlistToSave);

      // Сохраняем в БД, если это не плейлист "музыка из результатов поиска".
      if (saveInDB && newPlaylist.type != PlaylistType.searchResults) {
        await saveDBPlaylist(playlistToSave);
      }

      return PlaylistUpdateResult(
        playlist: playlistToSave,
        changed: playlistChanged,
        deletedAudios: deletedAudios,
      );
    }

    return PlaylistUpdateResult(
      playlist: oldPlaylist,
      changed: false,
    );
  }

  /// Обновляет состояние данного Provider, объединяя новые и старые версии плейлистров, а после чего сохраняет их в БД, если [saveInDB] правдив.
  Future<List<PlaylistUpdateResult>> updatePlaylists(
    List<ExtendedPlaylist> newPlaylists, {
    bool saveInDB = false,
    bool fromAPI = false,
    int? playlistsCount,
  }) async {
    final List<PlaylistUpdateResult> changedPlaylists = [];
    for (ExtendedPlaylist playlist in newPlaylists) {
      final PlaylistUpdateResult result = await updatePlaylist(
        playlist,
        fromAPI: fromAPI,
        userOwnedPlaylistsCount: playlistsCount,
      );

      // Если этот плейлист считается изменённым, то запоминаем его что бы потом массово сохранить.
      if (result.changed) {
        changedPlaylists.add(result);
      }
    }

    // Если у нас есть несохранённые плейлисты, то массово сохраняем их.
    if (changedPlaylists.isNotEmpty) {
      await appStorage.savePlaylists(
        changedPlaylists
            .where((item) => item.playlist.type != PlaylistType.searchResults)
            .map(
              (item) => item.playlist.asDBPlaylist,
            )
            .toList(),
      );
    }

    return changedPlaylists;
  }

  /// Устанавливает значение данного Provider по передаваемому списку из [ExtendedPlaylist].
  ///
  /// Данный метод используется лишь в тех случаях, при которых БД Isar был изменён каким-то образом. Если Вы хотите сохранить уже имеющийся плейлист, то воспользуйтесь методом [updatePlaylist] или [updatePlaylists].
  void setPlaylists(
    List<ExtendedPlaylist> playlists, {
    bool? fromAPI,
    bool invalidateDBProvider = false,
  }) {
    if (invalidateDBProvider) {
      ref.invalidate(dbPlaylistsProvider);
    }

    state = AsyncData(
      state.value!.copyWith(
        playlists: playlists,
        fromAPI: fromAPI,
      ),
    );
  }

  /// Возвращает плейлист с лайкнутыми треками.
  ExtendedPlaylist? getFavoritesPlaylist() =>
      state.value?.playlists.firstWhereOrNull(
        (playlist) => playlist.type == PlaylistType.favorites,
      );

  /// Возвращает плейлист по передаваемому [ownerID] и [id].
  ExtendedPlaylist? getPlaylist(int ownerID, int id) =>
      state.value?.playlists.firstWhereOrNull(
        (playlist) => playlist.ownerID == ownerID && playlist.id == id,
      );

  /// Загружает информацию с API ВКонтакте по [playlist], если она не была загружена ранее, и обновляет state данного объекта.
  ///
  /// После успешной загрузки, [createCacheTask] диктует, будет ли создана задача по кэшированию треков в данном плейлисте.
  ///
  /// Возвращает новую версию [ExtendedPlaylist] с обновлёнными данными.
  Future<ExtendedPlaylist> loadPlaylist(
    ExtendedPlaylist playlist, {
    bool createCacheTask = true,
  }) async {
    final api = ref.read(vkAPIProvider);

    // Если информация по плейлисту уже загружена, то ничего не делаем.
    if (playlist.type == PlaylistType.favorites ||
        playlist.type == PlaylistType.audioMix ||
        (playlist.audios != null &&
            playlist.isLiveData &&
            playlist.areTracksLive)) {
      return playlist;
    }

    // logger.d("Loading data for $playlist");

    final APIMassAudioGetResponse response = await api.audio.getWithAlbums(
      playlist.ownerID,
      albumID: playlist.id,
      accessKey: playlist.accessKey,
    );

    // Обновляем плейлист.
    final newPlaylist = playlist.basicCopyWith(
      photo: response.playlists
          .firstWhereOrNull(
            (item) => item.mediaKey == playlist.mediaKey,
          )
          ?.photo,
      audios: response.audios
          .map(
            (item) => ExtendedAudio.fromAPIAudio(item),
          )
          .toList(),
      count: response.audioCount,
      isLiveData: true,
      areTracksLive: true,
    );

    final update = await updatePlaylist(
      newPlaylist,
      fromAPI: true,
      saveInDB: true,
    );

    // Если плейлист изменился, то создаём задачу по кэшированию.
    if (update.changed && createCacheTask) {
      createPlaylistCacheTask(
        ref,
        update.playlist,
        deletedAudios: update.deletedAudios,
      );
    }

    return newPlaylist;
  }
}

/// [Provider], возвращающий [ExtendedPlaylist], характеризующий фейковый плейлист "Любимая музыка".
@riverpod
ExtendedPlaylist? favoritesPlaylist(FavoritesPlaylistRef ref) {
  final PlaylistsState? state =
      ref.watch(playlistsProvider).unwrapPrevious().valueOrNull;
  if (state == null) return null;

  return state.playlists.firstWhereOrNull(
    (ExtendedPlaylist playlist) => playlist.type == PlaylistType.favorites,
  );
}

/// [Provider], возвращающий [ExtendedPlaylist], характеризующий фейковый плейлист "Музыка из результатов поиска".
@riverpod
ExtendedPlaylist? searchResultsPlaylist(SearchResultsPlaylistRef ref) {
  final PlaylistsState? state =
      ref.watch(playlistsProvider).unwrapPrevious().valueOrNull;
  if (state == null) return null;

  return state.playlists.firstWhereOrNull(
    (ExtendedPlaylist playlist) => playlist.type == PlaylistType.searchResults,
  );
}

/// [Provider], возвращающий список плейлистов ([ExtendedPlaylist]) пользователя.
@riverpod
List<ExtendedPlaylist>? userPlaylists(UserPlaylistsRef ref) {
  final PlaylistsState? state =
      ref.watch(playlistsProvider).unwrapPrevious().valueOrNull;
  if (state == null) return null;

  final List<ExtendedPlaylist> playlists = state.playlists
      .where(
        (ExtendedPlaylist playlist) => playlist.type == PlaylistType.regular,
      )
      .toList();
  if (playlists.isEmpty && !state.fromAPI) return null;

  return playlists;
}

/// [Provider], возвращающий список рекомендуемых плейлистов ([ExtendedPlaylist]) пользователя типа "VK Mix".
@riverpod
List<ExtendedPlaylist>? mixPlaylists(MixPlaylistsRef ref) {
  final PlaylistsState? state =
      ref.watch(playlistsProvider).unwrapPrevious().valueOrNull;
  if (state == null) return null;

  final List<ExtendedPlaylist> playlists = state.playlists
      .where(
        (ExtendedPlaylist playlist) => playlist.type == PlaylistType.audioMix,
      )
      .toList();
  if (playlists.isEmpty && !state.fromAPI) return null;

  return playlists;
}

/// [Provider], возвращающий список рекомендуемых плейлистов ([ExtendedPlaylist]) пользователя по настроению.
@riverpod
List<ExtendedPlaylist>? moodPlaylists(MoodPlaylistsRef ref) {
  final PlaylistsState? state =
      ref.watch(playlistsProvider).unwrapPrevious().valueOrNull;
  if (state == null) return null;

  final List<ExtendedPlaylist> playlists = state.playlists
      .where(
        (ExtendedPlaylist playlist) => playlist.type == PlaylistType.mood,
      )
      .toList();
  if (playlists.isEmpty && !state.fromAPI) return null;

  return playlists;
}

/// [Provider], возвращающий список рекомендуемых плейлистов ([ExtendedPlaylist]) пользователя типа "Плейлист дня 1" и подобные.
@riverpod
List<ExtendedPlaylist>? recommendedPlaylists(RecommendedPlaylistsRef ref) {
  final PlaylistsState? state =
      ref.watch(playlistsProvider).unwrapPrevious().valueOrNull;
  if (state == null) return null;

  final List<ExtendedPlaylist> playlists = state.playlists
      .where(
        (ExtendedPlaylist playlist) =>
            playlist.type == PlaylistType.recommendations,
      )
      .sorted((a, b) => b.id.compareTo(a.id))
      .toList();
  if (playlists.isEmpty && !state.fromAPI) return null;

  return playlists;
}

/// [Provider], возвращающий список рекомендуемых плейлистов ([ExtendedPlaylist]) пользователя, которые имеют схожести с другими плейлистами пользователя ВКонтакте.
@riverpod
List<ExtendedPlaylist>? simillarPlaylists(SimillarPlaylistsRef ref) {
  final PlaylistsState? state =
      ref.watch(playlistsProvider).unwrapPrevious().valueOrNull;
  if (state == null) return null;

  final List<ExtendedPlaylist> playlists = state.playlists
      .where(
        (ExtendedPlaylist playlist) => playlist.type == PlaylistType.simillar,
      )
      .sorted((a, b) => b.simillarity!.compareTo(a.simillarity!))
      .toList();
  if (playlists.isEmpty && !state.fromAPI) return null;

  return playlists;
}

/// [Provider], возвращающий список рекомендуемых плейлистов ([ExtendedPlaylist]) от ВКонтакте.
@riverpod
List<ExtendedPlaylist>? madeByVKPlaylists(MadeByVKPlaylistsRef ref) {
  final PlaylistsState? state =
      ref.watch(playlistsProvider).unwrapPrevious().valueOrNull;
  if (state == null) return null;

  final List<ExtendedPlaylist> playlists = state.playlists
      .where(
        (ExtendedPlaylist playlist) => playlist.type == PlaylistType.madeByVK,
      )
      .toList();
  if (playlists.isEmpty && !state.fromAPI) return null;

  return playlists;
}

/// [Provider], возвращающий [ExtendedPlaylist] по передаваемому [ownerID] и [id] плейлиста.
@riverpod
ExtendedPlaylist? getPlaylist(GetPlaylistRef ref, int ownerID, int id) {
  ref.watch(playlistsProvider);

  return ref.read(playlistsProvider.notifier).getPlaylist(ownerID, id);
}
