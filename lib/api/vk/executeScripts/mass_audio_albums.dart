// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:flutter/foundation.dart";
import "package:json_annotation/json_annotation.dart";

import "../execute.dart";
import "../shared.dart";

part "mass_audio_albums.g.dart";

/// Ответ для метода [scripts_massAlbumsGet].
@JsonSerializable()
class APIMassAudioAlbumsResponse {
  /// Объект ответа.
  final List<Audio>? response;

  /// Объект ошибки.
  final APIError? error;

  APIMassAudioAlbumsResponse(
    this.response,
    this.error,
  );

  factory APIMassAudioAlbumsResponse.fromJson(Map<String, dynamic> json) =>
      _$APIMassAudioAlbumsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIMassAudioAlbumsResponseToJson(this);
}

/// Массово извлекает информацию по альбомам (и, соответственно, изображениям) треков.
///
/// Для данного метода требуется токен от VK Admin.
Future<APIMassAudioAlbumsResponse> scripts_massAlbumsGet(
  String token,
  List<String> audioMediaIDs,
) async {
  final String executeCode = """
var audioMediaIDs = ${jsonEncode(audioMediaIDs)};

var audioAlbums = [];

var mediaIndex = 0;
while (mediaIndex < audioMediaIDs.length) {
  audioAlbums = audioAlbums + API.audio.getById({'audios': audioMediaIDs[mediaIndex]});

	mediaIndex = mediaIndex + 1;
};

return audioAlbums;""";

  var response = await VKExecuteAPI.execute(
    token,
    executeCode,
  );

  return await compute(
    (message) => APIMassAudioAlbumsResponse.fromJson(jsonDecode(message)),
    response.body,
  );
}
