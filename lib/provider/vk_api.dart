import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../api/vk/audio/add.dart";
import "../api/vk/audio/add_dislike.dart";
import "../api/vk/audio/delete.dart";
import "../api/vk/audio/edit.dart";
import "../api/vk/audio/get.dart";
import "../api/vk/audio/get_lyrics.dart";
import "../api/vk/audio/get_playlists.dart";
import "../api/vk/audio/get_stream_mix_audios.dart";
import "../api/vk/audio/restore.dart";
import "../api/vk/audio/search.dart";
import "../api/vk/audio/send_start_event.dart";
import "../api/vk/catalog/get_audio.dart";
import "../api/vk/execute/mass_get_albums.dart";
import "../api/vk/execute/mass_get_audio.dart";
import "../api/vk/shared.dart";
import "../api/vk/users/get.dart";
import "auth.dart";

part "vk_api.g.dart";

/// Возвращает класс [VKAPI], предоставляющий доступ к методам API ВКонтакте.
@riverpod
VKAPI vkAPI(VkAPIRef ref) => VKAPI(ref: ref);

/// Класс, предоставляющий простой доступ к различным категориям API ВКонтакте.
///
/// Стоит обратить внимание на следующие категории API ВКонтакте:
/// - [VKAPIUsers].
/// - [VKAPIAudio].
/// - [VKAPICatalog].
/// - [VKAPIExecute].
class VKAPI {
  /// Раздел API, отвечающий за пользователей (`users`).
  final VKAPIUsers users;

  /// Раздел API, отвечающий за аудиозаписи (`audio`).
  final VKAPIAudio audio;

  /// Раздел API, отвечающий за каталог аудиозаписей (`catalog`).
  final VKAPICatalog catalog;

  /// Раздел API, дающий доступ к различным скриптам  (`execute`).
  final VKAPIExecute execute;

  VKAPI({
    required VkAPIRef ref,
  })  : users = VKAPIUsers(ref: ref),
        audio = VKAPIAudio(ref: ref),
        catalog = VKAPICatalog(ref: ref),
        execute = VKAPIExecute(ref: ref);
}

/// Категория API ВКонтакте.
class VKAPICategory {
  final Ref _ref;

  /// Возвращает основной токен ВКонтакте. (Kate Mobile)
  String get token => _ref.read(tokenProvider)!;

  /// Возвращает вторичный токен ВКонтакте. (VK Admin)
  String? get secondaryToken => _ref.read(secondaryTokenProvider);

  VKAPICategory({
    required Ref ref,
  }) : _ref = ref;
}

/// Класс, предоставляющий доступ к методам API ВКонтакте, связанным с пользователями (`users`).
class VKAPIUsers extends VKAPICategory {
  VKAPIUsers({
    required super.ref,
  });

  /// {@macro VKAPI.users.get}
  Future<List<APIUser>> get(List<int> ids) => users_get(ids: ids);
}

/// Класс, предоставляющий доступ к методам API ВКонтакте, связанным с аудиозаписями (`audio`).
class VKAPIAudio extends VKAPICategory {
  VKAPIAudio({
    required super.ref,
  });

  /// {@macro VKAPI.audio.addDislike}
  Future<bool> addDislike(List<String> mediaKeys) =>
      audio_add_dislike(mediaKeys);

  /// {@macro VKAPI.audio.add}
  Future<int> add(int id, int ownerID) => audio_add(id, ownerID);

  /// {@macro VKAPI.audio.delete}
  Future<bool> delete(int id, int ownerID) => audio_delete(id, ownerID);

  /// {@macro VKAPI.audio.edit}
  Future<int> edit(
    int id,
    int ownerID,
    String title,
    String artist,
    int genreID,
  ) =>
      audio_edit(id, ownerID, title, artist, genreID);

  /// {@macro VKAPI.audio.getLyrics}
  Future<APIAudioGetLyricsResponse> getLyrics(String mediaKey) =>
      audio_get_lyrics(mediaKey);

  /// {@macro VKAPI.audio.getPlaylists}
  Future<APIAudioGetPlaylistsResponse> getPlaylists(int ownerID) =>
      audio_get_playlists(ownerID);

  /// {@macro VKAPI.audio.getStreamMixAudios}
  Future<List<Audio>> getStreamMixAudios({
    String mixID = "common",
    int count = 10,
  }) =>
      audio_get_stream_mix_audios(mixID, count);

  /// {@macro VKAPI.audio.getStreamMixAudios}
  ///
  /// В отличии от [getStreamMixAudios], данный метод добавляет трекам информацию о их альбомах.
  Future<List<Audio>> getStreamMixAudiosWithAlbums({
    String mixID = "common",
    int count = 10,
  }) async {
    final api = _ref.read(vkAPIExecuteProvider);

    // Получаем список треков.
    final List<Audio> response = await getStreamMixAudios(
      mixID: mixID,
      count: count,
    );

    // Если вторичного токена нет, то возвращаем ответ без дополнительной информации.
    if (this.secondaryToken == null) return response;

    return await api.massGetAlbums(
      response.map((audio) => audio.mediaKey).toList(),
    );
  }

  /// {@macro VKAPI.audio.get}
  Future<APIAudioGetResponse> get(int userID) => audio_get(userID);

  /// {@macro VKAPI.audio.get}
  ///
  /// В отличии от [get], данный метод добавляет трекам информацию о их альбомах.
  Future<APIMassAudioGetResponse> getWithAlbums(
    int ownerID, {
    int? albumID,
    String? accessKey,
  }) async {
    final api = _ref.read(vkAPIExecuteProvider);

    // Получаем список треков.
    final APIMassAudioGetResponse response = await api.massGetAudio(
      ownerID,
      albumID: albumID,
      accessKey: accessKey,
    );

    // Если вторичного токена нет, то возвращаем ответ без дополнительной информации.
    if (this.secondaryToken == null) return response;

    // Получаем информацию о альбомах.
    final audiosWithAlbums = await api.massGetAlbums(
      response.audios.map((audio) => audio.mediaKey).toList(),
    );

    return APIMassAudioGetResponse(
      audioCount: response.audioCount,
      audios: audiosWithAlbums,
      playlistsCount: response.playlistsCount,
      playlists: response.playlists,
    );
  }

  /// {@macro VKAPI.audio.restore}
  Future<Audio> restore(int id, int ownerID) => audio_restore(id, ownerID);

  /// {@macro VKAPI.audio.search}
  Future<APIAudioSearchResponse> search(
    String query, {
    bool autoComplete = true,
    int count = 50,
    int offset = 0,
  }) =>
      audio_search(
        query,
        autoComplete: autoComplete,
        count: count,
        offset: offset,
      );

  /// {@macro VKAPI.audio.search}
  ///
  /// В отличии от [search], данный метод добавляет трекам информацию о их альбомах.
  Future<APIAudioSearchResponse> searchWithAlbums(
    String query, {
    bool autoComplete = true,
    int count = 50,
    int offset = 0,
  }) async {
    final api = _ref.read(vkAPIExecuteProvider);

    // Получаем список треков.
    final APIAudioSearchResponse response = await search(
      query,
      autoComplete: autoComplete,
      count: count,
      offset: offset,
    );

    // Если вторичного токена нет, то возвращаем ответ без дополнительной информации.
    if (this.secondaryToken == null) return response;

    // Получаем информацию о альбомах.
    final List<Audio> audiosWithAlbums = await api.massGetAlbums(
      response.items.map((audio) => audio.mediaKey).toList(),
    );

    return APIAudioSearchResponse(
      count: response.count,
      items: audiosWithAlbums,
    );
  }

  /// {@macro VKAPI.audio.sendStartEvent}
  Future<dynamic> sendStartEvent(String mediaKey) =>
      audio_send_start_event(mediaKey);
}

/// Класс, предоставляющий доступ к методам API ВКонтакте, связанным с каталогом аудиозаписей (`catalog`).
class VKAPICatalog extends VKAPICategory {
  VKAPICatalog({
    required super.ref,
  });

  /// {@macro VKAPI.catalog.getAudio}
  Future<APICatalogGetAudioResponse> getAudio() => catalog_get_audio();
}

/// Класс, предоставляющий доступ к helper-методам для API ВКонтакте, предоставляющие удобный доступ к `execute`-скриптам.
class VKAPIExecute extends VKAPICategory {
  VKAPIExecute({
    required super.ref,
  });

  /// {@macro VKAPI.execute.massGetAlbums}
  Future<List<Audio>> massGetAlbums(List<String> mediaKeys) =>
      execute_mass_get_albums(mediaKeys);

  /// {@macro VKAPI.execute.massGetAudio}
  Future<APIMassAudioGetResponse> massGetAudio(
    int ownerID, {
    int? albumID,
    String? accessKey,
  }) =>
      execute_mass_get_audio(
        ownerID,
        albumID: albumID,
        accessKey: accessKey,
      );
}

/// Возвращает категорию API ВКонтакте типа [VKAPIUsers].
///
/// Вместо данного метода рекомендуется использовать [vkAPIProvider].
@riverpod
VKAPIUsers vkAPIUsers(VkAPIUsersRef ref) => VKAPIUsers(ref: ref);

/// Возвращает категорию API ВКонтакте типа [VKAPIAudio].
///
/// Вместо данного метода рекомендуется использовать [vkAPIProvider].
@riverpod
VKAPIAudio vkAPIAudio(VkAPIAudioRef ref) => VKAPIAudio(ref: ref);

/// Возвращает категорию API ВКонтакте типа [VKAPICatalog].
///
/// Вместо данного метода рекомендуется использовать [vkAPIProvider].
@riverpod
VKAPICatalog vkAPICatalog(VkAPICatalogRef ref) => VKAPICatalog(ref: ref);

/// Возвращает категорию API ВКонтакте типа [VKAPIExecute].
///
/// Вместо данного метода рекомендуется использовать [vkAPIProvider].
@riverpod
VKAPIExecute vkAPIExecute(VkAPIExecuteRef ref) => VKAPIExecute(ref: ref);
