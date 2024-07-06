// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIAudioDeleteResponse _$APIAudioDeleteResponseFromJson(
        Map<String, dynamic> json) =>
    APIAudioDeleteResponse(
      json['response'] == null
          ? false
          : boolFromInt((json['response'] as num?)?.toInt()),
      json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIAudioDeleteResponseToJson(
        APIAudioDeleteResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
