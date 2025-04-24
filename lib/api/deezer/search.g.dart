// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeezerAPISearchResponse _$DeezerAPISearchResponseFromJson(
        Map<String, dynamic> json) =>
    DeezerAPISearchResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => DeezerTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );
