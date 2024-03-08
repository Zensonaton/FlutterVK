// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";

part "search.g.dart";

@JsonSerializable()
class SpotifyTrack {
  /// Длительность трека в миллисекундах.
  @JsonKey(name: "duration_ms")
  final int durationMS;

  /// Название трека.
  final String name;

  /// Указывает, что данный трек является Explicit.
  final bool explicit;

  /// ID трека.
  final String id;

  SpotifyTrack({
    required this.durationMS,
    required this.name,
    required this.explicit,
    required this.id,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) =>
      _$SpotifyTrackFromJson(json);
  Map<String, dynamic> toJson() => _$SpotifyTrackToJson(this);
}

@JsonSerializable()
class Tracks {
  /// URL, вызывающий этот API-запрос.
  final String href;

  /// Результаты поиска.
  final List<SpotifyTrack> items;

  Tracks({
    required this.href,
    required this.items,
  });

  factory Tracks.fromJson(Map<String, dynamic> json) => _$TracksFromJson(json);
  Map<String, dynamic> toJson() => _$TracksToJson(this);
}

/// Класс, олицетворяющий трек, возвращённый API Deezer.
@JsonSerializable()
class SpotifyAPISearchResponse {
  /// Треки результатов поиска.
  final Tracks tracks;

  SpotifyAPISearchResponse({
    required this.tracks,
  });

  factory SpotifyAPISearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SpotifyAPISearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SpotifyAPISearchResponseToJson(this);
}

/// Выполняет поиск трека при помощи API Spotify.
Future<SpotifyAPISearchResponse> spotify_search(
  String accessToken,
  String artist,
  String title, {
  int limit = 3,
}) async {
  final String artistAndTitle = Uri.encodeComponent("$artist $title");

  var response = await apiGet(
    "https://api.spotify.com/v1/search?q=$artistAndTitle&type=track&limit=$limit",
    moreHeaders: {
      "Authorization": "Bearer $accessToken",
    },
  );

  return SpotifyAPISearchResponse.fromJson(jsonDecode(response.body));
}
