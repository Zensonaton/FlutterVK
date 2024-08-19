// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LRCLIBTrack _$LRCLIBTrackFromJson(Map<String, dynamic> json) => LRCLIBTrack(
      id: (json['id'] as num).toInt(),
      title: json['trackName'] as String,
      artist: json['artistName'] as String,
      album: json['albumName'] as String,
      duration: (json['duration'] as num).toInt(),
      instrumental: json['instrumental'] as bool,
      plainLyrics: json['plainLyrics'] as String?,
      syncedLyrics: json['syncedLyrics'] as String?,
    );

Map<String, dynamic> _$LRCLIBTrackToJson(LRCLIBTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trackName': instance.title,
      'artistName': instance.artist,
      'albumName': instance.album,
      'duration': instance.duration,
      'instrumental': instance.instrumental,
      'plainLyrics': instance.plainLyrics,
      'syncedLyrics': instance.syncedLyrics,
    };

LRCLIBError _$LRCLIBErrorFromJson(Map<String, dynamic> json) => LRCLIBError(
      code: (json['code'] as num).toInt(),
      name: json['name'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$LRCLIBErrorToJson(LRCLIBError instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'message': instance.message,
    };