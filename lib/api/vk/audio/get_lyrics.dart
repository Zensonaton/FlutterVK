// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../../../db/schemas/playlists.dart";
import "../api.dart";
import "../shared.dart";

part "get_lyrics.g.dart";

/// Олицетворение отдельной линии в тексте песни.
@JsonSerializable()
class LyricTimestamp {
  /// Текст данной строки.
  ///
  /// Иногда может отсутствовать, в случае, если [interlude] равен true.
  final String? line;

  /// Указывает, что здесь находится "заполнитель".
  ///
  /// Чаще всего в интерфейсе он отображается символом ноты.
  final bool interlude;

  /// Время начала данной линии в тексте песни в миллисекундах.
  final int? begin;

  /// Время окончания данной линии в тексте песни в миллисекундах.
  final int? end;

  /// Создаёт из передаваемого объекта [DBLyricTimestamp] объект данного класа.
  static LyricTimestamp fromDBLyricTimestamp(DBLyricTimestamp timestamp) =>
      LyricTimestamp(
        line: timestamp.line,
        interlude: timestamp.interlude,
        begin: timestamp.begin,
        end: timestamp.end,
      );

  /// Возвращает копию данного класса в виде объекта [DBLyricTimestamp].
  DBLyricTimestamp get asDBTimestamp =>
      DBLyricTimestamp.fromLyricTimestamp(this);

  @override
  String toString() =>
      "LyricTimestamp \"${interlude ? "** interlude **" : line}\"";

  LyricTimestamp({
    this.line,
    this.interlude = false,
    this.begin,
    this.end,
  });

  factory LyricTimestamp.fromJson(Map<String, dynamic> json) =>
      _$LyricTimestampFromJson(json);
  Map<String, dynamic> toJson() => _$LyricTimestampToJson(this);
}

/// Класс, олицетворяющий информацию по тексту песни из API ВКонтакте.
@JsonSerializable()
class Lyrics {
  /// Язык данного трека.
  ///
  /// Передаётся строка в виде `en`.
  final String? language;

  /// Перечисление всех линий в тексте песни, разделённых по времени.
  ///
  /// Может отсутствовать в случае, если у данного трека нету синхронизированных по времени lyrics'ов.
  final List<LyricTimestamp>? timestamps;

  /// Список всех линий в тексте песни. Может отсутствовать в пользу [timestamps].
  final List<String>? text;

  /// Создаёт из передаваемого объекта [DBLyrics] объект данного класа.
  static Lyrics fromDBLyrics(
    DBLyrics lyrics,
  ) =>
      Lyrics(
        language: lyrics.language,
        timestamps: lyrics.timestamps
            ?.map(
              (timestamp) => timestamp.asLyricTimestamp,
            )
            .toList(),
        text: lyrics.text,
      );

  /// Возвращает копию данного класса в виде объекта [DBLyrics].
  DBLyrics get asDBLyrics => DBLyrics.fromLyrics(this);

  @override
  String toString() =>
      "Lyrics $language with ${timestamps != null ? "${timestamps!.length} sync lyrics" : "text lyrics"}";

  Lyrics({
    this.language,
    this.timestamps,
    this.text,
  });

  factory Lyrics.fromJson(Map<String, dynamic> json) => _$LyricsFromJson(json);
  Map<String, dynamic> toJson() => _$LyricsToJson(this);
}

@JsonSerializable()
class APIAudioGetLyricsRealResponse {
  final String credits;

  /// Перечисление текста песни.
  final Lyrics lyrics;

  /// MD5-строка.
  final String md5;

  APIAudioGetLyricsRealResponse({
    required this.credits,
    required this.lyrics,
    required this.md5,
  });

  factory APIAudioGetLyricsRealResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioGetLyricsRealResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioGetLyricsRealResponseToJson(this);
}

/// Ответ для метода [audio_get_lyrics].
@JsonSerializable()
class APIAudioGetLyricsResponse {
  /// Объект ответа.
  final APIAudioGetLyricsRealResponse? response;

  /// Объект ошибки.
  final APIError? error;

  APIAudioGetLyricsResponse(
    this.response,
    this.error,
  );

  factory APIAudioGetLyricsResponse.fromJson(Map<String, dynamic> json) =>
      _$APIAudioGetLyricsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIAudioGetLyricsResponseToJson(this);
}

/// Возвращает текст песни (lyrics) у трека по его передаваемому ID ([Audio.mediaKey]).
///
/// API: `audio.getLyrics`.
Future<APIAudioGetLyricsResponse> audio_get_lyrics(
  String token,
  String audioID,
) async {
  var response = await vkAPIcall(
    "audio.getLyrics",
    token,
    {
      "audio_id": audioID,
    },
  );

  return APIAudioGetLyricsResponse.fromJson(jsonDecode(response.body));
}
