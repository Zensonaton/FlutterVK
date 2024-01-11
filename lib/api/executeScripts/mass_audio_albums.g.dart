// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mass_audio_albums.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SmallAudioAlbumData _$SmallAudioAlbumDataFromJson(Map<String, dynamic> json) =>
    SmallAudioAlbumData(
      json['id'] as int,
      json['oID'] as int,
      json['aID'] as int?,
      json['aT'] as String?,
      json['aOID'] as int?,
      json['aAKEY'] as String?,
      json['tW'] as int?,
      json['tH'] as int?,
      json['tP34'] as String?,
      json['tP68'] as String?,
      json['tP135'] as String?,
      json['tP270'] as String?,
      json['tP300'] as String?,
      json['tP600'] as String?,
      json['tP1200'] as String?,
    );

Map<String, dynamic> _$SmallAudioAlbumDataToJson(
        SmallAudioAlbumData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'oID': instance.ownerID,
      'aID': instance.albumID,
      'aT': instance.albumTitle,
      'aOID': instance.albumOwnerID,
      'aAKEY': instance.albumAccessKey,
      'tW': instance.thumbnailWidth,
      'tH': instance.thumbnailHeight,
      'tP34': instance.photo34,
      'tP68': instance.photo68,
      'tP135': instance.photo135,
      'tP270': instance.photo270,
      'tP300': instance.photo300,
      'tP600': instance.photo600,
      'tP1200': instance.photo1200,
    };

APIMassAudioAlbumsResponse _$APIMassAudioAlbumsResponseFromJson(
        Map<String, dynamic> json) =>
    APIMassAudioAlbumsResponse(
      (json['response'] as List<dynamic>?)
          ?.map((e) => Audio.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIMassAudioAlbumsResponseToJson(
        APIMassAudioAlbumsResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
