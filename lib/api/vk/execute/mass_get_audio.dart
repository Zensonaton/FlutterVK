// ignore_for_file: non_constant_identifier_names

import "package:flutter/foundation.dart";
import "package:json_annotation/json_annotation.dart";

import "../../../utils.dart";
import "../api.dart";
import "../shared.dart";

part "mass_get_audio.g.dart";

@JsonSerializable()
class APIMassAudioGetRealResponse {
  /// Количество треков.
  final int audioCount;

  /// Массив с треками.
  final List<Audio> audios;

  /// Количество плейлистов.
  final int playlistsCount;

  /// Плейлисты.
  final List<Playlist> playlists;

  APIMassAudioGetRealResponse({
    required this.audioCount,
    required this.audios,
    required this.playlistsCount,
    required this.playlists,
  });

  factory APIMassAudioGetRealResponse.fromJson(Map<String, dynamic> json) =>
      _$APIMassAudioGetRealResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIMassAudioGetRealResponseToJson(this);
}

/// Ответ для метода [execute_mass_get_audio].
@JsonSerializable()
class APIMassAudioGetResponse {
  /// Объект ответа.
  final APIMassAudioGetRealResponse? response;

  /// Объект ошибки.
  final APIError? error;

  APIMassAudioGetResponse({
    this.response,
    this.error,
  });

  factory APIMassAudioGetResponse.fromJson(Map<String, dynamic> json) =>
      _$APIMassAudioGetResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIMassAudioGetResponseToJson(this);
}

/// {@template VKAPI.execute.massGetAudio}
/// Массово извлекает список лайкнутых треков ВКонтакте. Максимум извлекает около 5000 треков.
/// {@endtemplate}
///
/// Для данного метода требуется токен от Kate Mobile.
Future<APIMassAudioGetResponse> execute_mass_get_audio(
  String token,
  int ownerID, {
  int? albumID,
  String? accessKey,
}) async {
  // TODO: Метод для offset'а.

  final String codeToExecute = """
var ownerID = $ownerID;
var albumID = ${albumID ?? 0};
var accessKey = '${accessKey ?? ''}';
var audios = [];

var audioCount = 1;
var audioIndex = 0;
while (audioIndex < audioCount) {
	var resp = API.audio.get({'count': 200, 'offset': audioIndex, 'owner_id': ownerID, 'album_id': albumID, 'access_key': accessKey});

	audioCount = resp.count;
  audios = audios + resp.items;

	audioIndex = audioIndex + 200;
};

var playlistsResp = API.audio.getPlaylists({'owner_id': ownerID, 'count': 50});

return {'audioCount': audioCount, 'audios': audios, 'playlistsCount': playlistsResp.count, 'playlists': playlistsResp.items};""";

  var response = await callVkAPI(
    "execute",
    token,
    {
      "code": minimizeJS(codeToExecute),
    },
  );

  return await compute(
    (message) => APIMassAudioGetResponse.fromJson(message),
    response.data,
  );
}
