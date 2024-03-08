import "package:json_annotation/json_annotation.dart";

part "shared.g.dart";

/// Класс, олицетворяющий ошибку API Spotify.
@JsonSerializable()
class SpotifyAPIError {
  /// Код ошибки.
  final int code;

  /// Сообщение об ошибке.
  final String message;

  SpotifyAPIError({
    required this.code,
    required this.message,
  });

  factory SpotifyAPIError.fromJson(Map<String, dynamic> json) =>
      _$SpotifyAPIErrorFromJson(json);
  Map<String, dynamic> toJson() => _$SpotifyAPIErrorToJson(this);
}

/// Класс, олицетворяющий отдельную строчку текста песни, полученного с API Spotify.
@JsonSerializable()
class SpotifyLyricLine {
  /// Время начала данной строчки в миллисекундах.
  @JsonKey(name: "startTimeMs", fromJson: int.parse)
  final int startTimeMS;

  /// Время конца данной строчки в миллисекундах. Чаще всего это поле равно значению `0`, что значит, что данная строчка не заканчивается.
  @JsonKey(name: "endTimeMs", fromJson: int.parse)
  final int endTimeMS;

  /// Содержимое данной строчки. В редких случаях, эта строчка может быть равна значению `♪`, а иногда она бывает пустой.
  final String words;

  SpotifyLyricLine({
    required this.startTimeMS,
    required this.endTimeMS,
    required this.words,
  });

  factory SpotifyLyricLine.fromJson(Map<String, dynamic> json) =>
      _$SpotifyLyricLineFromJson(json);
  Map<String, dynamic> toJson() => _$SpotifyLyricLineToJson(this);
}

/// Класс, олицетворяющий блок текста песни, полученного с API Spotify.
@JsonSerializable()
class SpotifyLyrics {
  /// Тип синхронизированности текста песни.
  ///
  /// Известные значения:
  /// - `UNSYNCED`: Не синхронизированы по времени.
  /// - `LINE_SYNCED`: Синхронизированы по времени.
  final String syncType;

  /// Строки текста песни.
  final List<SpotifyLyricLine> lines;

  /// Название провайдера данного текста песни.
  final String provider;

  /// ID данного трека в провайдере текста песни.
  @JsonKey(name: "providerLyricsId", fromJson: int.parse)
  final int providerLyricsID;

  /// Язык данного трека.
  final String language;

  SpotifyLyrics({
    required this.syncType,
    required this.lines,
    required this.provider,
    required this.providerLyricsID,
    required this.language,
  });

  factory SpotifyLyrics.fromJson(Map<String, dynamic> json) =>
      _$SpotifyLyricsFromJson(json);
  Map<String, dynamic> toJson() => _$SpotifyLyricsToJson(this);
}
