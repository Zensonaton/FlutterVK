// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SongData _$SongDataFromJson(Map<String, dynamic> json) => SongData(
      id: json['id'] as String,
      attributes:
          SongAttributes.fromJson(json['attributes'] as Map<String, dynamic>),
      albums: SongData._albumsFromJson(
          json['relationships'] as Map<String, dynamic>),
    );

SongAttributes _$SongAttributesFromJson(Map<String, dynamic> json) =>
    SongAttributes(
      name: json['name'] as String,
      artist: json['artistName'] as String,
      album: json['albumName'] as String,
      composer: json['composerName'] as String?,
      genreNames: (json['genreNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      duration: (json['durationInMillis'] as num).toInt(),
      artwork: Artwork.fromJson(json['artwork'] as Map<String, dynamic>),
      previews: SongAttributes._previewsFromJson(json['previews'] as List),
    );

Artwork _$ArtworkFromJson(Map<String, dynamic> json) => Artwork(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      url: json['url'] as String,
    );

AlbumData _$AlbumDataFromJson(Map<String, dynamic> json) => AlbumData(
      id: json['id'] as String,
      editorialVideo: AlbumData._editorialVideoFromJson(
          json['attributes'] as Map<String, dynamic>?),
    );

EditorialVideo _$EditorialVideoFromJson(Map<String, dynamic> json) =>
    EditorialVideo(
      motionSquareVideo1x1: json['motionSquareVideo1x1'] == null
          ? null
          : MotionVideo.fromJson(
              json['motionSquareVideo1x1'] as Map<String, dynamic>),
      motionDetailTall: json['motionDetailTall'] == null
          ? null
          : MotionVideo.fromJson(
              json['motionDetailTall'] as Map<String, dynamic>),
      motionDetailSquare: json['motionDetailSquare'] == null
          ? null
          : MotionVideo.fromJson(
              json['motionDetailSquare'] as Map<String, dynamic>),
    );

MotionVideo _$MotionVideoFromJson(Map<String, dynamic> json) => MotionVideo(
      previewFrame:
          PreviewFrame.fromJson(json['previewFrame'] as Map<String, dynamic>),
      video: json['video'] as String,
    );

PreviewFrame _$PreviewFrameFromJson(Map<String, dynamic> json) => PreviewFrame(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      url: json['url'] as String,
    );
