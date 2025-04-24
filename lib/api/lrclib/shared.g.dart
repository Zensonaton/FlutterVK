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
