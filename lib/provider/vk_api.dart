import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../api/vk/api.dart";
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
  Future<APIUsersGetResponse> get(List<int> ids) =>
      users_get(this.token, ids: ids);
}

/// Класс, предоставляющий доступ к методам API ВКонтакте, связанным с аудиозаписями (`audio`).
class VKAPIAudio extends VKAPICategory {
  VKAPIAudio({
    required super.ref,
  });

  /// {@macro VKAPI.audio.addDislike}
  Future<APIAudioAddDislikeResponse> addDislike(List<String> mediaKeys) =>
      audio_add_dislike(this.token, mediaKeys);

  /// {@macro VKAPI.audio.add}
  Future<APIAudioAddResponse> add(int id, int ownerID) =>
      audio_add(this.token, id, ownerID);

  /// {@macro VKAPI.audio.delete}
  Future<APIAudioDeleteResponse> delete(int id, int ownerID) =>
      audio_delete(this.token, id, ownerID);

  /// {@macro VKAPI.audio.edit}
  Future<APIAudioEditResponse> edit(
    int id,
    int ownerID,
    String title,
    String artist,
    int genreID,
  ) =>
      audio_edit(this.token, id, ownerID, title, artist, genreID);

  /// {@macro VKAPI.audio.getLyrics}
  Future<APIAudioGetLyricsResponse> getLyrics(String mediaKey) =>
      audio_get_lyrics(this.token, mediaKey);

  /// {@macro VKAPI.audio.getPlaylists}
  Future<APIAudioGetPlaylistsResponse> getPlaylists(int ownerID) =>
      audio_get_playlists(this.token, ownerID);

  /// {@macro VKAPI.audio.getStreamMixAudios}
  Future<APIAudioGetStreamMixAudiosResponse> getStreamMixAudios({
    String mixID = "common",
    int count = 10,
  }) =>
      audio_get_stream_mix_audios(this.token, mixID, count);

  /// {@macro VKAPI.audio.getStreamMixAudios}
  ///
  /// В отличии от [getStreamMixAudios], данный метод добавляет трекам информацию о их альбомах.
  Future<APIAudioGetStreamMixAudiosResponse> getStreamMixAudiosWithAlbums({
    String mixID = "common",
    int count = 10,
  }) async {
    // Получаем список треков.
    final APIAudioGetStreamMixAudiosResponse response =
        await getStreamMixAudios(
      mixID: mixID,
      count: count,
    );
    raiseOnAPIError(response);

    // Если вторичного токена нет, то возвращаем ответ без дополнительной информации.
    if (this.secondaryToken == null) return response;

    // Получаем информацию о альбомах.
    final APIMassAudioAlbumsResponse audiosWithAlbums =
        await execute_mass_get_albums(
      this.secondaryToken!,
      response.response!.map((audio) => audio.mediaKey).toList(),
    );
    raiseOnAPIError(audiosWithAlbums);

    return APIAudioGetStreamMixAudiosResponse(
      response: audiosWithAlbums.response!,
    );
  }

  /// {@macro VKAPI.audio.get}
  Future<APIAudioGetResponse> get(int userID) => audio_get(this.token, userID);

  /// {@macro VKAPI.audio.get}
  ///
  /// В отличии от [get], данный метод добавляет трекам информацию о их альбомах.
  Future<APIMassAudioGetResponse> getWithAlbums(
    int ownerID, {
    int? albumID,
    String? accessKey,
  }) async {
    // Получаем список треков.
    final APIMassAudioGetResponse response = await execute_mass_get_audio(
      this.token,
      ownerID,
      albumID: albumID,
      accessKey: accessKey,
    );
    raiseOnAPIError(response);

    // Если вторичного токена нет, то возвращаем ответ без дополнительной информации.
    if (this.secondaryToken == null) return response;

    // Получаем информацию о альбомах.
    final APIMassAudioAlbumsResponse audiosWithAlbums =
        await execute_mass_get_albums(
      this.secondaryToken!,
      response.response!.audios.map((audio) => audio.mediaKey).toList(),
    );
    raiseOnAPIError(audiosWithAlbums);

    return APIMassAudioGetResponse(
      response: APIMassAudioGetRealResponse(
        audioCount: response.response!.audioCount,
        audios: audiosWithAlbums.response!,
        playlistsCount: response.response!.playlistsCount,
        playlists: response.response!.playlists,
      ),
    );
  }

  /// {@macro VKAPI.audio.restore}
  Future<APIAudioRestoreResponse> restore(
    int id,
    int ownerID,
  ) =>
      audio_restore(this.token, id, ownerID);

  /// {@macro VKAPI.audio.search}
  Future<APIAudioSearchResponse> search(
    String query, {
    bool autoComplete = true,
    int count = 50,
    int offset = 0,
  }) =>
      audio_search(
        this.token,
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
    // Получаем список треков.
    final APIAudioSearchResponse response = await audio_search(
      this.token,
      query,
      autoComplete: autoComplete,
      count: count,
      offset: offset,
    );
    raiseOnAPIError(response);

    // Если вторичного токена нет, то возвращаем ответ без дополнительной информации.
    if (this.secondaryToken == null) return response;

    // Получаем информацию о альбомах.
    final APIMassAudioAlbumsResponse audiosWithAlbums =
        await execute_mass_get_albums(
      this.secondaryToken!,
      response.response!.items.map((audio) => audio.mediaKey).toList(),
    );
    raiseOnAPIError(audiosWithAlbums);

    return APIAudioSearchResponse(
      response: APIAudioSearchRealResponse(
        count: response.response!.count,
        items: audiosWithAlbums.response!,
      ),
    );
  }

  /// {@macro VKAPI.audio.sendStartEvent}
  Future<APIAudioSendStartEventResponse> sendStartEvent(String mediaKey) =>
      audio_send_start_event(this.token, mediaKey);
}

/// Класс, предоставляющий доступ к методам API ВКонтакте, связанным с каталогом аудиозаписей (`catalog`).
class VKAPICatalog extends VKAPICategory {
  VKAPICatalog({
    required super.ref,
  });

  /// {@macro VKAPI.catalog.getAudio}
  Future<APICatalogGetAudioResponse> getAudio() =>
      catalog_get_audio(this.secondaryToken!);
}

/// Класс, предоставляющий доступ к helper-методам для API ВКонтакте, предоставляющие удобный доступ к `execute`-скриптам.
class VKAPIExecute extends VKAPICategory {
  VKAPIExecute({
    required super.ref,
  });

  /// {@macro VKAPI.execute.massGetAlbums}
  Future<APIMassAudioAlbumsResponse> massGetAlbums(List<String> mediaKeys) =>
      execute_mass_get_albums(this.secondaryToken!, mediaKeys);

  /// {@macro VKAPI.execute.massGetAudio}
  Future<APIMassAudioGetResponse> massGetAudio(
    int ownerID, {
    int? albumID,
    String? accessKey,
  }) =>
      execute_mass_get_audio(
        this.secondaryToken!,
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
