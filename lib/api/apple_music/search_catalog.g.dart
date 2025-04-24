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

Map<String, dynamic> _$SongDataToJson(SongData instance) => <String, dynamic>{
      'id': instance.id,
      'attributes': instance.attributes,
      'relationships': instance.albums,
    };

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

Map<String, dynamic> _$SongAttributesToJson(SongAttributes instance) =>
    <String, dynamic>{
      'name': instance.name,
      'artistName': instance.artist,
      'albumName': instance.album,
      'composerName': instance.composer,
      'genreNames': instance.genreNames,
      'durationInMillis': instance.duration,
      'artwork': instance.artwork,
      'previews': instance.previews,
    };

Artwork _$ArtworkFromJson(Map<String, dynamic> json) => Artwork(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      url: json['url'] as String,
    );

Map<String, dynamic> _$ArtworkToJson(Artwork instance) => <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'url': instance.url,
    };

AlbumData _$AlbumDataFromJson(Map<String, dynamic> json) => AlbumData(
      id: json['id'] as String,
      editorialVideo: AlbumData._editorialVideoFromJson(
          json['attributes'] as Map<String, dynamic>?),
    );

Map<String, dynamic> _$AlbumDataToJson(AlbumData instance) => <String, dynamic>{
      'id': instance.id,
      'attributes': instance.editorialVideo,
    };

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

Map<String, dynamic> _$EditorialVideoToJson(EditorialVideo instance) =>
    <String, dynamic>{
      'motionSquareVideo1x1': instance.motionSquareVideo1x1,
      'motionDetailTall': instance.motionDetailTall,
      'motionDetailSquare': instance.motionDetailSquare,
    };

MotionVideo _$MotionVideoFromJson(Map<String, dynamic> json) => MotionVideo(
      previewFrame:
          PreviewFrame.fromJson(json['previewFrame'] as Map<String, dynamic>),
      video: json['video'] as String,
    );

Map<String, dynamic> _$MotionVideoToJson(MotionVideo instance) =>
    <String, dynamic>{
      'previewFrame': instance.previewFrame,
      'video': instance.video,
    };

PreviewFrame _$PreviewFrameFromJson(Map<String, dynamic> json) => PreviewFrame(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      url: json['url'] as String,
    );

Map<String, dynamic> _$PreviewFrameToJson(PreviewFrame instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'url': instance.url,
    };
