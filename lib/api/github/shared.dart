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
  @JsonKey(
    name: "created_at",
    fromJson: datetimeFromString,
  )
  final DateTime? createdAt;

  /// Время обновления данного файла, если хоть раз таковое было.
  @JsonKey(
    name: "updated_at",
    fromJson: datetimeFromString,
  )
  final DateTime? updatedAt;

  /// Url для загрузки данного файла.
  @JsonKey(name: "browser_download_url")
  final String browserDownloadUrl;

  ReleaseAsset(
    this.name,
    this.size,
    this.createdAt,
    this.updatedAt,
    this.browserDownloadUrl,
  );

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) =>
      _$ReleaseAssetFromJson(json);
  Map<String, dynamic> toJson() => _$ReleaseAssetToJson(this);
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

  /// Время создания Release.
  @JsonKey(
    name: "created_at",
    fromJson: datetimeFromString,
  )
  final DateTime? createdAt;

  /// Время публикации Release.
  @JsonKey(
    name: "published_at",
    fromJson: datetimeFromString,
  )
  final DateTime? publishedAt;

  /// Файлы, находящиеся в данном Release.
  final List<ReleaseAsset> assets;

  Release(
    this.htmlUrl,
    this.body,
    this.id,
    this.tagName,
    this.prerelease,
    this.createdAt,
    this.publishedAt,
    this.assets,
  );

  factory Release.fromJson(Map<String, dynamic> json) =>
      _$ReleaseFromJson(json);
  Map<String, dynamic> toJson() => _$ReleaseToJson(this);
}
