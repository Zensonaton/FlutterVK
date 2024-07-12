import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../api/vk/api.dart";
import "../api/vk/catalog/get_audio.dart";
import "../api/vk/executeScripts/mass_audio_get.dart";
import "../api/vk/shared.dart";
import "../db/schemas/playlists.dart";
import "../main.dart";
import "../services/logger.dart";
import "../utils.dart";
import "auth.dart";
import "user.dart";

part "playlists.g.dart";

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

/// [Provider], загружающий информацию о плейлистах пользователя из локальной БД.
@Riverpod(keepAlive: true)
Future<PlaylistsState?> dbPlaylists(DbPlaylistsRef ref) async {
  final AppLogger logger = getLogger("DBPlaylistsProvider");

  logger.d("Loading cached playlists from Isar DB");

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
    state = const AsyncLoading();

    // FIXME: Неиспользованные ключи локализации: music_basicDataLoadError, music_recommendationsDataLoadError.

    // Загружаем плейлисты из локальной БД, если они не были загружены ранее.
    if (!(state.unwrapPrevious().valueOrNull?.fromAPI ?? false)) {
      final Stopwatch watch = Stopwatch()..start();
      final PlaylistsState? playlistsState =
          await ref.read(dbPlaylistsProvider.future);

      if (playlistsState != null) {
        logger.d(
          "Took ${watch.elapsedMilliseconds}ms to load playlists from Isar DB",
        );

        state = AsyncData(playlistsState);
      }
    }

    // Пытаемся получить список плейлистов при помощи API.
    final results = await Future.wait([
      _loadUserPlaylists(),
      _loadRecommendedPlaylists(),
    ]);

    final (List<ExtendedPlaylist>, int) userPlaylists =
        results[0] as (List<ExtendedPlaylist>, int);
    final List<ExtendedPlaylist> recommendedPlaylists =
        results[1] as List<ExtendedPlaylist>;

    final List<ExtendedPlaylist> playlists = [
      ...userPlaylists.$1,
      ...recommendedPlaylists,
    ];

    // Если state не был установлен, то устанавливаем его.
    state = AsyncData(
      PlaylistsState(
        playlists: state.value?.playlists ?? [],
        fromAPI: true,
        playlistsCount: userPlaylists.$2,
      ),
    );

    // Обновляем плейлисты. Данный метод обновит UI и сохранит в БД, если плейлисты отличаются от тех, что уже есть.
    await updatePlaylists(
      playlists,
      saveInDB: true,
      fromAPI: true,
    );

    return state.value;
  }

  /// Загружает пользовательские плейлисты, а так же содержимое фейкового плейлиста "любимые треки".
  Future<(List<ExtendedPlaylist>, int)> _loadUserPlaylists() async {
    logger.d("Loading basic playlists info via API");

    final user = ref.read(userProvider);

    final APIMassAudioGetResponse regularPlaylists = await ref
        .read(userProvider.notifier)
        .scriptMassAudioGetWithAlbums(user.id);
    raiseOnAPIError(regularPlaylists);

    return (
      [
        // Фейковый плейлист "Любимая музыка", который отображает лайкнутые пользователем треки.
        ExtendedPlaylist(
          id: 0,
          ownerID: user.id,
          count: regularPlaylists.response!.audioCount,
          audios: regularPlaylists.response!.audios
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
        ...regularPlaylists.response!.playlists.map(
          (playlist) => ExtendedPlaylist.fromAudioPlaylist(
            playlist,
          ),
        ),
      ],
      regularPlaylists.response!.playlistsCount,
    );
  }

  /// Загружает список из рекомендуемых плейлистов пользователя.
  Future<List<ExtendedPlaylist>> _loadRecommendedPlaylists() async {
    final user = ref.read(userProvider);
    final secondaryToken = ref.read(secondaryTokenProvider);

    // Если у пользователя нет второго токена, то ничего не делаем.
    if (secondaryToken == null) return [];

    logger.d("Loading recommended playlists via API");

    /// Парсит список из плейлистов, возвращая список плейлистов из раздела "Какой сейчас вайб?".
    ///
    /// Сейчас этот метод возвращает null, поскольку ВК перестал
    /// передавать раздел "какой сейчас вайб" для VK Admin.
    List<ExtendedPlaylist>? parseMoodPlaylists(
      APICatalogGetAudioResponse response,
    ) {
      final Section mainSection = response.response!.catalog.sections[0];

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
      return response.response!.playlists
          .where(
            (Playlist playlist) => moodPlaylistIDs.contains(playlist.mediaKey),
          )
          .map(
            (Playlist playlist) => ExtendedPlaylist.fromAudioPlaylist(
              playlist,
              isMoodPlaylist: true,
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
      for (AudioMix mix in response.response!.audioStreamMixes) {
        playlists.add(
          ExtendedPlaylist(
            id: -fastHash(mix.id),
            ownerID: user.id,
            title: mix.title,
            description: mix.description,
            backgroundAnimationUrl: mix.backgroundAnimationUrl,
            mixID: mix.id,
            count: 0,
            isAudioMixPlaylist: true,
          ),
        );
      }

      return playlists;
    }

    /// Парсит список из плейлистов, возвращая только список из рекомендуемых плейлистов ("Для вас" и подобные).
    List<ExtendedPlaylist>? parseRecommendedPlaylists(
      APICatalogGetAudioResponse response,
    ) {
      final Section mainSection = response.response!.catalog.sections[0];

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
      return response.response!.playlists
          .where(
            (Playlist playlist) =>
                recommendedPlaylistIDs.contains(playlist.mediaKey),
          )
          .map(
            (Playlist playlist) => ExtendedPlaylist.fromAudioPlaylist(playlist),
          )
          .toList();
    }

    /// Парсит список из плейлистов, возвращая только список из плейлистов раздела "Совпадения по вкусам".
    List<ExtendedPlaylist> parseSimillarPlaylists(
      APICatalogGetAudioResponse response,
    ) {
      final List<ExtendedPlaylist> playlists = [];

      // Проходимся по списку рекомендуемых плейлистов.
      for (SimillarPlaylist playlist
          in response.response!.recommendedPlaylists) {
        final fullPlaylist = response.response!.playlists.firstWhere(
          (Playlist fullPlaylist) {
            return fullPlaylist.mediaKey == playlist.mediaKey;
          },
        );

        playlists.add(
          ExtendedPlaylist.fromAudioPlaylist(
            fullPlaylist,
            simillarity: playlist.percentage,
            color: playlist.color,
            isLiveData: false,
            knownTracks: response.response!.audios
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
      final Section mainSection = response.response!.catalog.sections[0];

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
      return response.response!.playlists
          .where(
            (Playlist playlist) =>
                recommendedPlaylistIDs.contains(playlist.mediaKey),
          )
          .map(
            (Playlist playlist) => ExtendedPlaylist.fromAudioPlaylist(playlist),
          )
          .toList();
    }

    final APICatalogGetAudioResponse response =
        await ref.read(userProvider.notifier).catalogGetAudio();
    raiseOnAPIError(response);

    // Создаём список из всех рекомендуемых плейлистов, а так же добавляем их в память.
    return [
      ...parseMoodPlaylists(response) ?? [],
      ...parseAudioMixPlaylists(response),
      ...parseRecommendedPlaylists(response) ?? [],
      ...parseSimillarPlaylists(response),
      ...parseMadeByVKPlaylists(response) ?? [],
    ];
  }

  /// Обновляет состояние данного Provider, объединяя новую и старую версию плейлиста, а после чего сохраняет его в БД, если [saveInDB] правдив.
  ///
  /// Возвращает то, отличается ли старая версия плейлиста от новой.
  Future<bool> updatePlaylist(
    ExtendedPlaylist playlist, {
    bool saveInDB = false,
    bool fromAPI = false,
  }) async {
    assert(
      state.value != null,
      "State was not set before calling updatePlaylist",
    );

    final List<ExtendedPlaylist> allPlaylists = state.value?.playlists ?? [];
    final ExtendedPlaylist? existingPlaylist = allPlaylists.firstWhereOrNull(
      (ExtendedPlaylist plist) =>
          plist.id == playlist.id && plist.ownerID == playlist.ownerID,
    );

    // Если передаваемого плейлиста ещё нету в списке плейлистов, то просто сохраняем его.
    if (existingPlaylist == null) {
      allPlaylists.add(playlist);

      // Обновляем состояние.
      state = AsyncData(
        state.value?.copyWith(
          playlists: allPlaylists,
        ),
      );

      // Сохраняем в БД.
      if (saveInDB) {
        await appStorage.savePlaylist(playlist.asDBPlaylist);
      }

      return true;
    }

    // Такой же плейлист уже существует в списке плейлистов.
    // Объединяем старые и новые данные у плейлиста.
    // Но для начала проверим, отличаются ли поля у этого плейлиста (кроме списка треков).
    bool playlistChanged = (existingPlaylist.count != playlist.count ||
        existingPlaylist.title != playlist.title ||
        existingPlaylist.description != playlist.description ||
        existingPlaylist.subtitle != playlist.subtitle ||
        (existingPlaylist.cacheTracks ?? false) !=
            (playlist.cacheTracks ?? false) ||
        existingPlaylist.areTracksLive != playlist.areTracksLive ||
        existingPlaylist.backgroundAnimationUrl !=
            playlist.backgroundAnimationUrl ||
        existingPlaylist.isLiveData != playlist.isLiveData ||
        existingPlaylist.photo != playlist.photo);

    // Проходимся по всем трекам в передаваемом плейлисте.
    final List<ExtendedAudio> newAudios = [];
    if (playlist.audios != null) {
      final List<ExtendedAudio> existingAudios = existingPlaylist.audios ?? [];

      for (ExtendedAudio givenAudio in [...playlist.audios!]) {
        final ExtendedAudio? existingAudio = existingAudios
            .firstWhereOrNull((oldAudio) => oldAudio == givenAudio);

        // Трек не найден, добавляем его.
        if (existingAudio == null) {
          newAudios.add(givenAudio);

          playlistChanged = true;

          continue;
        }

        // Если трек не отличается, то ничего не меняем.
        if (existingAudio.title == givenAudio.title &&
            existingAudio.artist == givenAudio.artist &&
            (existingAudio.isCached ?? false) ==
                (givenAudio.isCached ?? false) &&
            (existingAudio.album == givenAudio.album ||
                givenAudio.album == null) &&
            existingAudio.hasLyrics == givenAudio.hasLyrics &&
            existingAudio.lyrics == givenAudio.lyrics &&
            existingAudio.isLiked == givenAudio.isLiked &&
            existingAudio.frequentColorInt == givenAudio.frequentColorInt) {
          newAudios.add(givenAudio);

          continue;
        }

        newAudios.add(
          existingAudio.copyWith(
            title: givenAudio.title,
            artist: givenAudio.artist,
            url: givenAudio.url,
            isCached: givenAudio.isCached,
            album: givenAudio.album,
            hasLyrics: givenAudio.hasLyrics,
            lyrics: givenAudio.lyrics,
            vkThumbs: givenAudio.vkThumbs,
            isLiked: givenAudio.isLiked,
            colorCount: givenAudio.colorCount,
            colorInts: givenAudio.colorInts,
            scoredColorInts: givenAudio.scoredColorInts,
            frequentColorInt: givenAudio.frequentColorInt,
          ),
        );

        playlistChanged = true;
      }

      // Проходимся по тому списку треков, которые кэшированы, но больше нет в плейлисте.
      final List<ExtendedAudio> removedAudios = existingAudios
          .where(
            (audio) =>
                (audio.isCached ?? false) && !playlist.audios!.contains(audio),
          )
          .toList();

      // Проходимся по списку из "удалённых" из плейлиста треков.
      for (ExtendedAudio audio in removedAudios) {
        logger.d("$audio should be deleted");

        playlistChanged = true;
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
      final ExtendedPlaylist newPlaylist = existingPlaylist.copyWith(
        count: playlist.count,
        title: playlist.title,
        description: playlist.description,
        subtitle: playlist.subtitle,
        cacheTracks: playlist.cacheTracks,
        photo: playlist.photo,
        createTime: playlist.createTime,
        updateTime: playlist.updateTime,
        followers: playlist.followers,
        areTracksLive: playlist.areTracksLive,
        backgroundAnimationUrl: playlist.backgroundAnimationUrl,
        isLiveData: playlist.isLiveData,
        audios: newAudios,
      );

      // Обновляем плейлист.
      allPlaylists.removeWhere(
        (a) => a.id == playlist.id && a.ownerID == playlist.ownerID,
      );
      allPlaylists.add(newPlaylist);

      // Обновляем состояние интерфейса.
      state = AsyncData(
        state.value!.copyWith(
          playlists: allPlaylists,
        ),
      );

      // Отправляем событие об изменении плейлиста.
      PlaylistsState.playlistModificationsController.add(newPlaylist);

      // Сохраняем в БД.
      if (saveInDB) {
        await appStorage.savePlaylist(newPlaylist.asDBPlaylist);
      }

      logger.d("Playlist has changed");
    } else {
      logger.d("No changes to the playlist");
    }

    return playlistChanged;
  }

  /// Обновляет состояние данного Provider, объединяя новые и старые версии плейлистров, а после чего сохраняет их в БД, если [saveInDB] правдив.
  ///
  /// Возвращает то, был ли изменён хотя бы один из плейлистов после объединения.
  Future<bool> updatePlaylists(
    List<ExtendedPlaylist> newPlaylists, {
    bool saveInDB = false,
    bool fromAPI = false,
  }) async {
    final List<ExtendedPlaylist> changedPlaylists = [];
    for (ExtendedPlaylist playlist in newPlaylists) {
      final bool changed = await updatePlaylist(
        playlist,
        fromAPI: fromAPI,
      );

      // Если этот плейлист считается изменённым, то запоминаем его что бы потом массово сохранить.
      if (changed) {
        changedPlaylists.add(playlist);
      }
    }

    // Если у нас есть несохранённые плейлисты, то массово сохраняем их.
    if (changedPlaylists.isNotEmpty) {
      await appStorage.savePlaylists(
        changedPlaylists
            .map(
              (playlist) => playlist.asDBPlaylist,
            )
            .toList(),
      );
    }

    return changedPlaylists.isNotEmpty;
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
        (playlist) => playlist.isFavoritesPlaylist,
      );

  /// Возвращает плейлист по передаваемому [ownerID] и [id].
  ExtendedPlaylist? getPlaylist(int ownerID, int id) =>
      state.value?.playlists.firstWhereOrNull(
        (playlist) => playlist.ownerID == ownerID && playlist.id == id,
      );

  /// Сбрасывает [state] данного Provider, сбрасывая список всех плейлистов.
  void reset() => state = const AsyncLoading();

  /// Загружает информацию с API ВКонтакте по [playlist], если она не была загружена ранее, и обновляет state данного объекта.
  Future<void> loadPlaylist(ExtendedPlaylist playlist) async {
    final user = ref.read(userProvider.notifier);

    // Если информация по плейлисту уже загружена, то ничего не делаем.
    if (playlist.isFavoritesPlaylist ||
        (playlist.audios != null &&
            playlist.isLiveData &&
            playlist.areTracksLive)) {
      return;
    }

    logger.d("Loading data for $playlist");

    final APIMassAudioGetResponse response =
        await user.scriptMassAudioGetWithAlbums(
      playlist.ownerID,
      albumID: playlist.id,
      accessKey: playlist.accessKey,
    );
    raiseOnAPIError(response);

    await updatePlaylist(
      playlist.copyWith(
        photo: response.response!.playlists
            .firstWhereOrNull(
              (item) => item.mediaKey == playlist.mediaKey,
            )
            ?.photo,
        audios: response.response!.audios
            .map(
              (item) => ExtendedAudio.fromAPIAudio(item),
            )
            .toList(),
        count: response.response!.audioCount,
        isLiveData: true,
        areTracksLive: true,
      ),
    );
  }
}

/// [Provider], возвращающий [ExtendedPlaylist], характеризующий фейковый плейлист "Любимая музыка".
@riverpod
ExtendedPlaylist? favoritesPlaylist(FavoritesPlaylistRef ref) {
  final PlaylistsState? state =
      ref.watch(playlistsProvider).unwrapPrevious().valueOrNull;
  if (state == null) return null;

  return state.playlists.firstWhereOrNull(
    (ExtendedPlaylist playlist) => playlist.isFavoritesPlaylist,
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
        (ExtendedPlaylist playlist) => playlist.isRegularPlaylist,
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
        (ExtendedPlaylist playlist) => playlist.isAudioMixPlaylist,
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
        (ExtendedPlaylist playlist) => playlist.isMoodPlaylist,
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
        (ExtendedPlaylist playlist) => playlist.isRecommendationsPlaylist,
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
        (ExtendedPlaylist playlist) => playlist.isSimillarPlaylist,
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
        (ExtendedPlaylist playlist) => playlist.isMadeByVKPlaylist,
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
