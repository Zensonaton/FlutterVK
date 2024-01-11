// ignore_for_file: non_constant_identifier_names

import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "../execute.dart";
import "../shared.dart";

part "mass_audio_albums.g.dart";

/// "Уменьшенный" объект [Audio], где есть уменьшенная версия объекта [AudioThumbnails].
@JsonSerializable()
class SmallAudioAlbumData {
  /// ID аудиозаписи.
  final int id;

  /// ID владельца записи.
  @JsonKey(name: "oID")
  final int ownerID;

  /// ID альбома, если таковой есть.
  @JsonKey(name: "aID")
  final int? albumID;

  /// Наименование альбома.
  @JsonKey(name: "aT")
  final String? albumTitle;

  /// ID владельца альбома.
  @JsonKey(name: "aOID")
  final int? albumOwnerID;

  /// Ключ доступа (access key) альбома.
  @JsonKey(name: "aAKEY")
  final String? albumAccessKey;

  /// Ширина для изображения альбома.
  @JsonKey(name: "tW")
  final int? thumbnailWidth;

  /// Высота для изображения альбома.
  @JsonKey(name: "tH")
  final int? thumbnailHeight;

  /// URL на изображение альбома в размере `34`.
  @JsonKey(name: "tP34")
  final String? photo34;

  /// URL на изображение альбома в размере `68`.
  @JsonKey(name: "tP68")
  final String? photo68;

  /// URL на изображение альбома в размере `135`.
  @JsonKey(name: "tP135")
  final String? photo135;

  /// URL на изображение альбома в размере `270`.
  @JsonKey(name: "tP270")
  final String? photo270;

  /// URL на изображение альбома в размере `300`.
  @JsonKey(name: "tP300")
  final String? photo300;

  /// URL на изображение альбома в размере `600`.
  @JsonKey(name: "tP600")
  final String? photo600;

  /// URL на изображение альбома в размере `1200`.
  @JsonKey(name: "tP1200")
  final String? photo1200;

  /// Возвращает самую большую фотографию альбома.
  String? get photo =>
      photo1200 ??
      photo600 ??
      photo300 ??
      photo270 ??
      photo135 ??
      photo68 ??
      photo34;

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  String get mediaKey => "${ownerID}_$id";

  SmallAudioAlbumData(
    this.id,
    this.ownerID,
    this.albumID,
    this.albumTitle,
    this.albumOwnerID,
    this.albumAccessKey,
    this.thumbnailWidth,
    this.thumbnailHeight,
    this.photo34,
    this.photo68,
    this.photo135,
    this.photo270,
    this.photo300,
    this.photo600,
    this.photo1200,
  );

  factory SmallAudioAlbumData.fromJson(Map<String, dynamic> json) =>
      _$SmallAudioAlbumDataFromJson(json);
  Map<String, dynamic> toJson() => _$SmallAudioAlbumDataToJson(this);
}

/// Ответ для метода [scripts_massAlbumsGet].
@JsonSerializable()
class APIMassAudioAlbumsResponse {
  /// Объект ответа.
  final List<Audio>? response;

  /// Объект ошибки.
  final APIError? error;

  APIMassAudioAlbumsResponse(
    this.response,
    this.error,
  );

  factory APIMassAudioAlbumsResponse.fromJson(Map<String, dynamic> json) =>
      _$APIMassAudioAlbumsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$APIMassAudioAlbumsResponseToJson(this);
}

/// Массово извлекает информацию по альбомам (и, соответственно, изображениям) треков.
///
/// Для данного метода требуется токен от VK Admin.
Future<APIMassAudioAlbumsResponse> scripts_massAlbumsGet(
  String token,
  List<String> audioMediaIDs,
) async {
  final String executeCode = """
var audioMediaIDs = ${jsonEncode(audioMediaIDs)};

var audioAlbums = [];

var mediaIndex = 0;
while (mediaIndex < audioMediaIDs.length) {
	var response = API.audio.getById({'audios': audioMediaIDs[mediaIndex]});

	var i = 0;
	while (i < response.length) {
    audioAlbums.push(response[i]);

		i = i + 1;
	}

	mediaIndex = mediaIndex + 1;
};

return audioAlbums;""";

  var response = await VKExecuteAPI.execute(
    token,
    executeCode,
  );

  return APIMassAudioAlbumsResponse.fromJson(jsonDecode(response.body));
}
