// ignore_for_file: non_constant_identifier_names

import "package:json_annotation/json_annotation.dart";

import "../../main.dart";

part "search_catalog.g.dart";

@JsonSerializable()
class SongData {
  /// ID трека.
  final String id;

  /// Атрибуты трека.
  final SongAttributes attributes;

  static List<AlbumData> _albumsFromJson(Map<String, dynamic> json) {
    return (json["albums"]?["data"] as List<dynamic>?)
            ?.map(
              (album) => AlbumData.fromJson(album as Map<String, dynamic>),
            )
            .toList()
            .cast<AlbumData>() ??
        [];
  }

  //// Альбомы трека.
  @JsonKey(name: "relationships", fromJson: _albumsFromJson)
  final List<AlbumData> albums;

  SongData({
    required this.id,
    required this.attributes,
    required this.albums,
  });

  factory SongData.fromJson(Map<String, dynamic> json) =>
      _$SongDataFromJson(json);

  Map<String, dynamic> toJson() => _$SongDataToJson(this);
}

@JsonSerializable()
class SongAttributes {
  /// Название трека.
  final String name;

  /// Имя исполнителя.
  @JsonKey(name: "artistName")
  final String artist;

  /// Альбом трека.
  @JsonKey(name: "albumName")
  final String album;

  /// Имя композитора.
  @JsonKey(name: "composerName")
  final String? composer;

  /// Список названий жанров.
  final List<String> genreNames;

  /// Длительность трека.
  @JsonKey(name: "durationInMillis")
  final int duration;

  /// Информация об обложке.
  final Artwork artwork;

  static List<String> _previewsFromJson(List<dynamic> json) {
    return json
        .map(
          (preview) => preview["url"] as String,
        )
        .toList()
        .cast<String>();
  }

  /// Список ссылок на превью трека.
  @JsonKey(name: "previews", fromJson: _previewsFromJson)
  final List<String> previews;

  SongAttributes({
    required this.name,
    required this.artist,
    required this.album,
    required this.composer,
    required this.genreNames,
    required this.duration,
    required this.artwork,
    required this.previews,
  });

  factory SongAttributes.fromJson(Map<String, dynamic> json) =>
      _$SongAttributesFromJson(json);

  Map<String, dynamic> toJson() => _$SongAttributesToJson(this);
}

@JsonSerializable()
class Artwork {
  /// Ширина обложки.
  final int width;

  /// Высота обложки.
  final int height;

  /// URL обложки вида `https://....rgb.jpg/{w}x{h}bb.jpg`.
  final String url;

  Artwork({
    required this.width,
    required this.height,
    required this.url,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) =>
      _$ArtworkFromJson(json);

  Map<String, dynamic> toJson() => _$ArtworkToJson(this);
}

@JsonSerializable()
class AlbumData {
  /// ID альбома.
  final String id;

  static EditorialVideo? _editorialVideoFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    if (json["editorialVideo"] == null) return null;

    return EditorialVideo.fromJson(
      json["editorialVideo"] as Map<String, dynamic>,
    );
  }

  /// Анимированная обложка альбома.
  @JsonKey(name: "attributes", fromJson: _editorialVideoFromJson)
  final EditorialVideo? editorialVideo;

  AlbumData({
    required this.id,
    this.editorialVideo,
  });

  factory AlbumData.fromJson(Map<String, dynamic> json) =>
      _$AlbumDataFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumDataToJson(this);
}

@JsonSerializable()
class EditorialVideo {
  /// Анимированная обложка альбома в формате 1:1.
  final MotionVideo? motionSquareVideo1x1;

  /// Анимированная обложка альбома в формате 9:16.
  final MotionVideo? motionDetailTall;

  /// Анимированная обложка альбома в формате 1:1.
  final MotionVideo? motionDetailSquare;

  EditorialVideo({
    this.motionSquareVideo1x1,
    this.motionDetailTall,
    this.motionDetailSquare,
  });

  factory EditorialVideo.fromJson(Map<String, dynamic> json) =>
      _$EditorialVideoFromJson(json);

  Map<String, dynamic> toJson() => _$EditorialVideoToJson(this);
}

@JsonSerializable()
class MotionVideo {
  /// Превью анимированной обложки альбома.
  final PreviewFrame previewFrame;

  /// Ссылка на .m3u8-файл с анимированной обложкой альбома.
  final String video;

  MotionVideo({
    required this.previewFrame,
    required this.video,
  });

  factory MotionVideo.fromJson(Map<String, dynamic> json) =>
      _$MotionVideoFromJson(json);

  Map<String, dynamic> toJson() => _$MotionVideoToJson(this);
}

@JsonSerializable()
class PreviewFrame {
  /// Ширина превью.
  final int width;

  /// Высота превью.
  final int height;

  /// URL превью вида `https://....rgb.jpg/{w}x{h}bb.jpg`.
  final String url;

  PreviewFrame({
    required this.width,
    required this.height,
    required this.url,
  });

  factory PreviewFrame.fromJson(Map<String, dynamic> json) =>
      _$PreviewFrameFromJson(json);

  Map<String, dynamic> toJson() => _$PreviewFrameToJson(this);
}

/// Возвращает информацию по треку из Apple Music по переданному названию [title].
Future<SongData> am_search_catalog(String title) async {
  var response = await appleMusicDio.get(
    "catalog/us/search",
    queryParameters: {
      "term": title,
      "l": "en-US",
      "limit": 1,
      "platform": "web",
      "types": "songs",
      "fields[albums]": "editorialVideo",
      "include[songs]": "albums",
    },
  );

  final data = response.data?["results"]?["songs"]?["data"]?[0];

  return SongData.fromJson(data);
}
