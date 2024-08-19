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
  Map<String, dynamic> toJson() => _$LRCLIBTrackToJson(this);
}

/// Объект ошибки API ВКонтакте.
///
/// Не следует путать с [VKAPIError].
@JsonSerializable()
class LRCLIBError {
  /// Код ошибки.
  final int code;

  /// Название ошибки.
  final String name;

  /// Сообщение об ошибке.
  final String message;

  @override
  String toString() => "LRCLIB Error $name: $message";

  LRCLIBError({
    required this.code,
    required this.name,
    required this.message,
  });

  factory LRCLIBError.fromJson(Map<String, dynamic> json) =>
      _$LRCLIBErrorFromJson(json);
  Map<String, dynamic> toJson() => _$LRCLIBErrorToJson(this);
}
