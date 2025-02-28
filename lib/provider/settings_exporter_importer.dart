import "dart:convert";
import "dart:io";

import "package:archive/archive_io.dart";
import "package:cancellation_token/cancellation_token.dart";
import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:json_annotation/json_annotation.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../main.dart";
import "../provider/user.dart";
import "../services/logger.dart";
import "../services/player/server.dart";
import "../utils.dart";
import "playlists.dart";
import "preferences.dart";

part "settings_exporter_importer.g.dart";

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

  /// Debug-описание трека.
  @JsonKey(includeToJson: false)
  final String? debugComment;

  /// Создаёт экземпляр этого класса, забирая некоторые существующие поля из переданного [audio] типа [ExtendedAudio].
  static ExportedAudio copyFromExtendedAudio(
    ExtendedAudio audio, {
    required int playlistOwnerID,
    required int playlistID,
    bool? isExported,
    bool? forceDeezerThumbs,
    ExportedThumbnail? deezerThumbs,
    bool? isCached,
    bool? replacedLocally,
  }) =>
      ExportedAudio(
        id: audio.id,
        ownerID: audio.ownerID,
        playlistOwnerID: playlistOwnerID,
        playlistID: playlistID,
        isExported: isExported,
        forceDeezerThumbs: forceDeezerThumbs,
        deezerThumbs: deezerThumbs,
        isCached: isCached,
        replacedLocally: replacedLocally,
        debugComment: audio.toString(),
      );

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
    this.debugComment,
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

/// JSON-содержимое файла [SettingsExporter.exportedFilename], который хранит информацию об экспорте.
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
///
/// Используйте [settingsExporterProvider] для получения instance этого класса.
class SettingsExporter {
  static final AppLogger logger = getLogger("SettingsExporter");
  static const JsonEncoder jsonEncoder =
      JsonEncoder.withIndent(kDebugMode ? "\t" : null);

  /// Текущая версия экспортера, который используется в приложении.
  static const exporterVersion = 1;

  /// Возвращает название файла, в котором будут храниться данные.
  static const exportedFilename = "Audios export.fluttervk";

  final Ref ref;

  SettingsExporter({
    required this.ref,
  });

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
  ExportedSections exportSectionsData({
    bool settings = true,
    bool modifiedThumbnails = true,
    bool modifiedLyrics = true,
    bool modifiedLocalMetadata = true,
    bool cachedRestricted = true,
    bool locallyReplacedAudios = true,
  }) {
    final playlists = ref.watch(playlistsProvider).value!.playlists;
    final preferences = ref.read(preferencesProvider).toExportedJson();

    List<ExportedAudio>? sectionModifiedThumbnails = [];
    List<ExportedAudio>? sectionModifiedLyrics = [];
    List<ExportedAudio>? sectionModifiedLocalMetadata = [];
    List<ExportedAudio>? sectionCachedRestricted = [];
    List<ExportedAudio>? sectionLocallyReplacedAudios = [];

    // Получаем информацию по экспортируемым разделам.
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
            ExportedAudio.copyFromExtendedAudio(
              audio,
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
            !(audio.replacedLocally ?? false)) {
          sectionCachedRestricted ??= [];
          sectionCachedRestricted.add(
            ExportedAudio.copyFromExtendedAudio(
              audio,
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
            !(audio.isCached ?? false)) {
          sectionLocallyReplacedAudios ??= [];
          sectionLocallyReplacedAudios.add(
            ExportedAudio.copyFromExtendedAudio(
              audio,
              playlistID: playlist.id,
              playlistOwnerID: playlist.ownerID,
              replacedLocally: true,
              isExported: true,
            ),
          );
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
  Future<File?> export({
    required int userID,
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

      cancellationToken?.throwIfCancelled();

      onProgress.call(completed / total);
    }

    final exportStartedAt = getUnixTimestamp();
    final hash = hashUserID(userID);
    final key = utf8.encode(userID.toString());

    // Создаём .zip-файл, в котором будут храниться файлы.
    bool isClosed = false;
    bool forceCancelled = false;
    final encoder = ZipFileEncoder();
    final zipPath = await getExportedInfoPath();
    encoder.create(zipPath);

    try {
      // Если нет секций, то получаем их.
      sections ??= exportSectionsData(
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
        cancellationToken?.throwIfCancelled();

        final audio = exportedAudios.elementAt(i);

        // Получаем путь к аудио.
        final audioFile =
            await PlayerLocalServer.getCachedAudioByKey(audio.mediaKey);
        final exists = audioFile.existsSync();
        if (!exists) {
          throw Exception("Audio file not found: ${audio.mediaKey}");
        }

        // Загружаем аудио, а так же шифруем его при помощи XOR.
        final bytes = await audioFile.readAsBytes();
        final encrypted = await xorCryptIsolate(bytes, key);

        final archive = ArchiveFile(
          "audios\\${sha256String(audio.mediaKey)}",
          0,
          encrypted,
        );
        archive.compress = false;

        // Debug-комментарий.
        if (kDebugMode) {
          archive.comment = audio.debugComment ?? audio.toString();
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
        ArchiveFile(
          "metadata.json",
          0,
          utf8.encode(metadataJSON),
        )..compress = false,
      );

      // Сохраняем .zip.
      await encoder.close();
      isClosed = true;

      updateProgress(1, 1);

      return File(zipPath);
    } on CancelledException {
      forceCancelled = true;
    } finally {
      if (!isClosed) {
        try {
          await encoder.close();
        } catch (e) {
          // No-op.
        }
      }

      // Если запрос был отменён, то удаляем файл.
      if (forceCancelled) {
        try {
          await File(zipPath).delete();
        } catch (error) {
          // No-op.
        }
      }
    }

    return null;
  }

  /// Возвращает информацию по всем ранее экспортированным секциям по файлу [exportedFile], который был создан при помощи метода [export].
  ///
  /// Данный метод проводит проверки, связанные с [userID] а так же версией созданного файла: если они отличаются, то будет выброшено исключение.
  Future<ExportedAudiosInfoMetadata> loadSectionsData({
    required int userID,
    required File exportedFile,
  }) async {
    // Открываем .zip-файл.
    final stream = InputFileStream(exportedFile.path);
    try {
      final archive = ZipDecoder().decodeBuffer(stream);

      // Ищем метаданные.
      final metadataFile = archive.findFile("metadata.json");
      if (metadataFile == null) {
        throw Exception("Metadata file not found");
      }
      final metadata = ExportedAudiosInfoMetadata.fromJson(
        json.decode(utf8.decode(metadataFile.content)),
      );

      // Проверяем правильность хэша.
      if (metadata.hash != hashUserID(userID)) {
        throw Exception("Wrong user ID");
      }

      // Проверяем версию экспортера.
      final versionDiffString =
          "ver ${metadata.exporterVersion} (app v${metadata.appVersion}) vs $exporterVersion (app v$appVersion)";
      if (metadata.exporterVersion > exporterVersion) {
        throw Exception(
          "Bad exporter version ($versionDiffString)",
        );
      } else if (metadata.exporterVersion < exporterVersion) {
        logger.w(
          "Old exporter file version ($versionDiffString})",
        );
      }

      return metadata;
    } finally {
      await stream.close();
    }
  }

  /// Производит импорт настроек и треков пользователя по файлу [exportedFile], который был создан при помощи метода [export].
  ///
  /// Возвращает список из [ExtendedPlaylist], в которых есть изменения треков.
  Future<List<ExtendedPlaylist>> import({
    required int userID,
    required File exportedFile,
    ExportedAudiosInfoMetadata? exportedMetadata,
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

      cancellationToken?.throwIfCancelled();

      onProgress.call(completed / total);
    }

    final key = utf8.encode(userID.toString());

    // Открываем .zip-файл.
    bool isClosed = false;
    final stream = InputFileStream(exportedFile.path);
    try {
      final archive = ZipDecoder().decodeBuffer(stream);

      // Если нет метаданных, то загружаем их из файла.
      exportedMetadata ??= await loadSectionsData(
        userID: userID,
        exportedFile: exportedFile,
      );

      final preferences = ref.read(preferencesProvider.notifier);
      final playlists = ref.read(playlistsProvider.notifier);

      // Импортируем настройки.
      if (settings) {
        preferences.setFromJson(exportedMetadata.sections.settings ?? {});
      }

      // Копируем экспортированные треки, что бы потом пометить их как кэшированные.
      final possibleExportedAudios = [
        if (cachedRestricted)
          ...(exportedMetadata.sections.cachedRestricted ?? []),
        if (locallyReplacedAudios)
          ...(exportedMetadata.sections.locallyReplacedAudios ?? []),
      ];
      final exportedAudios = possibleExportedAudios
          .where(
            (audio) => audio.isExported == true,
          )
          .toSet();
      final totalAudios = exportedAudios.length;

      for (int i = 0; i < totalAudios; i++) {
        cancellationToken?.throwIfCancelled();

        final audio = exportedAudios.elementAt(i);

        // Ищем плейлист, с которым связан трек.
        final playlist =
            playlists.getPlaylist(audio.playlistOwnerID, audio.playlistID);
        if (playlist == null) {
          logger.w("Playlist not found for audio: $audio");

          continue;
        }

        // Ищем трек в плейлисте.
        final playlistAudio = playlist.audios?.firstWhereOrNull(
          (item) => item.id == audio.id,
        );
        if (playlistAudio == null) {
          logger.w("Audio not found in playlist: $audio");

          continue;
        }

        // Загружаем аудио из архива.
        final archiveAudioPath = "audios/${sha256String(audio.mediaKey)}";
        final archiveAudio = archive.findFile(archiveAudioPath);
        if (archiveAudio == null) {
          throw Exception("Audio file not found: ${audio.mediaKey}");
        }
        final Uint8List encryptedBytes = archiveAudio.content;
        final int encryptedSize = encryptedBytes.length;

        // Расшифровываем трек, потом копируем его, и помечаем как кэшированный, если это не было сделано ранее.
        if ((playlistAudio.isCached != true &&
                playlistAudio.replacedLocally != true) ||
            encryptedSize != playlistAudio.cachedSize) {
          // Расшифровываем трек из архива.
          final decrypted = await xorCryptIsolate(encryptedBytes, key);
          updateProgress(i * 2 + 1, totalAudios * 2);

          // Сохраняем аудио на диск.
          final audioPath =
              await PlayerLocalServer.getCachedAudioByKey(audio.mediaKey);
          await audioPath.create(recursive: true);
          await audioPath.writeAsBytes(decrypted);

          // Помечаем аудио как кэшированное.
          //
          // Сохраяем плейлист в БД каждые 3 трека.
          await playlists.updatePlaylist(
            playlist.basicCopyWith(
              audiosToUpdate: [
                playlistAudio.basicCopyWith(
                  isCached: audio.isCached,
                  replacedLocally: audio.replacedLocally,
                  cachedSize: encryptedSize,
                ),
              ],
            ),
            saveInDB: i % 3 == 0,
          );
        }

        updateProgress(i * 2 + 2, totalAudios * 2);
      }

      // Треки успешно были скопированы на диск и помечены как кэшированные.
      // Теперь нам нужно обновить метаданные (обложки, ...) этих треков.
      final List<ExportedAudio> modifiedAudios = [
        if (modifiedThumbnails)
          ...(exportedMetadata.sections.modifiedThumbnails ?? []),
        if (modifiedLyrics) ...(exportedMetadata.sections.modifiedLyrics ?? []),
        if (modifiedLocalMetadata)
          ...(exportedMetadata.sections.modifiedLocalMetadata ?? []),
      ];
      final List<ExtendedPlaylist> modifiedPlaylists = [];

      for (ExportedAudio audio in modifiedAudios) {
        cancellationToken?.throwIfCancelled();

        // Ищем плейлист, с которым связан трек.
        final playlist =
            playlists.getPlaylist(audio.playlistOwnerID, audio.playlistID);
        if (playlist == null) {
          logger.w("Playlist not found for audio: $audio");

          continue;
        }

        // Ищем трек в плейлисте.
        final playlistAudio = playlist.audios?.firstWhereOrNull(
          (item) => item.id == audio.id,
        );
        if (playlistAudio == null) {
          logger.w("Audio not found in playlist: $audio");

          continue;
        }

        // Обновляем трек.
        final updatedAudio = playlistAudio.basicCopyWith(
          forceDeezerThumbs: audio.forceDeezerThumbs,
          deezerThumbs: audio.deezerThumbs != null
              ? ExtendedThumbnails(
                  photoSmall: audio.deezerThumbs!.photoSmall,
                  photoMedium: audio.deezerThumbs!.photoMedium,
                  photoBig: audio.deezerThumbs!.photoBig,
                  photoMax: audio.deezerThumbs!.photoMax,
                )
              : null,
        );
        // TODO: Сбрасывать кэшированные цвета обложек.

        // Сохраняем плейлист в список обновлённых.
        final existingPlaylist = modifiedPlaylists.firstWhereOrNull(
          (p) => p.id == playlist.id && p.ownerID == playlist.ownerID,
        );

        if (existingPlaylist != null) {
          existingPlaylist.audiosToUpdate!.add(updatedAudio);
        } else {
          modifiedPlaylists.add(
            playlist.basicCopyWith(
              audiosToUpdate: [updatedAudio],
            ),
          );
        }
      }

      // Сохраняем изменённые плейлисты.
      await playlists.updatePlaylists(
        modifiedPlaylists,
        saveInDB: true,
      );

      return modifiedPlaylists;
    } finally {
      if (!isClosed) {
        try {
          await stream.close();
        } catch (e) {
          // No-op.
        }
      }
    }
  }
}

/// [Provider] для получения объекта [SettingsExporter].
@riverpod
SettingsExporter settingsExporter(Ref ref) => SettingsExporter(ref: ref);
