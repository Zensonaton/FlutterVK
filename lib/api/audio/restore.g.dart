// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restore.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioRestoreResponse _$APIAudioRestoreResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioRestoreResponse(
      json['response'] == null
          ? null
          : Audio.fromJson(json['response'] as Map<String, dynamic>),
      json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioRestoreResponseToJson(
        APIAudioRestoreResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
