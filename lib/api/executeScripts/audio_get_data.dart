// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../execute.dart";
import "../shared.dart";

part "audio_get_data.g.dart";

@JsonSerializable()
class APIAudioGetDataRealResponse {
  /// Количество треков.
  final int audioCount;

  /// Массив с треками.
  final List<Audio> audios;

  /// Количество плейлистов.
  final int playlistsCount;

  /// Плейлисты.
  final List<AudioPlaylist> playlists;

  APIAudioGetDataRealResponse(
    this.audioCount,
    this.audios,
    this.playlistsCount,
    this.playlists,
  );

  factory APIAudioGetDataRealResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioGetDataRealResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioGetDataRealResponseToJson(this);
}

/// Ответ для метода [massGet].
@JsonSerializable()
class APIAudioGetDataResponse {
  /// Объект ответа.
  final APIAudioGetDataRealResponse? response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioGetDataResponse(
    this.response,
    this.error,
  );

  factory APIAudioGetDataResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioGetDataResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioGetDataResponseToJson(this);
}

/// Извлекает <200 лайкнутых треков, а так же <50 плейлистов пользователя.
///
/// Для данного метода требуется токен от Kate Mobile.
Future<APIAudioGetDataResponse> scripts_getFavAudioAndPlaylists(
  String token,
  int userID,
) async {
  final String executeCode = """
var selfID = $userID;

var audiosResp = API.audio.get({'count': 200, 'offset': 0});
var playlistsResp = API.audio.getPlaylists({'owner_id': selfID});

return {'audioCount': audiosResp.count, 'audios': audiosResp.items, 'playlistsCount': playlistsResp.count, 'playlists': playlistsResp.items};""";

  var response = await VKExecuteAPI.execute(
    token,
    executeCode,
  );

  return APIAudioGetDataResponse.fromJson(jsonDecode(response.body));
}
