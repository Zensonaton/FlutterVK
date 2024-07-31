// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "get_playlists.g.dart";

@JsonSerializable()
class APIAudioGetPlaylistsRealResponse {
  /// Количество плейлистов.
  final int count;

  /// Информация о плейлистах.
  final List<Playlist> items;

  APIAudioGetPlaylistsRealResponse({
    required this.count,
    required this.items,
  });

  factory APIAudioGetPlaylistsRealResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$APIAudioGetPlaylistsRealResponseFromJson(json);
  Map<String, dynamic> toJson() =>
      _$APIAudioGetPlaylistsRealResponseToJson(this);
}

/// Ответ для метода [audio_get_playlists].
@JsonSerializable()
class APIAudioGetPlaylistsResponse {
  /// Объект ответа.
  final APIAudioGetPlaylistsRealResponse? response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioGetPlaylistsResponse({
    this.response,
    this.error,
  });

  factory APIAudioGetPlaylistsResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioGetPlaylistsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioGetPlaylistsResponseToJson(this);
}

/// {@template VKAPI.audio.getPlaylists}
/// Возвращает информацию о плейлистах пользователя.
/// {@endtemplate}
///
/// API: `audio.getPlaylists`.
Future<APIAudioGetPlaylistsResponse> audio_get_playlists(
  String token,
  int userID,
) async {
  var response = await callVkAPI(
    "audio.getPlaylists",
    token,
    {
      "owner_id": userID.toString(),
      "count": 100.toString(),
    },
  );

  return APIAudioGetPlaylistsResponse.fromJson(response.data);
}
