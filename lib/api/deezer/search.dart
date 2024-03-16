// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:http/http.dart";
import "package:json_annotation/json_annotation.dart";
import "package:string_similarity/string_similarity.dart";

import "shared.dart";

part "search.g.dart";

/// Процент схожести треков, используемый в [deezer_search_closest].
const simillarityPercentThreshold = 0.4;

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

/// Используя API Deezer, делает поиск по передаваемому [artist] и [title] трека.
Future<DeezerAPISearchResponse> deezer_search(
  String artist,
  String title,
) async {
  var response = await get(
    Uri.parse(
      Uri.encodeFull(
        "https://api.deezer.com/search?q=$artist $title",
      ),
    ),
  );

  return DeezerAPISearchResponse.fromJson(jsonDecode(response.body));
}

/// Используя API Deezer, выполняет поиск по передаваемым [artist] и [title] трека, после чего возвращает список объектов [DeezerTrack], отсортированных по схожести с запросом.
Future<List<DeezerTrack>> deezer_search_sorted(
  String artist,
  String title, {
  String? album,
  int? duration,
}) async {
  final DeezerAPISearchResponse response = await deezer_search(artist, title);

  final String trackA = "$artist$title${album ?? ""}$duration";
  List<DeezerTrack> sortedTracks = [];

  // Проходимся по всем результатам поиска и сортируем их по схожести с запросом.
  for (DeezerTrack track in response.data) {
    final String trackB =
        "${track.artist.name}${track.title}${album != null ? track.album : ""}${track.duration}";

    final double similarity = trackA.similarityTo(trackB);

    if (similarity >= simillarityPercentThreshold) {
      sortedTracks.add(track);
    }
  }

  // Сортируем список треков по убыванию схожести.
  sortedTracks.sort((a, b) {
    final String trackA =
        "${a.artist.name}${a.title}${album != null ? a.album : ""}${a.duration}";
    final String trackB =
        "${b.artist.name}${b.title}${album != null ? b.album : ""}${b.duration}";

    final double similarityA = trackA.similarityTo(trackB);
    final double similarityB = trackB.similarityTo(trackA);

    return similarityB.compareTo(similarityA);
  });

  return sortedTracks;
}

/// Используя API Deezer, выполняет поиск по передаваемым [artist] и [title] трека, после чего пытается найти самое точное совпадение, возвращая объект [DeezerTrack] в случае успеха (если процент схожести больше [simillarityPercentThreshold]).
Future<DeezerTrack?> deezer_search_closest(
  String artist,
  String title, {
  String? album,
  int? duration,
}) async {
  final List<DeezerTrack> response = await deezer_search_sorted(
    artist,
    title,
    album: album,
    duration: duration,
  );

  return response[0];
}
