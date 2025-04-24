// ignore_for_file: non_constant_identifier_names

import "package:dio/dio.dart";
import "package:json_annotation/json_annotation.dart";

import "../../../main.dart";

part "get_audio_search.g.dart";

/// Возвращает фейковые данные для этого метода.
Map<String, dynamic> _getFakeData() {
  final List<String> suggestions = [
    "nick leng",
    "daughter",
    "missio",
    "half alive",
    "wolf alice",
    "tamer",
    "twenty one pilots",
    "монеточка",
    "glass animals",
    "joywave",
  ];

  return APICatalogGetAudioSearchResponse(
    suggestions: [
      for (String suggestion in suggestions) Suggestion(title: suggestion),
    ],
  ).toJson();
}

/// Отдельный предложенный запрос поиска для [APICatalogGetAudioSearchResponse].
@JsonSerializable()
class Suggestion {
  /// ID предложенного запроса.
  final String? id;

  /// Текст предложенного запроса.
  final String title;

  final String? subtitle;
  final String? context;

  Suggestion({
    this.id,
    required this.title,
    this.subtitle,
    this.context,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) =>
      _$SuggestionFromJson(json);
}

/// Ответ для метода [catalog_get_audio_search].
@JsonSerializable(createToJson: true)
class APICatalogGetAudioSearchResponse {
  /// Список из предлагаемых (частых) запросов.
  final List<Suggestion> suggestions;

  APICatalogGetAudioSearchResponse({
    required this.suggestions,
  });

  factory APICatalogGetAudioSearchResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$APICatalogGetAudioSearchResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$APICatalogGetAudioSearchResponseToJson(this);
}

/// {@template VKAPI.catalog.getAudioSearch}
/// Возвращает информацию по частым запросам поиска аудиозаписей.
/// {@endtemplate}
///
/// API: `catalog.getAudioSearch`.
Future<APICatalogGetAudioSearchResponse> catalog_get_audio_search() async {
  var response = await vkDio.post(
    "catalog.getAudioSearch",
    data: {
      "need_blocks": "1",

      // Demo response
      "_demo_": _getFakeData(),
    },
    options: Options(
      extra: {
        "useSecondary": true,
      },
    ),
  );

  return APICatalogGetAudioSearchResponse.fromJson(response.data);
}
