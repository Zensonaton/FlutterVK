// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReleaseAsset _$ReleaseAssetFromJson(Map<String, dynamic> json) => ReleaseAsset(
      json['name'] as String,
      json['size'] as int,
      datetimeFromString(json['created_at'] as String?),
      datetimeFromString(json['updated_at'] as String?),
      json['browser_download_url'] as String,
    );

Map<String, dynamic> _$ReleaseAssetToJson(ReleaseAsset instance) =>
    <String, dynamic>{
      'name': instance.name,
      'size': instance.size,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'browser_download_url': instance.browserDownloadUrl,
    };

Release _$ReleaseFromJson(Map<String, dynamic> json) => Release(
      json['html_url'] as String,
      json['body'] as String,
      json['id'] as int,
      json['tag_name'] as String,
      json['prerelease'] as bool,
      datetimeFromString(json['created_at'] as String?),
      datetimeFromString(json['published_at'] as String?),
      (json['assets'] as List<dynamic>)
          .map((e) => ReleaseAsset.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReleaseToJson(Release instance) => <String, dynamic>{
      'html_url': instance.htmlUrl,
      'body': instance.body,
      'id': instance.id,
      'tag_name': instance.tagName,
      'prerelease': instance.prerelease,
      'created_at': instance.createdAt?.toIso8601String(),
      'published_at': instance.publishedAt?.toIso8601String(),
      'assets': instance.assets,
    };
