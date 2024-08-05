// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../../../main.dart";
import "../shared.dart";

part "search.g.dart";

/// Ответ для метода [audio_search].
@JsonSerializable()
class APIAudioSearchResponse {
  /// Общее количество треков, которое было найдено при помощи поиска.
  ///
  /// Данное количество не всегда совпадает с значением [items].
  final int count;

  /// Информация о треках.
  final List<Audio> items;

  APIAudioSearchResponse({
    required this.count,
    required this.items,
  });

  factory APIAudioSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioSearchResponseToJson(this);
}

/// {@template VKAPI.audio.search}
/// Ищет треки во ВКонтакте по их названию.
/// {@endtemplate}
///
/// API: `audio.search`.
Future<APIAudioSearchResponse> audio_search(
  String query, {
  bool autoComplete = true,
  int count = 50,
  int offset = 0,
}) async {
  var response = await vkDio.post(
    "audio.search",
    data: {
      "q": query,
      "auto_complete": autoComplete ? "1" : "0",
      "count": count,
      "offset": offset,
    },
  );

  return APIAudioSearchResponse.fromJson(response.data);
}
