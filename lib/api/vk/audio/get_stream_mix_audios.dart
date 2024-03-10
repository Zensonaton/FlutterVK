// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "get_stream_mix_audios.g.dart";

/// Ответ для метода [audio_get_stream_mix_audios].
@JsonSerializable()
class APIAudioGetStreamMixAudiosResponse {
  /// Список из треков.
  final List<Audio>? response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioGetStreamMixAudiosResponse({
    required this.response,
    required this.error,
  });

  factory APIAudioGetStreamMixAudiosResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$APIAudioGetStreamMixAudiosResponseFromJson(json);
  Map<String, dynamic> toJson() =>
      _$APIAudioGetStreamMixAudiosResponseToJson(this);
}

/// Возвращает список треков для аудио микса (VK Mix).
///
/// API: `audio.getStreamMixAudios`.
Future<APIAudioGetStreamMixAudiosResponse> audio_get_stream_mix_audios(
  String token, {
  String mixID = "common",
  int count = 10,
}) async {
  var response = await vkAPIcall(
    "audio.getStreamMixAudios",
    token,
    {
      "mix_id": mixID,
      "count": count.toString(),
    },
  );

  return APIAudioGetStreamMixAudiosResponse.fromJson(jsonDecode(response.body));
}
