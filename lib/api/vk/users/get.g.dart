// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIUsersGetResponse _$APIUsersGetResponseFromJson(Map<String, dynamic> json) =>
    APIUsersGetResponse(
      response: (json['response'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] == null
          ? null
          : APIError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APIUsersGetResponseToJson(
        APIUsersGetResponse instance) =>
    <String, dynamic>{
      'response': instance.response,
      'error': instance.error,
    };
