// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioAddResponse _$APIAudioAddResponseFromJson(Map<String, dynamic> json) =>
    APIAudioAddResponse(
      json['response'] as int?,
      json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioAddResponseToJson(
        APIAudioAddResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
