// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "get_playlists.g.dart";

@JsonSerializable()
class APIAudioGetPlaylistsRealResponse {
  /// Количество плейлистов.
  final int count;

  /// Информация о плейлистах.
  final List<AudioPlaylist> items;

  APIAudioGetPlaylistsRealResponse(
    this.count,
    this.items,
  );

  factory APIAudioGetPlaylistsRealResponse.fromJson(
          Map<String, dynamic> json) =>
      _$APIAudioGetPlaylistsRealResponseFromJson(json);
  Map<String, dynamic> toJson() =>
      _$APIAudioGetPlaylistsRealResponseToJson(this);
}

/// Ответ для метода [audio_getPlaylists].
@JsonSerializable()
class APIAudioGetPlaylistsResponse {
  /// Объект ответа.
  final APIAudioGetPlaylistsRealResponse? response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioGetPlaylistsResponse(
    this.response,
    this.error,
  );

  factory APIAudioGetPlaylistsResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioGetPlaylistsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioGetPlaylistsResponseToJson(this);
}

/// Возвращает информацию о аудио плейлистах указанного пользователя.
///
/// API: `audio.getPlaylists`.
Future<APIAudioGetPlaylistsResponse> audio_getPlaylists(
  String token,
  int userID,
) async {
  var response = await vkAPIcall(
    "audio.getPlaylists",
    token,
    {
      "owner_id": userID.toString(),
      "count": 100.toString(),
    },
  );

  return APIAudioGetPlaylistsResponse.fromJson(jsonDecode(response.body));
}
