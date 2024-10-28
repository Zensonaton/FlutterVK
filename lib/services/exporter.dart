import "dart:convert";
import "dart:io";

import "package:archive/archive_io.dart";
import "package:cancellation_token/cancellation_token.dart";
import "package:flutter/foundation.dart";
import "package:json_annotation/json_annotation.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";

import "../main.dart";
import "../provider/user.dart";
import "../utils.dart";
import "audio_player.dart";
import "logger.dart";

part "exporter.g.dart";

/// Класс, олицетворяющий экспортированную обложку.
@JsonSerializable()
class ExportedThumbnail {
  /// Размеры изображений, в зависимости от источника:
  /// - ВКонтакте: `68x68`.
  /// - Deezer: `56x56`.
  final String photoSmall;

  /// Размеры изображений, в зависимости от источника:
  /// - ВКонтакте: `270x270`.
  /// - Deezer: `250x250`.
  final String photoMedium;

  /// Размеры изображений, в зависимости от источника:
  /// - ВКонтакте: `600x600`.
  /// - Deezer: `500x500`.
  final String photoBig;

  /// Размеры изображений, в зависимости от источника:
  /// - ВКонтакте: `1200x1200`.
  /// - Deezer: `1000x1000`.
  final String photoMax;

  ExportedThumbnail({
    required this.photoSmall,
    required this.photoMedium,
    required this.photoBig,
    required this.photoMax,
  });

  factory ExportedThumbnail.fromJson(Map<String, dynamic> json) =>
      _$ExportedThumbnailFromJson(json);
  Map<String, dynamic> toJson() => _$ExportedThumbnailToJson(this);
}

/// Класс, олицетворяющий экспортированное аудио.
@JsonSerializable(includeIfNull: false)
class ExportedAudio {
  /// ID аудиозаписи.
  final int id;

  /// ID владельца аудиозаписи.
  final int ownerID;

  /// ID владельца плейлиста.
  final int playlistOwnerID;

  /// ID плейлиста.
  final int playlistID;

  /// Указывает, что `.mp3`-файл трека был экспортирован.
  final bool? isExported;

  /// Указывает, что используется обложка из Deezer.
  final bool? forceDeezerThumbs;

  /// Обложки из Deezer.
  final ExportedThumbnail? deezerThumbs;

  /// Указывает, что трек кэширован.
  final bool? isCached;

  /// Указывает, что `.mp3`-файл трека был локально заменён.
  final bool? replacedLocally;

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  String get mediaKey => "${ownerID}_$id";

  @override
  String toString() => "ExportedAudio $mediaKey";

  @override
  bool operator ==(covariant ExportedAudio other) {
    if (identical(this, other)) return true;

    return other.runtimeType == ExportedAudio &&
        other.id == id &&
        other.ownerID == ownerID;
  }

  @override
  int get hashCode => mediaKey.hashCode;

  ExportedAudio({
    required this.id,
    required this.ownerID,
    required this.playlistOwnerID,
    required this.playlistID,
    this.isExported,
    this.forceDeezerThumbs,
    this.deezerThumbs,
    this.isCached,
    this.replacedLocally,
  });

  factory ExportedAudio.fromJson(Map<String, dynamic> json) =>
      _$ExportedAudioFromJson(json);
  Map<String, dynamic> toJson() => _$ExportedAudioToJson(this);
}

/// Класс, олицетворяющий секции экспортированных данных.
@JsonSerializable(includeIfNull: false)
class ExportedSections {
  /// Экспортированные настройки.
  final Map<String, dynamic>? settings;

  /// Список из треков, обложки которых были изменены.
  final List<ExportedAudio>? modifiedThumbnails;

  /// Список из треков, тексты песен (lyrics) которых были изменены.
  final List<ExportedAudio>? modifiedLyrics;

  /// Список из треков, метаданные (название, исполнитель и другие) которых были изменены.
  final List<ExportedAudio>? modifiedLocalMetadata;

  /// Список из ограниченныых  (со стороны ВКонтакте) треков, которые были кэшированы пользователем.
  final List<ExportedAudio>? cachedRestricted;

  /// Список из треков, у которых были локально заменённые `mp3`.
  final List<ExportedAudio>? locallyReplacedAudios;

  ExportedSections({
    this.settings,
    this.modifiedThumbnails,
    this.modifiedLyrics,
    this.modifiedLocalMetadata,
    this.cachedRestricted,
    this.locallyReplacedAudios,
  });

  factory ExportedSections.fromJson(Map<String, dynamic> json) =>
      _$ExportedSectionsFromJson(json);
  Map<String, dynamic> toJson() => _$ExportedSectionsToJson(this);
}

/// JSON-содержимое файла [AudiosInfoExporter.exportedFilename], который хранит информацию об экспорте.
@JsonSerializable()
class ExportedAudiosInfoMetadata {
  /// Версия экспортера, который использовался для создания файла.
  ///
  /// Если версия отличается от текущей, то это значит, что файл был создан в другой версии Flutter VK.
  final int exporterVersion;

  /// Версия Flutter VK, в которой был создан файл.
  final String appVersion;

  /// UNIX-timestamp начала создания файла.
  final int exportStartedAt;

  /// UNIX-timestamp окончания создания файла.
  final int exportedAt;

  /// SHA-256 хэш ID пользователя ВКонтакте, для которого был создан файл.
  ///
  /// Вычисляется как `sha256(reversed(userID))`.
  ///
  /// Может в редких случаях отсутствовать, если экспорт был произведён экстренно (после force-сброса БД).
  final String? hash;

  /// Информация об экспортированных разделах.
  final ExportedSections sections;

  ExportedAudiosInfoMetadata({
    required this.exporterVersion,
    required this.appVersion,
    required this.exportStartedAt,
    required this.exportedAt,
    this.hash,
    required this.sections,
  });

  factory ExportedAudiosInfoMetadata.fromJson(Map<String, dynamic> json) =>
      _$ExportedAudiosInfoMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$ExportedAudiosInfoMetadataToJson(this);
}

/// Класс, отображающий сервис для экспортирования и импорта изменений треков.
class AudiosInfoExporter {
  static final AppLogger logger = getLogger("AudiosInfoExporter");
  static const JsonEncoder jsonEncoder =
      JsonEncoder.withIndent(kDebugMode ? "\t" : null);

  /// Текущая версия экспортера, который используется в приложении.
  static const exporterVersion = 1;

  /// Возвращает название файла, в котором будут храниться данные.
  static const exportedFilename = "Audios export.fluttervk";

  /// Возвращает путь, в которой будет сохранён временный файл экспорта [exportedFilename].
  static Future<String> getExportedInfoPath() async => join(
        (await getApplicationSupportDirectory()).path,
        exportedFilename,
      );

  /// Возвращает SHA-256 хэш из передаваемого [userID].
  static String hashUserID(int userID) => sha256String(
        userID.toString().split("").reversed.join(),
      );

  /// Возвращает информацию по всем секциям экспортированных данных.
  static ExportedSections exportSectionsData({
    List<ExtendedPlaylist>? playlists,
    Map<String, dynamic>? preferences,
    bool settings = true,
    bool modifiedThumbnails = true,
    bool modifiedLyrics = true,
    bool modifiedLocalMetadata = true,
    bool cachedRestricted = true,
    bool locallyReplacedAudios = true,
  }) {
    if (playlists == null &&
        (modifiedThumbnails ||
            modifiedLyrics ||
            modifiedLocalMetadata ||
            cachedRestricted ||
            locallyReplacedAudios)) {
      throw Exception("User playlists are empty");
    }
    if (preferences == null && settings) {
      throw Exception("User preferences are null");
    }

    List<ExportedAudio>? sectionModifiedThumbnails = [];
    List<ExportedAudio>? sectionModifiedLyrics = [];
    List<ExportedAudio>? sectionModifiedLocalMetadata = [];
    List<ExportedAudio>? sectionCachedRestricted = [];
    List<ExportedAudio>? sectionLocallyReplacedAudios = [];

    // Получаем информацию по экспортируемым разделам.
    if (playlists != null) {
      for (ExtendedPlaylist playlist in playlists) {
        if (playlist.audios == null) continue;

        // Проходимся по каждому треку в плейлисте.
        for (ExtendedAudio audio in playlist.audios!) {
          // Изменённые обложки треков.
          if (modifiedThumbnails &&
              audio.forceDeezerThumbs == true &&
              audio.deezerThumbs != null) {
            sectionModifiedThumbnails ??= [];
            sectionModifiedThumbnails.add(
              ExportedAudio(
                id: audio.id,
                ownerID: audio.ownerID,
                playlistID: playlist.id,
                playlistOwnerID: playlist.ownerID,
                forceDeezerThumbs: true,
                deezerThumbs: ExportedThumbnail(
                  photoSmall: audio.deezerThumbs!.photoSmall,
                  photoMedium: audio.deezerThumbs!.photoMedium,
                  photoBig: audio.deezerThumbs!.photoBig,
                  photoMax: audio.deezerThumbs!.photoMax,
                ),
              ),
            );
          }

          // TODO: Изменённые тексты песен.
          // TODO: Изменённые параметры треков.

          // Кэшированные, но ограниченные треки.
          if (cachedRestricted &&
              audio.isRestricted &&
              audio.isCached == true &&
              audio.replacedLocally == false) {
            sectionCachedRestricted ??= [];
            sectionCachedRestricted.add(
              ExportedAudio(
                id: audio.id,
                ownerID: audio.ownerID,
                playlistID: playlist.id,
                playlistOwnerID: playlist.ownerID,
                isCached: true,
                isExported: true,
              ),
            );
          }

          // Локально заменённые треки.
          if (locallyReplacedAudios &&
              audio.replacedLocally == true &&
              audio.isCached == false) {
            sectionLocallyReplacedAudios ??= [];
            sectionLocallyReplacedAudios.add(
              ExportedAudio(
                id: audio.id,
                ownerID: audio.ownerID,
                playlistID: playlist.id,
                playlistOwnerID: playlist.ownerID,
                replacedLocally: true,
                isExported: true,
              ),
            );
          }
        }
      }
    }

    List<ExportedAudio>? listIfNotEmpty(List<ExportedAudio>? list) {
      if (list == null || list.isEmpty) return null;

      return list;
    }

    return ExportedSections(
      settings: settings ? preferences : null,
      modifiedThumbnails: listIfNotEmpty(sectionModifiedThumbnails),
      modifiedLyrics: listIfNotEmpty(sectionModifiedLyrics),
      modifiedLocalMetadata: listIfNotEmpty(sectionModifiedLocalMetadata),
      cachedRestricted: listIfNotEmpty(sectionCachedRestricted),
      locallyReplacedAudios: listIfNotEmpty(sectionLocallyReplacedAudios),
    );
  }

  /// Производит экспорт настроек и треков пользователя. Возвращает [File], репрезентирующий `.zip`-файл, в котором хранятся все экспортированные данные.
  ///
  /// Если [sections] не указан, то требуется, что бы были указаны включённые разделы ([settings], [modifiedThumbnails], [modifiedLyrics], [modifiedLocalMetadata], [cachedRestricted], [locallyReplacedAudios]), а так же им были переданы данные ([playlists], [preferences]).
  static Future<File?> export({
    required int userID,
    List<ExtendedPlaylist>? playlists,
    Map<String, dynamic>? preferences,
    ExportedSections? sections,
    bool settings = false,
    bool modifiedThumbnails = false,
    bool modifiedLyrics = false,
    bool modifiedLocalMetadata = false,
    bool cachedRestricted = false,
    bool locallyReplacedAudios = false,
    CancellationToken? cancellationToken,
    Function(double)? onProgress,
  }) async {
    void updateProgress(int completed, int total) {
      if (onProgress == null) return;

      if (cancellationToken?.isCancelled == true) {
        throw const CancelledException();
      }

      onProgress.call(completed / total);
    }

    final exportStartedAt = getUnixTimestamp();
    final hash = hashUserID(userID);
    final key = utf8.encode(userID.toString());

    // Создаём .zip-файл, в котором будут храниться файлы.
    bool isClosed = false;
    final encoder = ZipFileEncoder();
    final zipPath = await getExportedInfoPath();
    encoder.create(zipPath);

    try {
      // Если нет секций, то получаем их.
      sections ??= exportSectionsData(
        playlists: playlists,
        preferences: preferences,
        settings: settings,
        modifiedThumbnails: modifiedThumbnails,
        modifiedLyrics: modifiedLyrics,
        modifiedLocalMetadata: modifiedLocalMetadata,
        cachedRestricted: cachedRestricted,
        locallyReplacedAudios: locallyReplacedAudios,
      );

      // Копируем треки в папку экспорта.
      //
      // Проходимся по секциям, и ищем те треки, которые имеют поле isExported.
      // Если оно равно true, то копируем трек в папку экспорта.
      final possibleExportedAudios = [
        ...(sections.cachedRestricted ?? []),
        ...(sections.locallyReplacedAudios ?? []),
      ];
      final exportedAudios = possibleExportedAudios
          .where(
            (audio) => audio.isExported == true,
          )
          .toSet();
      final totalAudios = exportedAudios.length;

      for (int i = 0; i < totalAudios; i++) {
        if (cancellationToken?.isCancelled == true) {
          throw const CancelledException();
        }

        final audio = exportedAudios.elementAt(i);

        // Получаем путь к аудио.
        final audioFile = await CachedStreamAudioSource.getCachedAudioByKey(
          audio.mediaKey,
        );
        final exists = audioFile.existsSync();
        if (!exists) {
          throw Exception("Audio file not found: ${audio.mediaKey}");
        }

        // Загружаем аудио, а так же шифруем его при помощи XOR.
        final bytes = await audioFile.readAsBytes();
        final encrypted = await xorCryptIsolate(bytes, key);

        final archive = ArchiveFile(
          "audios\\${sha256String(audio.mediaKey)}.mp3",
          0,
          encrypted,
        );
        archive.compress = false;

        // Debug-комментарий.
        if (kDebugMode) {
          archive.comment = audio.toString();
        }

        encoder.addArchiveFile(archive);

        updateProgress(i + 1, totalAudios);
      }

      // Создаём файл `metadata.json`, добавляя его в архив.
      final exportedMetadata = ExportedAudiosInfoMetadata(
        exporterVersion: exporterVersion,
        appVersion: appVersion,
        exportStartedAt: exportStartedAt,
        exportedAt: getUnixTimestamp(),
        hash: hash,
        sections: sections,
      );
      final metadataJSON = jsonEncoder.convert(exportedMetadata.toJson());
      encoder.addArchiveFile(
        ArchiveFile.string(
          "metadata.json",
          metadataJSON,
        ),
      );

      // Сохраняем .zip.
      await encoder.close();
      isClosed = true;

      updateProgress(1, 1);

      return File(zipPath);
    } on CancelledException {
      // No-op.
    } catch (error, stackTrace) {
      logger.e(
        "Error while exporting:",
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      if (!isClosed) {
        try {
          await encoder.close();
        } catch (e) {
          // No-op.
        }
      }
    }

    return null;
  }
}
