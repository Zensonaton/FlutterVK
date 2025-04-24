import "package:dio/dio.dart";
import "package:json_annotation/json_annotation.dart";

import "../vk/audio/get_lyrics.dart";

part "shared.g.dart";

/// Класс, олицетворяющий трек с сервиса LRCLIB.
@JsonSerializable()
class LRCLIBTrack {
  /// ID трека, уникальный для данного сервиса.
  final int id;

  /// Название трека.
  @JsonKey(name: "trackName")
  final String title;

  /// Исполнитель трека.
  @JsonKey(name: "artistName")
  final String artist;

  /// Название альбома, в котором содержится трек.
  @JsonKey(name: "albumName")
  final String album;

  /// Длительность трека в секундах.
  final int duration;

  /// Инструментальная версия трека?
  final bool instrumental;

  /// Текст трека.
  ///
  /// Может быть null, если [instrumental] правдив.
  final String? plainLyrics;

  /// Текст трека в формате LRC.
  ///
  /// Может быть null, если [instrumental] правдив.
  final String? syncedLyrics;

  /// Возвращает копию данного класса в виде объекта [Lyrics].
  Lyrics? get asLyrics => Lyrics.fromLRCLIBTrack(this);

  LRCLIBTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.instrumental,
    required this.plainLyrics,
    required this.syncedLyrics,
  });

  factory LRCLIBTrack.fromJson(Map<String, dynamic> json) =>
      _$LRCLIBTrackFromJson(json);
}

/// Класс, расширяющий [DioException], олицетворяющий ошибку API LRCLib.
class LRCLIBException extends DioException {
  /// Цифровой код ошибки.
  int? code;

  /// Код ошибки.
  String? name;

  @override
  String toString() => "LRCLib error $name: $message";

  LRCLIBException({
    this.code,
    this.name,
    super.message,
    required super.requestOptions,
  });
}
