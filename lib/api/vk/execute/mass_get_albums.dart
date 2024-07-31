// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:flutter/foundation.dart";
import "package:json_annotation/json_annotation.dart";

import "../../../utils.dart";
import "../api.dart";
import "../shared.dart";

part "mass_get_albums.g.dart";

/// Ответ для метода [execute_mass_get_albums].
@JsonSerializable()
class APIMassAudioAlbumsResponse {
  /// Объект ответа.
  final List<Audio>? response;

  /// Объект ошибки.
  final APIError? error;

  APIMassAudioAlbumsResponse({
    this.response,
    this.error,
  });

  factory APIMassAudioAlbumsResponse.fromJson(Map<String, dynamic> json) =>
      _$APIMassAudioAlbumsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIMassAudioAlbumsResponseToJson(this);
}

/// {@template VKAPI.execute.massGetAlbums}
/// Массово извлекает информацию по альбомам (и, соответственно, изображениям) треков.
///
/// Передавая [mediaKeys], данный список будет автоматически разделён на группы по 200 элементов максимум, что бы избежать лимита API ВКонтакте.
/// {@endtemplate}
///
/// Для данного метода требуется токен от VK Admin.
Future<APIMassAudioAlbumsResponse> execute_mass_get_albums(
  String token,
  List<String> mediaKeys,
) async {
  final List<String> groupedMediaKeys = List.generate(
    (mediaKeys.length / 200).ceil(),
    (i) => mediaKeys
        .sublist(
          i * 200,
          (i * 200 + 200).clamp(0, mediaKeys.length),
        )
        .join(","),
  );

  final String codeToExecute = """
var audioMediaIDs = ${jsonEncode(groupedMediaKeys)};

var audioAlbums = [];

var mediaIndex = 0;
while (mediaIndex < audioMediaIDs.length) {
  audioAlbums = audioAlbums + API.audio.getById({'audios': audioMediaIDs[mediaIndex]});

	mediaIndex = mediaIndex + 1;
};

return audioAlbums;""";

  var response = await callVkAPI(
    "execute",
    token,
    {
      "code": minimizeJS(codeToExecute),
    },
  );

  return await compute(
    (message) => APIMassAudioAlbumsResponse.fromJson(message),
    response.data,
  );
}
