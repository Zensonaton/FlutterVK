// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../api.dart";
import "../shared.dart";

part "get_audio.g.dart";

/// Класс отдельного рекомендуемого плейлиста из раздела "совпадения по вкусам".
@JsonSerializable()
class SimillarPlaylist {
  /// ID плейлиста.
  final int id;

  /// ID владельца плейлиста.
  @JsonKey(name: "owner_id")
  final int ownerID;

  /// Число от `0.0` до `1.0`, показывающее процент "схожести" плейлиста по вкусу.
  final double percentage;

  /// Перечисление до трёх элементов типа [ExtendedVKAudio.mediaKey].
  final List<String> audios;

  /// Hex-код цвета данного плейлиста.
  final String color;

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  String get mediaKey => "${ownerID}_$id";

  SimillarPlaylist({
    required this.id,
    required this.ownerID,
    required this.percentage,
    required this.audios,
    required this.color,
  });

  factory SimillarPlaylist.fromJson(Map<String, dynamic> json) =>
      _$SimillarPlaylistFromJson(json);
  Map<String, dynamic> toJson() => _$SimillarPlaylistToJson(this);
}

/// Класс действия у блока секции в аудиозаписях.
@JsonSerializable()
class BlockAction {
  /// ID данной секции.
  @JsonKey(name: "section_id")
  final String? sectionID;

  /// Название данной секции.
  final String? title;

  /// Количество элементов.
  @JsonKey(name: "ref_items_count")
  final int? refItemsCount;

  @JsonKey(name: "ref_layout_name")
  final String? refLayoutName;

  /// Тип данных.
  @JsonKey(name: "ref_data_type")
  final String? refDataType;

  BlockAction(
    this.sectionID,
    this.title,
    this.refItemsCount,
    this.refLayoutName,
    this.refDataType,
  );

  factory BlockAction.fromJson(Map<String, dynamic> json) =>
      _$BlockActionFromJson(json);
  Map<String, dynamic> toJson() => _$BlockActionToJson(this);
}

/// Класс блока секции каталога в аудиозаписях.
@JsonSerializable()
class SectionBlock {
  /// ID блока секции.
  final String id;

  /// Название данного блока.
  final String? title;

  /// Тип данного блока.
  ///
  /// Известные значения:
  /// - `none`.
  /// - `music_playlists`: Указывается в блоках с плейлистами.
  /// - `music_recommended_playlists`: Блок с рекомендуемыми плейлистами других пользователей.
  @JsonKey(name: "data_type")
  final String dataType;

  final dynamic layout;

  /// Список действий данного блока.
  final List<BlockAction>? actions;

  /// Список аудио в данном блоке.
  @JsonKey(name: "audios_ids")
  final List<String>? audioIDs;

  /// Список плейлистов в данном блоке.
  @JsonKey(name: "playlists_ids")
  final List<String>? playlistIDs;

  SectionBlock(
    this.id,
    this.title,
    this.dataType,
    this.layout,
    this.actions,
    this.audioIDs,
    this.playlistIDs,
  );

  factory SectionBlock.fromJson(Map<String, dynamic> json) =>
      _$SectionBlockFromJson(json);
  Map<String, dynamic> toJson() => _$SectionBlockToJson(this);
}

/// Класс секции каталога в аудиозаписях.
@JsonSerializable()
class Section {
  /// ID данной секции.
  final String id;

  /// Название данной секции.
  final String title;

  /// URL к указанной секции.
  final String url;

  /// Список блоков.
  final List<SectionBlock>? blocks;

  /// Список действий в данном блоке.
  final List<dynamic>? actions;

  Section(
    this.id,
    this.title,
    this.url,
    this.blocks,
    this.actions,
  );

  factory Section.fromJson(Map<String, dynamic> json) =>
      _$SectionFromJson(json);
  Map<String, dynamic> toJson() => _$SectionToJson(this);
}

/// Каталог в аудиозаписи.
@JsonSerializable()
class Catalog {
  @JsonKey(name: "default_section")
  final String defaultSection;

  /// Секции.
  final List<Section> sections;

  final dynamic header;

  final dynamic buttons;

  @JsonKey(name: "pinned_section")
  final String? pinnedSection;

  Catalog(
    this.defaultSection,
    this.sections,
    this.header,
    this.buttons,
    this.pinnedSection,
  );

  factory Catalog.fromJson(Map<String, dynamic> json) =>
      _$CatalogFromJson(json);
  Map<String, dynamic> toJson() => _$CatalogToJson(this);
}

@JsonSerializable()
class APICatalogRealResponse {
  /// Информация о треках.
  final List<Audio> audios;

  /// Информация о плейлистах.
  final List<AudioPlaylist> playlists;

  /// Информация о каталоге раздела "музыка".
  final Catalog catalog;

  /// Перечисление плейлистов из раздела "совпадения по вкусам".
  @JsonKey(name: "recommended_playlists")
  final List<SimillarPlaylist> recommendedPlaylists;

  APICatalogRealResponse(
    this.audios,
    this.playlists,
    this.catalog,
    this.recommendedPlaylists,
  );

  factory APICatalogRealResponse.fromJson(Map<String, dynamic> json) =>
      _$APICatalogRealResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APICatalogRealResponseToJson(this);
}

/// Ответ для метода [catalog_getAudio].
@JsonSerializable()
class APICatalogGetAudioResponse {
  /// Объект ответа.
  final APICatalogRealResponse? response;

  /// Объект ошибки.
  final APIError? error;

  APICatalogGetAudioResponse(
    this.response,
    this.error,
  );

  factory APICatalogGetAudioResponse.fromJson(Map<String, dynamic> json) =>
      _$APICatalogGetAudioResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APICatalogGetAudioResponseToJson(this);
}

/// Возвращает информацию о категории для раздела "аудио".
///
/// API: `catalog.getAudio`.
Future<APICatalogGetAudioResponse> catalog_getAudio(
  String token,
) async {
  var response = await vkAPIcall(
    "catalog.getAudio",
    token,
    {"need_blocks": "1"},
  );

  return APICatalogGetAudioResponse.fromJson(jsonDecode(response.body));
}
