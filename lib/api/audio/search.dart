// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "search.g.dart";

@JsonSerializable()
class APIAudioSearchRealResponse {
  /// Количество треков.
  final int count;

  /// Информация о треках.
  final List<Audio> items;

  APIAudioSearchRealResponse(
    this.count,
    this.items,
  );

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

  APIAudioSearchResponse(
    this.response,
    this.error,
  );

  factory APIAudioSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioSearchResponseToJson(this);
}

/// Ищет треки во ВКонтакте по их названию.
///
/// API: `audio.search`.
Future<APIAudioSearchResponse> audio_search(
  String token,
  String query, {
  bool autoComplete = true,
  int count = 50,
  int offset = 0,
}) async {
  var response = await vkAPIcall(
    "audio.search",
    token,
    {
      "q": query,
      "auto_complete": autoComplete ? "1" : "0",
      "count": count.toString(),
      "offset": offset.toString(),
    },
  );

  return APIAudioSearchResponse.fromJson(jsonDecode(response.body));
}
