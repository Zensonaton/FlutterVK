import "package:collection/collection.dart";
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
  /// Указывает, загружены ли плейлисты через API ВКонтакте.
  ///
  /// Если false, то значит, что плейлисты кэшированы.
  final bool fromAPI;

  /// [List] из всех плейлистов у пользователя.
  final List<ExtendedPlaylist> playlists;

  /// Количество всех созданых плейлистов пользователя (те, что находятся в разделе "Ваши плейлисты").
  final int? playlistsCount;

  @override
  bool operator ==(covariant PlaylistsState other) {
    if (identical(this, other)) return true;

    return other.fromAPI == fromAPI &&
        other.playlistsCount == playlistsCount &&
        other.playlists == playlists;
  }

  @override
  int get hashCode => playlists.hashCode;

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
    // FIXME: При получении плейлистов с БД, записи в БД забываются. Нужно merge'ить плейлисты.

    // Загружаем плейлисты из локальной БД, если они не были загружены ранее.
    if (!state.hasValue || !(state.value?.fromAPI ?? false)) {
      final PlaylistsState? playlistsState =
          await ref.read(dbPlaylistsProvider.future);
      if (playlistsState != null) {
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

    state = AsyncData(
      PlaylistsState(
        playlists: playlists,
        fromAPI: true,
        playlistsCount: userPlaylists.$2,
      ),
    );

    // Загружаем эти плейлисты в БД.
    await appStorage.savePlaylists(
      playlists
          .map((ExtendedPlaylist playlist) => playlist.asDBPlaylist)
          .toList(),
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
        logger.w("Блок с рекомендуемыми плейлистами не был найден");

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
      SectionBlock? recommendedPlaylistsBlock =
          mainSection.blocks!.lastWhereOrNull(
        (SectionBlock block) => block.dataType == "music_playlists",
      );

      if (recommendedPlaylistsBlock == null) {
        logger.w("Блок с разделом 'собрано редакцией' не был найден");

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
}

/// [Provider], возвращающий [ExtendedPlaylist], характеризующий фейковый плейлист "Любимая музыка".
@riverpod
ExtendedPlaylist? favoritesPlaylist(FavoritesPlaylistRef ref) {
  final PlaylistsState? state = ref.watch(playlistsProvider).value;
  if (state == null) return null;

  return state.playlists.firstWhereOrNull(
    (ExtendedPlaylist playlist) => playlist.isFavoritesPlaylist,
  );
}

/// [Provider], возвращающий список плейлистов ([ExtendedPlaylist]) пользователя.
@riverpod
List<ExtendedPlaylist>? userPlaylists(UserPlaylistsRef ref) {
  final PlaylistsState? state = ref.watch(playlistsProvider).value;
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
  final PlaylistsState? state = ref.watch(playlistsProvider).value;
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
  final PlaylistsState? state = ref.watch(playlistsProvider).value;
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
  final PlaylistsState? state = ref.watch(playlistsProvider).value;
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
  final PlaylistsState? state = ref.watch(playlistsProvider).value;
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
  final PlaylistsState? state = ref.watch(playlistsProvider).value;
  if (state == null) return null;

  final List<ExtendedPlaylist> playlists = state.playlists
      .where(
        (ExtendedPlaylist playlist) => playlist.isMadeByVKPlaylist,
      )
      .toList();
  if (playlists.isEmpty && !state.fromAPI) return null;

  return playlists;
}
