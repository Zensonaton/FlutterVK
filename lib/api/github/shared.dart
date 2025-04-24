import "package:json_annotation/json_annotation.dart";

import "../../utils.dart";

part "shared.g.dart";

/// Класс, олицетворяющий Asset для Github Release.
@JsonSerializable()
class ReleaseAsset {
  /// Название файла.
  final String name;

  /// Размер файла в байтах.
  final int size;

  /// Время загрузки данного файла.
  @JsonKey(name: "created_at", fromJson: datetimeFromString)
  final DateTime? createdAt;

  /// Время обновления данного файла, если хоть раз таковое было.
  @JsonKey(name: "updated_at", fromJson: datetimeFromString)
  final DateTime? updatedAt;

  /// Url для загрузки данного файла.
  @JsonKey(name: "browser_download_url")
  final String browserDownloadUrl;

  @override
  String toString() => "Release asset $name, $size bytes";

  ReleaseAsset({
    required this.name,
    required this.size,
    this.createdAt,
    this.updatedAt,
    required this.browserDownloadUrl,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) =>
      _$ReleaseAssetFromJson(json);
}

/// Класс, олицетворяющий Github Release.
@JsonSerializable()
class Release {
  /// Url на данный Release, который может быть открыт пользователем в браузере.
  @JsonKey(name: "html_url")
  final String htmlUrl;

  /// Текстовое описание Release.
  final String body;

  /// ID данного Release.
  final int id;

  /// Название тэга данного Release.
  @JsonKey(name: "tag_name")
  final String tagName;

  /// Указывает, является ли данный Release pre-release'ом.
  final bool prerelease;

  /// Время создания Release в UTC.
  @JsonKey(name: "created_at", fromJson: datetimeFromString)
  final DateTime? createdAt;

  /// Время публикации Release в UTC.
  @JsonKey(name: "published_at", fromJson: datetimeFromString)
  final DateTime? publishedAt;

  /// Файлы, находящиеся в данном Release.
  final List<ReleaseAsset> assets;

  @override
  String toString() => "Release $tagName";

  Release({
    required this.htmlUrl,
    required this.body,
    required this.id,
    required this.tagName,
    required this.prerelease,
    this.createdAt,
    this.publishedAt,
    required this.assets,
  });

  factory Release.fromJson(Map<String, dynamic> json) =>
      _$ReleaseFromJson(json);
}
