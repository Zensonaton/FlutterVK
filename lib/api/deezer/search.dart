// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";
import "package:string_similarity/string_similarity.dart";

import "../../main.dart";
import "shared.dart";

part "search.g.dart";

/// Количество секунд, на которое может отличаться длительность трека от запрошенной, чтобы считать трек подходящим.
const int deezerSearchDurationTolerance = 2;

/// Класс, олицетворяющий трек, возвращённый API Deezer.
@JsonSerializable()
class DeezerAPISearchResponse {
  /// Результаты поиска.
  final List<DeezerTrack> data;

  /// Общее количество результатов поиска.
  final int total;

  DeezerAPISearchResponse({
    required this.data,
    required this.total,
  });

  factory DeezerAPISearchResponse.fromJson(Map<String, dynamic> json) =>
      _$DeezerAPISearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DeezerAPISearchResponseToJson(this);
}

/// Используя API Deezer, делает поиск по передаваемому [query].
Future<DeezerAPISearchResponse> deezer_search_query(String query) async {
  var response = await dio.get(
    "https://api.deezer.com/search/track",
    queryParameters: {
      "q": query,
      "order": "RANKING",
    },
  );

  return DeezerAPISearchResponse.fromJson(response.data);
}

/// Используя API Deezer, делает поиск по передаваемому [artist] и [title] трека.
Future<DeezerAPISearchResponse> deezer_search(
  String artist,
  String title, {
  String? album,
  int? duration,
}) async {
  String escapedArtist = artist.replaceAll('"', '\\"');
  String escapedTitle = title.replaceAll('"', '\\"');

  String queryString = "artist:\"$escapedArtist\" track:\"$escapedTitle\"";

  if (album != null && album.isNotEmpty) {
    String escapedAlbum = album.replaceAll("\"", "\\\"");
    queryString += " album:\"$escapedAlbum\"";
  }
  if (duration != null && duration > 0) {
    queryString +=
        " dur_min:${duration - deezerSearchDurationTolerance} dur_max:${duration + deezerSearchDurationTolerance}";
  }

  var response = await dio.get(
    "https://api.deezer.com/search/track",
    queryParameters: {
      "q": queryString,
      "order": "RANKING",
    },
  );

  return DeezerAPISearchResponse.fromJson(response.data);
}

/// Используя API Deezer, выполняет поиск по передаваемым [artist] и [title] трека, после чего возвращает список объектов [DeezerTrack], отсортированных по схожести с запросом.
Future<List<DeezerTrack>> deezer_search_sorted(
  String artist,
  String title, {
  String? subtitle,
  int? duration,
  String? album,
}) async {
  final DeezerAPISearchResponse response = await deezer_search(
    artist,
    title,
    album: album,
    duration: duration,
  );
  List<DeezerTrack> tracks = response.data;

  double calculateSimilarity(DeezerTrack track) {
    double score = 0;

    score += track.artist.name.similarityTo(artist) * 3;
    score += track.title.similarityTo(title) * 3;
    if (subtitle != null) {
      if (track.subtitle != null) {
        score += track.subtitle!.similarityTo(subtitle) * 2;
      } else {
        score -= 1;
      }
    }
    if (duration != null) {
      score *= 1 - (track.duration - duration).abs() / duration;
    }
    if (album != null) {
      score += track.album.title.similarityTo(album) * 2;
    }

    return score;
  }

  tracks.sort((a, b) {
    double scoreA = calculateSimilarity(a);
    double scoreB = calculateSimilarity(b);

    return scoreB.compareTo(scoreA);
  });

  return tracks;
}
