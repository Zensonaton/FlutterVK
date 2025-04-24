// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../../../main.dart";
import "../shared.dart";

part "get_playlists.g.dart";

/// Ответ для метода [audio_get_playlists].
@JsonSerializable()
class APIAudioGetPlaylistsResponse {
  /// Количество плейлистов.
  final int count;

  /// Информация о плейлистах.
  final List<Playlist> items;

  APIAudioGetPlaylistsResponse({
    required this.count,
    required this.items,
  });

  factory APIAudioGetPlaylistsResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioGetPlaylistsResponseFromJson(json);
}

/// {@template VKAPI.audio.getPlaylists}
/// Возвращает информацию о плейлистах пользователя.
/// {@endtemplate}
///
/// API: `audio.getPlaylists`.
Future<APIAudioGetPlaylistsResponse> audio_get_playlists(int userID) async {
  var response = await vkDio.post(
    "audio.getPlaylists",
    data: {
      "owner_id": userID,
      "count": 100,

      // Demo response
      "_demo_": {
        // TODO
        "count": 0,
        "items": [],
      },
    },
  );

  return APIAudioGetPlaylistsResponse.fromJson(response.data);
}
