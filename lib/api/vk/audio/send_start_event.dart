// ignore_for_file: non_constant_identifier_names

import "../../../main.dart";

/// {@template VKAPI.audio.sendStartEvent}
/// Информирует ВКонтакте о том, что передавемый ID трека ([ExtendedAudio.mediaKey]) сейчас прослушивается.
///
/// Благодаря этому методу, рекомендации ВКонтакте перестают рекомендовать этот трек снова и снова.
/// {@endtemplate}
///
/// API: `audio.sendStartEvent`.
Future<dynamic> audio_send_start_event(String mediaKey) async {
  var response = await vkDio.post(
    "audio.sendStartEvent",
    data: {
      "uuid": "abcdef:abcdef", // Понятия не имею что это за параша.
      "audio_id": mediaKey,
    },
  );

  return response.data;
}
