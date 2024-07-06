// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioEditResponse _$APIAudioEditResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioEditResponse(
      (json['response'] as num?)?.toInt(),
      json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioEditResponseToJson(
        APIAudioEditResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
