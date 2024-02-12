// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "get.g.dart";

@JsonSerializable()
class APIAudioGetRealResponse {
  /// Количество треков.
  final int count;

  /// Информация о треках.
  final List<Audio> items;

  APIAudioGetRealResponse(
    this.count,
    this.items,
  );

  factory APIAudioGetRealResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioGetRealResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioGetRealResponseToJson(this);
}

/// Ответ для метода [audio_get].
@JsonSerializable()
class APIAudioGetResponse {
  /// Объект ответа.
  final APIAudioGetRealResponse? response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioGetResponse(
    this.response,
    this.error,
  );

  factory APIAudioGetResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioGetResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioGetResponseToJson(this);
}

/// Возвращает информацию об аудиофайлах пользователя или сообщества.
///
/// API: `audio.get`.
Future<APIAudioGetResponse> audio_get(
  String token,
  int userID,
) async {
  var response = await vkAPIcall(
    "audio.get",
    token,
    {"owner_id": userID.toString()},
  );

  return APIAudioGetResponse.fromJson(jsonDecode(response.body));
}
