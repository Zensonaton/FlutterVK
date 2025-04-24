// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReleaseAsset _$ReleaseAssetFromJson(Map<String, dynamic> json) => ReleaseAsset(
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
      createdAt: datetimeFromString(json['created_at'] as String?),
      updatedAt: datetimeFromString(json['updated_at'] as String?),
      browserDownloadUrl: json['browser_download_url'] as String,
    );

Release _$ReleaseFromJson(Map<String, dynamic> json) => Release(
      htmlUrl: json['html_url'] as String,
      body: json['body'] as String,
      id: (json['id'] as num).toInt(),
      tagName: json['tag_name'] as String,
      prerelease: json['prerelease'] as bool,
      createdAt: datetimeFromString(json['created_at'] as String?),
      publishedAt: datetimeFromString(json['published_at'] as String?),
      assets: (json['assets'] as List<dynamic>)
          .map((e) => ReleaseAsset.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
