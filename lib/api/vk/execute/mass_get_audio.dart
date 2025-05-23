// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../../../main.dart";
import "../../../utils.dart";
import "../fake.dart";
import "../shared.dart";

part "mass_get_audio.g.dart";

/// Возвращает фейковые данные для этого метода.
Map<String, dynamic> _getFakeData(int? albumID) {
  List<Audio> audios = switch (albumID) {
    null => fakeMyMusicAudio,
    1 => fakeClancyTourAudio,
    2 => fakeCunksFavoritesAudio,
    _ => fakePlaylistAudios,
  };

  return {
    "audioCount": audios.length,
    "audios": audios
        .map(
          (audio) => audio.toJson(),
        )
        .toList(),
    "playlistsCount": fakeYourPlaylists.length,
    "playlists": fakeYourPlaylists
        .map(
          (playlist) => playlist.toJson(),
        )
        .toList(),
  };
}

/// Ответ для метода [execute_mass_get_audio].
@JsonSerializable()
class APIMassAudioGetResponse {
  /// Количество треков.
  final int audioCount;

  /// Массив с треками.
  final List<Audio> audios;

  /// Количество плейлистов.
  final int playlistsCount;

  /// Плейлисты.
  final List<Playlist> playlists;

  APIMassAudioGetResponse({
    required this.audioCount,
    required this.audios,
    required this.playlistsCount,
    required this.playlists,
  });

  factory APIMassAudioGetResponse.fromJson(Map<String, dynamic> json) =>
      _$APIMassAudioGetResponseFromJson(json);
}

/// {@template VKAPI.execute.massGetAudio}
/// Массово извлекает список лайкнутых треков ВКонтакте. Максимум извлекает около 5000 треков.
/// {@endtemplate}
///
/// Для данного метода требуется токен от Kate Mobile.
Future<APIMassAudioGetResponse> execute_mass_get_audio(
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

  var response = await vkDio.post(
    "execute",
    data: {
      "code": minimizeJS(codeToExecute),

      // Demo response
      "_demo_": _getFakeData(albumID),
    },
  );

  return APIMassAudioGetResponse.fromJson(response.data);
}
