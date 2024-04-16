// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "send_start_event.g.dart";

/// Ответ для метода [audio_send_start_event].
@JsonSerializable()
class APIAudioSendStartEventResponse {
  final dynamic response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioSendStartEventResponse({
    this.response,
    this.error,
  });

  factory APIAudioSendStartEventResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioSendStartEventResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioSendStartEventResponseToJson(this);
}

/// Информирует ВКонтакте о том, что передавемый трек сейчас прослушивается. Благодаря этому методу, рекомендации ВКонтакте перестают рекомендовать этот трек снова и снова.
///
/// API: `audio.sendStartEvent`.
Future<APIAudioSendStartEventResponse> audio_send_start_event(
  String token,
  String id,
) async {
  var response = await vkAPIcall(
    "audio.sendStartEvent",
    token,
    {
      "uuid": "abcdef:abcdef", // Понятия не имею что это за параша.
      "audio_id": id,
    },
  );

  return APIAudioSendStartEventResponse.fromJson(jsonDecode(response.body));
}
