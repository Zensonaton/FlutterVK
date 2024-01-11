// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../execute.dart";
import "../shared.dart";

part "mass_audio_get.g.dart";

@JsonSerializable()
class APIMassAudioGetRealResponse {
  /// Количество треков.
  final int audioCount;

  /// Массив с треками.
  final List<Audio> audios;

  /// Количество плейлистов.
  final int playlistsCount;

  /// Плейлисты.
  final List<AudioPlaylist> playlists;

  APIMassAudioGetRealResponse(
    this.audioCount,
    this.audios,
    this.playlistsCount,
    this.playlists,
  );

  factory APIMassAudioGetRealResponse.fromJson(Map<String, dynamic> json) =>
      _$APIMassAudioGetRealResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIMassAudioGetRealResponseToJson(this);
}

/// Ответ для метода [scripts_massAudioGet].
@JsonSerializable()
class APIMassAudioGetResponse {
  /// Объект ответа.
  final APIMassAudioGetRealResponse? response;

  /// Объект ошибки.
  final APIError? error;

  APIMassAudioGetResponse(
    this.response,
    this.error,
  );

  factory APIMassAudioGetResponse.fromJson(Map<String, dynamic> json) =>
      _$APIMassAudioGetResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIMassAudioGetResponseToJson(this);
}

/// Массово извлекает список лайкнутых треков ВКонтакте. Максимум извлекает около 5000 треков.
///
/// Для данного метода требуется токен от Kate Mobile.
Future<APIMassAudioGetResponse> scripts_massAudioGet(
  String token,
  int userID, {
  int? albumID,
}) async {
  // TODO: Метод для offset'а.

  final String executeCode = """
var selfID = $userID;
var albumID = ${albumID ?? 0};
var audios = [];

var audioCount = 1;
var audioIndex = 0;
while (audioIndex < audioCount) {
	var resp = API.audio.get({'count': 200, 'offset': audioIndex, 'album_id': albumID});
	audioCount = resp.count;

	var i = 0;
	while (i < resp.items.length) {
		var item = resp.items[i];

		audios.push(item);

		i = i + 1;
	};

	audioIndex = audioIndex + 200;
};

var playlistsResp = API.audio.getPlaylists({'owner_id': selfID});

return {'audioCount': audioCount, 'audios': audios, 'playlistsCount': playlistsResp.count, 'playlists': playlistsResp.items};""";

  var response = await VKExecuteAPI.execute(
    token,
    executeCode,
  );

  return APIMassAudioGetResponse.fromJson(jsonDecode(response.body));
}
