// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeezerArtist _$DeezerArtistFromJson(Map<String, dynamic> json) => DeezerArtist(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$DeezerArtistToJson(DeezerArtist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

DeezerAlbum _$DeezerAlbumFromJson(Map<String, dynamic> json) => DeezerAlbum(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      coverSmall: json['cover_small'] as String?,
      cover: json['cover'] as String?,
      coverMedium: json['cover_medium'] as String?,
      coverBig: json['cover_big'] as String?,
      coverXL: json['cover_xl'] as String?,
    );

Map<String, dynamic> _$DeezerAlbumToJson(DeezerAlbum instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'cover_small': instance.coverSmall,
      'cover': instance.cover,
      'cover_medium': instance.coverMedium,
      'cover_big': instance.coverBig,
      'cover_xl': instance.coverXL,
    };

DeezerTrack _$DeezerTrackFromJson(Map<String, dynamic> json) => DeezerTrack(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      subtitle: emptyStringAsNull(json['title_version'] as String?),
      duration: (json['duration'] as num).toInt(),
      artist: DeezerArtist.fromJson(json['artist'] as Map<String, dynamic>),
      album: DeezerAlbum.fromJson(json['album'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DeezerTrackToJson(DeezerTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'title_version': instance.subtitle,
      'duration': instance.duration,
      'artist': instance.artist.toJson(),
      'album': instance.album.toJson(),
    };
