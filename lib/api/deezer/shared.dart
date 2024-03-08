import "package:json_annotation/json_annotation.dart";

part "shared.g.dart";

/// Класс, олицетворяющий исполнителя трека в Deezer.
@JsonSerializable()
class DeezerArtist {
  /// ID исполнителя.
  final int id;

  /// Имя исполнителя.
  final String name;

  @override
  String toString() => "DeezerArtist $id $name";

  DeezerArtist({
    required this.id,
    required this.name,
  });

  factory DeezerArtist.fromJson(Map<String, dynamic> json) =>
      _$DeezerArtistFromJson(json);
  Map<String, dynamic> toJson() => _$DeezerArtistToJson(this);
}

/// Класс, олицетворяющий альбом трека в Deezer.
@JsonSerializable()
class DeezerAlbum {
  /// ID альбома.
  final int id;

  /// Название альбома.
  final String title;

  /// URL на изображение альбома размером `56x56`.
  @JsonKey(name: "cover_small")
  final String? coverSmall;

  /// URL на изображение альбома размера `120x120`.
  final String? cover;

  /// URL на изображение альбома размером `250x250`.
  @JsonKey(name: "cover_medium")
  final String? coverMedium;

  /// URL на изображение альбома размером `500x500`.
  @JsonKey(name: "cover_big")
  final String? coverBig;

  /// URL на изображение альбома размером `1000x1000`.
  @JsonKey(name: "cover_xl")
  final String? coverXL;

  @override
  String toString() => "DeezerAlbum $id $title";

  DeezerAlbum({
    required this.id,
    required this.title,
    required this.coverSmall,
    required this.cover,
    required this.coverMedium,
    required this.coverBig,
    required this.coverXL,
  });

  factory DeezerAlbum.fromJson(Map<String, dynamic> json) =>
      _$DeezerAlbumFromJson(json);
  Map<String, dynamic> toJson() => _$DeezerAlbumToJson(this);
}

/// Класс, олицетворяющий трек, возвращённый API Deezer.
@JsonSerializable()
class DeezerTrack {
  /// ID трека.
  final int id;

  /// Название трека.
  final String title;

  /// Длительность трека в секундах.
  final int duration;

  /// Информация по исполнителю данного трека.
  final DeezerArtist artist;

  /// Информация по альбому данного трека.
  final DeezerAlbum album;

  @override
  String toString() => "DeezerTrack $id $title - ${artist.name}";

  DeezerTrack({
    required this.id,
    required this.title,
    required this.duration,
    required this.artist,
    required this.album,
  });

  factory DeezerTrack.fromJson(Map<String, dynamic> json) =>
      _$DeezerTrackFromJson(json);
  Map<String, dynamic> toJson() => _$DeezerTrackToJson(this);
}
