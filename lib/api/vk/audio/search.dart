// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "search.g.dart";

@JsonSerializable()
class APIAudioSearchRealResponse {
  /// Общее количество треков, которое было найдено при помощи поиска.
  ///
  /// Данное количество не всегда совпадает с значением [items].
  final int count;

  /// Информация о треках.
  final List<Audio> items;

  APIAudioSearchRealResponse({
    required this.count,
    required this.items,
  });

  factory APIAudioSearchRealResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioSearchRealResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioSearchRealResponseToJson(this);
}

/// Ответ для метода [audio_search].
@JsonSerializable()
class APIAudioSearchResponse {
  /// Объект ответа.
  final APIAudioSearchRealResponse? response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioSearchResponse({
    this.response,
    this.error,
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
  String token,
  String query, {
  bool autoComplete = true,
  int count = 50,
  int offset = 0,
}) async {
  var response = await callVkAPI(
    "audio.search",
    token,
    {
      "q": query,
      "auto_complete": autoComplete ? "1" : "0",
      "count": count.toString(),
      "offset": offset.toString(),
    },
  );

  return APIAudioSearchResponse.fromJson(response.data);
}
