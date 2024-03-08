// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "shared.dart";

part "get_lyrics.g.dart";

/// Класс, олицетворяющий трек, возвращённый API Deezer.
@JsonSerializable()
class SpotifyAPIGetLyricsResponse {
  /// Информация по тексту песни.
  final SpotifyLyrics lyrics;

  SpotifyAPIGetLyricsResponse({
    required this.lyrics,
  });

  factory SpotifyAPIGetLyricsResponse.fromJson(Map<String, dynamic> json) =>
      _$SpotifyAPIGetLyricsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SpotifyAPIGetLyricsResponseToJson(this);
}

/// Возвращает текст песни у трека Spotify по передаваемому ID трека.
Future<SpotifyAPIGetLyricsResponse?> spotify_get_lyrics(
  String accessToken,
  String id,
) async {
  var response = await apiGet(
    "https://spclient.wg.spotify.com/color-lyrics/v2/track/$id?format=json&vocalRemoval=false&market=from_token",
    moreHeaders: {
      "App-Platform": "WebPlayer",
      "Authorization": "Bearer $accessToken",
    },
  );

  if (response.statusCode == 404) return null;

  return SpotifyAPIGetLyricsResponse.fromJson(jsonDecode(response.body));
}
