// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:dio/dio.dart";

import "../../../main.dart";
import "../../../utils.dart";
import "../shared.dart";

/// {@template VKAPI.execute.massGetAlbums}
/// Массово извлекает информацию по альбомам (и, соответственно, изображениям) треков.
///
/// Передавая [mediaKeys], данный список будет автоматически разделён на группы по 200 элементов максимум, что бы избежать лимита API ВКонтакте.
/// {@endtemplate}
///
/// Для данного метода требуется токен от VK Admin.
Future<List<Audio>> execute_mass_get_albums(List<String> mediaKeys) async {
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

  var response = await vkDio.post(
    "execute",
    data: {
      "code": minimizeJS(codeToExecute),
    },
    options: Options(
      extra: {
        "useSecondary": true,
      },
    ),
  );

  return response.data
      .map<Audio>(
        (item) => Audio.fromJson(item),
      )
      .toList();
}
