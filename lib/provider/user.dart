import "dart:io";

import "package:audio_service/audio_service.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../api/vk/audio/add.dart";
import "../api/vk/audio/delete.dart";
import "../api/vk/audio/edit.dart";
import "../api/vk/audio/get.dart";
import "../api/vk/audio/get_lyrics.dart";
import "../api/vk/audio/get_playlists.dart";
import "../api/vk/audio/restore.dart";
import "../api/vk/audio/search.dart";
import "../api/vk/catalog/get_audio.dart";
import "../api/vk/consts.dart";
import "../api/vk/executeScripts/audio_get_data.dart";
import "../api/vk/executeScripts/mass_audio_albums.dart";
import "../api/vk/executeScripts/mass_audio_get.dart";
import "../api/vk/shared.dart";
import "../api/vk/users/get.dart";
import "../db/schemas/playlists.dart";
import "../enums.dart";
import "../main.dart";
import "../services/audio_player.dart";
import "../services/cache_manager.dart";
import "../services/logger.dart";
import "../utils.dart";

/// Класс, копирующий поля из класса [Playlist] от API ВКонтакте, добавляющий информацию о треках в данном плейлисте.
class ExtendedPlaylist {
  /// ID плейлиста.
  int id;

  /// ID владельца плейлиста.
  int ownerID;

  /// Название плейлиста.
  String? title;

  /// Описание плейлиста. Пустые описания плейлистов (т.е., [String.isEmpty]) будут восприниматься как null.
  String? description;

  /// Подпись плейлиста, обычно присутствует в плейлистах-рекомендациях. Пустые подписи (т.е., [String.isEmpty]) будут восприниматься как null.
  String? subtitle;

  /// Количество аудиозаписей в данном плейлисте.
  ///
  /// Это значение возвращает общее количество треков в плейлисте, вне зависимости от количества треков в [audios].
  int count;

  /// Ключ доступа.
  String? accessKey;

  /// Количество подписчиков плейлиста.
  int followers;

  /// Количество проигрываний плейлиста.
  int plays;

  /// Timestamp создания плейлиста.
  int? createTime;

  /// Timestamp последнего обновления плейлиста.
  int? updateTime;

  /// Указывает, подписан ли данный пользователь на данный плейлист или нет.
  bool isFollowing;

  /// Фотография плейлиста.
  Thumbnails? photo;

  /// Список из аудио в данном плейлисте.
  Set<ExtendedAudio>? audios;

  /// Указывает, что данный плейлист является плейлистом с "любимыми" треками пользователя.
  bool get isFavoritesPlaylist => id == 0;

  /// Указывает, что данный плейлист является обычным плейлистом пользователя, который он либо создал либо сохранил.
  bool get isRegularPlaylist =>
      id > 0 && ownerID != vkMusicGroupID && !isSimillarPlaylist;

  /// Указывает, что данный плейлист является плейлистом из рекомендаций.
  bool get isRecommendationsPlaylist => id < 0;

  /// Указывает, что данный плейлист является плейлистом из раздела "Совпадения по вкусам".
  bool get isSimillarPlaylist => simillarity != null;

  /// Указывает, что данный плейлист является плейлистом от ВКонтакте (плейлист из раздела "Собрано редакцией")
  bool get isMadeByVKPlaylist => ownerID == vkMusicGroupID;

  /// Указывает, пуст ли данный плейлист. Данный метод всегда возвращает true, если треки не были загружены.
  bool get isEmpty => audios == null ? true : count == 0;

  /// Указывает процент "схожести" данного плейлиста. Данное поле не-null только для плейлистов из раздела "совпадения по вкусам".
  final double? simillarity;

  /// Указывает Hex-цвет для данного плейлиста. Данное поле не-null только для плейлистов из раздела "совпадения по вкусам".
  final String? color;

  /// Указывает первые 3 известных трека для данного плейлиста. Данное поле не-null только для плейлистов из раздела "совпадения по вкусам".
  final List<ExtendedAudio>? knownTracks;

  /// Указывает, что данный плейлист был загружен с API ВКонтакте. Если данное поле false, то это значит, что все данные из этого плейлиста являются кешированными (т.е., загружены из БД Isar).
  ///
  /// Не стоит путать с [areTracksLive], данное поле указывает только то, что основная информация о плейлисте (его количество прослушиваний, изображение, ...) была загружена с API ВКонтакте, данное поле не отображает состояние загрузки треков в данном плейлисте.
  bool isLiveData;

  /// Указывает, что данный плейлист был загружен с БД Isar, т.е., данные этого плейлиста являются кэшированными.
  ///
  /// Данное поле является противоположностью поля [isLiveData].
  bool get isDataCached => !isLiveData;

  /// Указывает, что треки данного плейлиста были загружены с API ВКонтакте. Если данное поле false, то это значит, что все треки из этого плейлиста являются кешированными (т.е., загружены из БД Isar).
  ///
  /// Не стоит путать с [isLiveData], данное поле указывает только то, что треки в данном плейлисте были загружены с API ВКонтакте, данное поле не отображает состояние загруженности данных о самом плейлисте.
  bool areTracksLive;

  /// Указывает, что треки данного плейлиста были загружены с БД Isar, т.е., данные этого плейлиста являются кэшированными.
  ///
  /// Данное поле является противоположностью поля [areTracksLive].
  bool get areTracksCached => !areTracksLive;

  /// Указывает, что в данном плейлисте разрешено кэширование треков.
  bool? cacheTracks;

  /// Возвращает длительность всего плейлиста. Если список треков ещё не был получен, то возвращает null.
  Duration? get duration {
    if (audios == null) return null;

    return audios!.fold<Duration>(
      Duration.zero,
      (
        Duration totalDuration,
        ExtendedAudio audio,
      ) {
        return totalDuration +
            Duration(
              seconds: audio.duration,
            );
      },
    );
  }

  /// Создаёт из передаваемого объекта [Playlist] объект данного класа.
  static ExtendedPlaylist fromAudioPlaylist(
    Playlist playlist, {
    Set<ExtendedAudio>? audios,
    int? totalAudios,
    double? simillarity,
    String? color,
    List<ExtendedAudio>? knownTracks,
    bool isLiveData = true,
    bool areTracksLive = false,
  }) =>
      ExtendedPlaylist(
        id: playlist.id,
        ownerID: playlist.ownerID,
        title: playlist.title,
        description: playlist.description,
        count: playlist.count,
        accessKey: playlist.accessKey,
        followers: playlist.followers,
        plays: playlist.plays,
        createTime: playlist.createTime,
        updateTime: playlist.updateTime,
        isFollowing: playlist.isFollowing,
        subtitle: playlist.subtitle,
        photo: playlist.photo,
        audios: audios,
        simillarity: simillarity,
        color: color,
        knownTracks: knownTracks,
        isLiveData: isLiveData,
        areTracksLive: areTracksLive,
      );

  /// Создаёт из передаваемого объекта [DBPlaylist] объект данного класа.
  static ExtendedPlaylist fromDBPlaylist(
    DBPlaylist playlist,
  ) =>
      ExtendedPlaylist(
        id: playlist.id,
        ownerID: playlist.ownerID,
        title: playlist.title,
        description: playlist.description,
        count: playlist.count,
        accessKey: playlist.accessKey,
        followers: playlist.followers,
        plays: playlist.plays,
        createTime: playlist.createTime,
        updateTime: playlist.updateTime,
        isFollowing: playlist.isFollowing ?? false,
        subtitle: playlist.subtitle,
        photo: playlist.photo?.asThumbnails,
        audios: playlist.audios
            ?.map(
              (DBAudio audio) => ExtendedAudio.fromDBAudio(
                audio,
                isLiked: playlist.id == 0,
              ),
            )
            .toSet(),
        simillarity: playlist.simillarity,
        color: playlist.color,
        knownTracks: playlist.knownTracks
            ?.map(
              (DBAudio audio) => ExtendedAudio.fromDBAudio(
                audio,
                isLiked: playlist.id == 0,
              ),
            )
            .toList(),
        cacheTracks: playlist.isCachingAllowed,
      );

  /// Возвращает копию данного класса в виде объекта [DBPlaylist].
  DBPlaylist get asDBPlaylist => DBPlaylist.fromExtendedPlaylist(this);

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  String get mediaKey => "${ownerID}_$id";

  @override
  String toString() =>
      "ExtendedPlaylist $mediaKey with ${audios?.length}/$count tracks ${isDataCached ? '(cached data)' : ''} ${areTracksCached ? '(cached tracks)' : ''}";

  @override
  bool operator ==(covariant ExtendedPlaylist other) {
    if (identical(this, other)) return true;

    return other.runtimeType == ExtendedPlaylist && other.mediaKey == mediaKey;
  }

  @override
  int get hashCode => mediaKey.hashCode;

  ExtendedPlaylist({
    required this.id,
    required this.ownerID,
    this.title,
    this.description,
    required this.count,
    this.accessKey,
    this.followers = 0,
    this.plays = 0,
    this.createTime,
    this.updateTime,
    this.isFollowing = false,
    this.subtitle,
    this.photo,
    this.audios,
    this.simillarity,
    this.color,
    this.knownTracks,
    this.isLiveData = false,
    this.areTracksLive = false,
    this.cacheTracks,
  });
}

/// Класс, копирующий поля объекта [Audio] от API ВКонтакте, добавляя некоторые новые поля.
class ExtendedAudio {
  /// ID аудиозаписи.
  int id;

  /// ID владельца аудиозаписи.
  int ownerID;

  /// Имя исполнителя.
  String artist;

  /// Название аудиозаписи.
  String title;

  /// Длительность аудиозаписи в секундах.
  final int duration;

  /// Подпись трека.
  final String? subtitle;

  /// Ключ доступа.
  String accessKey;

  /// Указывает, если это Explicit-аудиозапись.
  final bool isExplicit;

  /// Указывает, что данный трек ограничен.
  final bool isRestricted;

  /// URL на `mp3` данной аудиозаписи.
  ///
  /// Очень часто он отсутствует, выдавая пустую строку.
  String? url;

  /// Timestamp добавления аудиозаписи.
  final int date;

  /// Информация об альбоме данной аудиозаписи.
  Album? album;

  /// Указывает наличие текста песни.
  final bool hasLyrics;

  /// ID жанра аудиозаписи. Список жанров описан [здесь](https://dev.vk.com/ru/reference/objects/audio-genres).
  int? genreID;

  /// Информация о тексте песни.
  Lyrics? lyrics;

  /// ID трека ([id]) до его добавления в список фаворитов.
  ///
  /// Данное поле устанавливается приложением (оно не передаётся API ВКонтакте) при добавлении трека в списка "любимых треков", поскольку оригинальное поле [id] заменяется новым значением.
  int? oldID;

  /// ID владельца трека ([ownerID]) до его добавления в список фаворитов.
  ///
  /// Данное поле устанавливается приложением (оно не передаётся API ВКонтакте) при добавлении трека в списка "любимых треков", поскольку оригинальное поле [ownerID] заменяется значением ID владельца текущей страницы.
  int? oldOwnerID;

  /// Указывает, что данный трек лайкнут (если находится в плейлисте "любимые треки").
  ///
  /// Данное поле может стать false только в том случае, если пользователь удалил трек, который ранее был лайкнутым.
  bool isLiked;

  String? _normalizedName;

  /// Возвращает "чистое" название данного трека, в котором используется название трека и его исполнитель.
  ///
  /// В данной строке удалены диакритические символы благодаря вызову метода [cleanString]. Сравнивая строки, стоит воспользоваться именно методом [cleanString].
  String get normalizedName {
    _normalizedName ??= cleanString(title + artist);

    return _normalizedName!;
  }

  String? _durationString;

  /// Возвращает длительность данного трека в формате `01:23`.
  String get durationString {
    _durationString ??= secondsAsString(duration);

    return _durationString!;
  }

  /// Указывает, кэширован ли данный трек.
  bool? isCached;

  /// [ValueNotifier] для указания прогресса загрузки трека этого трека.
  ///
  /// Указывает значение от 0.0 до 1.0.
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);

  /// Возвращает данный объект как [MediaItem] для аудио плеера.
  MediaItem get asMediaItem => MediaItem(
        id: mediaKey,
        title: title,
        album: album?.title,
        artist: artist,
        artUri: album?.thumbnails != null
            ? Uri.parse(
                album!.thumbnails!.photo1200!,
              )
            : null,
        duration: Duration(
          seconds: duration,
        ),
        extras: {
          "albumID": album?.id,
        },
      );

  /// Создаёт из передаваемого объекта [Audio] объект данного класа.
  static ExtendedAudio fromAudio(
    Audio audio, {
    Lyrics? lyrics,
    bool? isLiked,
  }) =>
      ExtendedAudio(
        id: audio.id,
        ownerID: audio.ownerID,
        artist: audio.artist,
        title: audio.title,
        duration: audio.duration,
        subtitle: audio.subtitle,
        accessKey: audio.accessKey,
        isExplicit: audio.isExplicit,
        isRestricted: audio.isRestricted,
        url: audio.url,
        date: audio.date,
        album: audio.album,
        hasLyrics: audio.hasLyrics,
        genreID: audio.genreID,
        lyrics: lyrics,
        isLiked: isLiked ?? false,
      );

  /// Создаёт из передаваемого объекта [DBAudio] объект данного класа.
  static ExtendedAudio fromDBAudio(
    DBAudio audio, {
    bool isLiked = false,
  }) =>
      ExtendedAudio(
        id: audio.id!,
        ownerID: audio.ownerID!,
        artist: audio.artist!,
        title: audio.title!,
        duration: audio.duration!,
        subtitle: audio.subtitle,
        accessKey: audio.accessKey!,
        isExplicit: audio.isExplicit!,
        isRestricted: audio.isRestricted!,
        date: audio.date!,
        album: audio.album?.asAudioAlbum,
        hasLyrics: audio.hasLyrics!,
        genreID: audio.genreID ?? 18,
        lyrics: audio.lyrics?.asLyrics,
        isLiked: isLiked,
        isCached: audio.isCached ?? false,
      );

  /// Возвращает копию данного класса в виде объекта [DBAudio].
  DBAudio get asDBAudio => DBAudio.fromExtendedAudio(this);

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  String get mediaKey => "${ownerID}_$id";

  @override
  String toString() => "ExtendedAudio $mediaKey $artist - $title";

  @override
  bool operator ==(covariant ExtendedAudio other) {
    if (identical(this, other)) return true;

    return other.runtimeType == ExtendedAudio && other.mediaKey == mediaKey;
  }

  @override
  int get hashCode => mediaKey.hashCode;

  ExtendedAudio({
    required this.id,
    required this.ownerID,
    required this.artist,
    required this.title,
    required this.duration,
    this.subtitle,
    required this.accessKey,
    this.isExplicit = false,
    this.isRestricted = false,
    this.url,
    required this.date,
    this.album,
    this.hasLyrics = false,
    this.genreID,
    this.lyrics,
    this.isLiked = false,
    this.isCached,
  });
}

/// Класс с настройками пользователя.
class Settings {
  /// Указывает, что поле "Моя музыка" включено на экране с музыкой.
  bool myMusicChipEnabled = true;

  /// Указывает, что поле "Ваши плейлисты" включено на экране с музыкой.
  bool playlistsChipEnabled = true;

  /// Указывает, что поле "Плейлисты для Вас" включено на экране с музыкой.
  bool recommendedPlaylistsChipEnabled = true;

  /// Указывает, что поле "Совпадения по вкусам" включено на экране с музыкой.
  bool similarMusicChipEnabled = true;

  /// Указывает, что поле "Собрано редакцией" включено на экране с музыкой.
  bool byVKChipEnabled = true;

  /// Указывает, что при последнем прослушивании shuffle был включён.
  bool shuffleEnabled = false;

  /// Указывает, что Discord Rich Presence включён.
  bool discordRPCEnabled = true;

  /// Указывает, что настройка "пауза при минимальной громкости" включена.
  bool pauseOnMuteEnabled = false;

  /// Указывает, что полноэкранный плеер использует изображение трека в качестве фона.
  bool playerThumbAsBackground = true;

  /// Указывает, что включён показ текста трека в полноэкранном плеере.
  bool trackLyricsEnabled = true;

  /// Указывает, что цвета плеера распространяются на всё приложение.
  bool playerColorsAppWide = false;

  /// Указывает, какая тема приложения используется.
  ThemeMode theme = ThemeMode.system;

  /// Указывает, что включена OLED тема приложения.
  bool oledTheme = false;

  /// Указывает поведение в случае закрытия приложения.
  AppCloseBehavior closeBehavior = AppCloseBehavior.close;

  /// Указывает, что приложение показывает предупреждение при попытке сохранить уже лайкнутый трек.
  bool checkBeforeFavorite = true;

  /// Указывает политику для автообновлений.
  UpdatePolicy updatePolicy = UpdatePolicy.dialog;

  /// Указывает ветку для автообновлений.
  UpdateBranch updateBranch = UpdateBranch.releasesOnly;
}

/// Provider для получения объекта пользователя в контексте интерфейса приложения.
///
/// Использование:
/// ```dart
/// final UserProvider user = Provider.of<UserProvider>(context, listen: false);
/// print(user.id);
/// ```
///
/// Если Вы хотите получить объект пользователя в контексте интерфейса Flutter, и хотите, что бы интерфейс сам обновлялся при изменении полей, то используйте следующий код:
/// ```dart
/// final UserProvider user = Provider.of<UserProvider>(context);
/// ...
/// Text(
///   "Ваш ID: ${user.id}"
/// )
/// ```
class UserProvider extends ChangeNotifier {
  /// Объект логгера для пользователя.
  static AppLogger logger = getLogger("UserProvider");

  /// Указывает, что данный пользователь авторизован в приложении при помощи основного токена (Kate Mobile).
  bool isAuthorized;

  /// Основной access-токен (Kate Mobile).
  ///
  /// Все запросы (кроме получения рекомендаций) делаются при помощи этого токена.
  String? mainToken;

  /// Вторичный access-токен (VK Admin).
  ///
  /// Используется для получения списка рекомендаций музыки.
  String? recommendationsToken;

  /// Указывает ID данного пользователя.
  int? id;

  /// Имя пользователя.
  String? firstName;

  /// Фамилия пользователя.
  String? lastName;

  /// Возвращает имя и фамилию пользователя.
  String? get fullName => isAuthorized ? "$firstName $lastName" : null;

  /// URL к квадратной фотографии с шириной в 50 пикселей.
  String? photo50Url;

  /// URL к квадратной фотографии с максимальным размером.
  String? photoMaxUrl;

  /// URL к изначальной фотографии с максимальным размером.
  String? photoMaxOrigUrl;

  /// Объект, перечисляющий все плейлисты пользователя.
  Map<String, ExtendedPlaylist> allPlaylists = {};

  /// Фейковый плейлист с "лайкнутыми" треками пользователя.
  ExtendedPlaylist? get favoritesPlaylist => allPlaylists["${id!}_0"];

  /// Перечисление всех обычных плейлистов, которые были сделаны данным пользователем.
  List<ExtendedPlaylist> get regularPlaylists => allPlaylists.values
      .where(
        (ExtendedPlaylist playlist) => playlist.isRegularPlaylist,
      )
      .toList();

  /// Перечисление всех "рекомендованных" плейлистов.
  List<ExtendedPlaylist> get recommendationPlaylists => allPlaylists.values
      .where(
        (ExtendedPlaylist playlist) => playlist.isRecommendationsPlaylist,
      )
      .toList();

  /// Перечисление всех плейлистов из раздела "Совпадения по вкусам".
  List<ExtendedPlaylist> get simillarPlaylists => allPlaylists.values
      .where(
        (ExtendedPlaylist playlist) => playlist.isSimillarPlaylist,
      )
      .toList();

  /// Перечисление всех плейлистов, которые были сделаны ВКонтакте (раздел "Собрано редакцией").
  List<ExtendedPlaylist> get madeByVKPlaylists => allPlaylists.values
      .where(
        (ExtendedPlaylist playlist) => playlist.isMadeByVKPlaylist,
      )
      .toList();

  /// Информация о количестве плейлистов пользователя.
  int? playlistsCount;

  /// Настройки пользователя.
  Settings settings = Settings();

  UserProvider(
    this.isAuthorized, {
    this.mainToken,
    this.recommendationsToken,
    this.id,
    this.firstName,
    this.lastName,
    this.photo50Url,
    this.photoMaxUrl,
    this.photoMaxOrigUrl,
  });

  /// Деавторизовывает данного пользователя, удаляя данные для авторизации с диска, а так же очищая из памяти лишние объекты.
  ///
  /// После данного вызова рекомендуется перекинуть пользователя на экран [WelcomeRoute].
  void logout() async {
    // Очищаем объект плеера.
    player.stop();

    // Очищаем все поля у пользователя.
    isAuthorized = false;
    mainToken = null;
    recommendationsToken = null;
    id = null;
    firstName = null;
    lastName = null;
    photo50Url = null;
    photoMaxUrl = null;
    photoMaxOrigUrl = null;
    playlistsCount = null;
    allPlaylists = {};

    // Удаляем сохранённые данные SharedPreferences.
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.clear();
    markUpdated(false);

    // Очищаем кэш изображений.
    await CachedNetworkImagesManager.instance.emptyCache();
    await CachedAlbumImagesManager.instance.emptyCache();

    // Удаляем кэшированные треки.
    Directory(
      await CachedStreamedAudio.getTrackStorageDirectory(),
    ).deleteSync(
      recursive: true,
    );
  }

  /// Сохраняет важные поля пользователя на диск.
  void saveToDisk() async {
    logger.d("saveToDisk call");

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Сохраняем состояние авторизованности пользователем.
    await prefs.setBool("IsAuthorized", isAuthorized);

    // Если мы не авторизованы, то ничего более сохранять не нужно.
    if (!isAuthorized) return;

    // Сохраняем остальные поля.
    await prefs.setString("Token", mainToken!);
    if (recommendationsToken != null) {
      await prefs.setString("RecommendationsToken", recommendationsToken!);
    }
    await prefs.setInt("ID", id!);
    await prefs.setString("FirstName", firstName!);
    await prefs.setString("LastName", lastName!);
    if (photo50Url != null) await prefs.setString("Photo50", photo50Url!);
    if (photoMaxUrl != null) await prefs.setString("PhotoMax", photoMaxUrl!);
    if (photoMaxOrigUrl != null) {
      await prefs.setString("PhotoMaxOrig", photoMaxOrigUrl!);
    }
    await prefs.setBool(
      "MyMusicChipEnabled",
      settings.myMusicChipEnabled,
    );
    await prefs.setBool(
      "PlaylistsChipEnabled",
      settings.playlistsChipEnabled,
    );
    await prefs.setBool(
      "RecommendedPlaylistsChipEnabled",
      settings.recommendedPlaylistsChipEnabled,
    );
    await prefs.setBool(
      "SimilarMusicChipEnabled",
      settings.similarMusicChipEnabled,
    );
    await prefs.setBool(
      "ByVKChipEnabled",
      settings.byVKChipEnabled,
    );
    await prefs.setBool(
      "ShuffleEnabled",
      settings.shuffleEnabled,
    );
    await prefs.setBool(
      "DiscordRPCEnabled",
      settings.discordRPCEnabled,
    );
    await prefs.setBool(
      "PauseOnMuteEnabled",
      settings.pauseOnMuteEnabled,
    );
    await prefs.setBool(
      "PlayerThumbAsBackground",
      settings.playerThumbAsBackground,
    );
    await prefs.setBool(
      "TrackLyricsEnabled",
      settings.trackLyricsEnabled,
    );
    await prefs.setBool(
      "PlayerColorsAppWide",
      settings.playerColorsAppWide,
    );
    await prefs.setInt(
      "Theme",
      settings.theme.index,
    );
    await prefs.setBool(
      "OLEDTheme",
      settings.oledTheme,
    );
    await prefs.setInt(
      "CloseBehavior",
      settings.closeBehavior.index,
    );
    await prefs.setBool(
      "CheckBeforeFavorite",
      settings.checkBeforeFavorite,
    );
    await prefs.setInt(
      "UpdatePolicy",
      settings.updatePolicy.index,
    );
    await prefs.setInt(
      "UpdateBranch",
      settings.updateBranch.index,
    );
  }

  /// Загружает данный объект пользователя с диска.
  ///
  /// Возвращает значение переменной [isAuthorized].
  Future<bool> loadFromDisk() async {
    logger.d("loadFromDisk call");

    SharedPreferences prefs = await SharedPreferences.getInstance();

    isAuthorized = (prefs.getBool("IsAuthorized")) ?? false;
    if (!isAuthorized) return false;

    mainToken = prefs.getString("Token");
    recommendationsToken = prefs.getString("RecommendationsToken");
    id = prefs.getInt("ID");
    firstName = prefs.getString("FirstName");
    lastName = prefs.getString("LastName");
    photo50Url = prefs.getString("Photo50");
    photoMaxUrl = prefs.getString("PhotoMax");
    photoMaxOrigUrl = prefs.getString("PhotoMaxOrig");
    settings.myMusicChipEnabled = prefs.getBool("MyMusicChipEnabled") ?? true;
    settings.playlistsChipEnabled =
        prefs.getBool("PlaylistsChipEnabled") ?? true;
    settings.recommendedPlaylistsChipEnabled =
        prefs.getBool("RecommendedPlaylistsChipEnabled") ?? true;
    settings.similarMusicChipEnabled =
        prefs.getBool("SimilarMusicChipEnabled") ?? true;
    settings.byVKChipEnabled = prefs.getBool("ByVKChipEnabled") ?? true;
    settings.shuffleEnabled = prefs.getBool("ShuffleEnabled") ?? false;
    settings.discordRPCEnabled = prefs.getBool("DiscordRPCEnabled") ?? true;
    settings.pauseOnMuteEnabled = prefs.getBool("PauseOnMuteEnabled") ?? false;
    settings.playerThumbAsBackground =
        prefs.getBool("PlayerThumbAsBackground") ?? true;
    settings.trackLyricsEnabled = prefs.getBool("TrackLyricsEnabled") ?? true;
    settings.playerColorsAppWide =
        prefs.getBool("PlayerColorsAppWide") ?? false;
    settings.theme = ThemeMode.values[prefs.getInt("Theme") ?? 0];
    settings.oledTheme = prefs.getBool("OLEDTheme") ?? false;
    settings.closeBehavior =
        AppCloseBehavior.values[prefs.getInt("CloseBehavior") ?? 0];
    settings.checkBeforeFavorite = prefs.getBool("CheckBeforeFavorite") ?? true;
    settings.updatePolicy =
        UpdatePolicy.values[prefs.getInt("UpdatePolicy") ?? 0];
    settings.updateBranch =
        UpdateBranch.values[prefs.getInt("UpdateBranch") ?? 0];

    markUpdated(false);

    return isAuthorized;
  }

  /// Помечает данный объект пользователя как обновлённый, заставляя Flutter перестроить ту часть интерфейса, где используется информация о данном пользователе.
  ///
  /// Данный метод рекомендуется вызывать только после всех манипуляций и изменений над данным классом (т.е., вызывать его множество раз не рекомендуется).
  ///
  /// [dumpData] указывает, будут ли данные в объекте данного пользователя сериализированы и сохранены на диск.
  void markUpdated([bool dumpData = true]) {
    notifyListeners();

    if (dumpData) saveToDisk();
  }

  /// Вставляет в [allPlaylists] указанный плейлист [playlists], объеденяя старые и новые поля. Если плейлист не существовал ранее, то он будет создан. [saveToDB] указывает, будет ли изменение сохранено в БД Isar.
  void updatePlaylist(
    ExtendedPlaylist playlist, {
    bool saveToDB = true,
  }) async {
    ExtendedPlaylist? existingPlaylist = allPlaylists[playlist.mediaKey];

    if (existingPlaylist == null) {
      // Ранее такового плейлиста не было, просто сохраняем и ничего не делаем.

      existingPlaylist = playlist;
    } else {
      // Мы должны сделать объединение полей из старого и нового плейлиста.

      existingPlaylist.count = playlist.count;
      existingPlaylist.title = playlist.title;
      existingPlaylist.description = playlist.description;
      existingPlaylist.subtitle = playlist.subtitle;
      existingPlaylist.cacheTracks =
          playlist.cacheTracks ?? existingPlaylist.cacheTracks;
      existingPlaylist.createTime = playlist.createTime;
      existingPlaylist.updateTime = playlist.updateTime;
      existingPlaylist.followers = playlist.followers;
      existingPlaylist.isLiveData = playlist.isLiveData;
      existingPlaylist.areTracksLive = playlist.areTracksLive;

      // Проходимся по новому списку треков, если он вообще был передан.
      if (playlist.audios != null) {
        // Создаём отдельный List с shadow copy списка треков.
        final List<ExtendedAudio> newAudios = [...playlist.audios!];
        final Set<ExtendedAudio> oldAudios = existingPlaylist.audios ?? {};
        existingPlaylist.audios = {};

        for (ExtendedAudio audio in newAudios) {
          ExtendedAudio newAudio =
              oldAudios.firstWhereOrNull((oldAudio) => oldAudio == audio) ??
                  audio;

          newAudio.url ??= audio.url;
          newAudio.isCached = audio.isCached ?? newAudio.isCached;
          newAudio.album ??= audio.album;

          existingPlaylist.audios!.add(newAudio);
        }

        // Проходимся по тому списку треков, которые кэшированы, но больше нет в плейлисте.
        final Set<ExtendedAudio> removedAudios = oldAudios
            .where(
              (audio) =>
                  (audio.isCached ?? false) &&
                  !existingPlaylist!.audios!.contains(audio),
            )
            .toSet();

        for (ExtendedAudio audio in removedAudios) {
          logger.d("Audio $audio will be deleted");

          // Удаляем трек из кэша.
          try {
            CachedStreamedAudio(cacheKey: audio.mediaKey).delete();

            audio.isCached = false;
          } catch (e) {
            // No-op.
          }
        }
      }
    }

    allPlaylists[playlist.mediaKey] = existingPlaylist;

    if (saveToDB) {
      await appStorage.savePlaylists(
        allPlaylists.values
            .map(
              (playlist) => playlist.asDBPlaylist,
            )
            .toList(),
      );
    }
  }

  /// Вставляет в [allPlaylists] указанный список из плейлистов [playlists], объеденяя старые и новые поля. Если какой то из плейлистов [playlists] не существовал ранее, то он будет создан. [saveToDB] указывает, будет ли изменение сохранено в БД Isar.
  void updatePlaylists(
    List<ExtendedPlaylist> playlists, {
    bool saveToDB = true,
  }) async {
    for (ExtendedPlaylist playlist in playlists) {
      updatePlaylist(
        playlist,
        saveToDB: false,
      );
    }

    if (saveToDB) {
      await appStorage.savePlaylists(
        allPlaylists.values
            .map(
              (playlist) => playlist.asDBPlaylist,
            )
            .toList(),
      );
    }
  }

  /// Получает публичную информацию о пользователях с передаваемым ID, либо же о владельце текущей страницы, если ID не передаётся.
  Future<APIUsersGetResponse> usersGet({
    List<int>? userIDs,
    String? fields = vkAPIallUserFields,
  }) async =>
      await users_get(
        mainToken!,
        userIDs: userIDs,
        fields: fields,
      );

  /// Возвращает информацию об аудиофайлах пользователя или сообщества.
  ///
  /// API: `audio.get`.
  Future<APIAudioGetResponse> audioGet(
    int userID,
  ) async =>
      audio_get(
        mainToken!,
        userID,
      );

  /// Возвращает информацию о аудио плейлистах указанного пользователя.
  ///
  /// API: `audio.getPlaylists`.
  Future<APIAudioGetPlaylistsResponse> audioGetPlaylists(
    int userID,
  ) async =>
      audio_getPlaylists(
        mainToken!,
        userID,
      );

  /// Копирует трек с указанным ID к данному пользователю, передавая относительный для данного пользователя сохранённый ID трека.
  ///
  /// API: `audio.add`.
  Future<APIAudioAddResponse> audioAdd(
    int audioID,
    int ownerID,
  ) async =>
      audio_add(
        mainToken!,
        audioID,
        ownerID,
      );

  /// Удаляет трек из лайкнутых.
  ///
  /// API: `audio.delete`.
  Future<APIAudioDeleteResponse> audioDelete(
    int audioID,
    int ownerID,
  ) async =>
      audio_delete(
        mainToken!,
        audioID,
        ownerID,
      );

  /// Восстанавливает трек по его ID, после удаления, вызванного методом [audioDelete].
  ///
  /// API: `audio.restore`.
  Future<APIAudioRestoreResponse> audioRestore(
    int audioID, {
    int? ownerID,
  }) async =>
      audio_restore(
        mainToken!,
        audioID,
        ownerID ?? id!,
      );

  /// Модифицирует параметры трека: его название ([title]) и/ли исполнителя ([artist]).
  ///
  /// API: `audio.edit`.
  Future<APIAudioEditResponse> audioEdit(
    int ownerID,
    int audioID,
    String title,
    String artist,
    int genreID,
  ) async =>
      await audio_edit(
        mainToken!,
        ownerID,
        audioID,
        title,
        artist,
        genreID,
      );

  /// Возвращает текст песни (lyrics) у трека по его передаваемому ID ([Audio.mediaKey]).
  ///
  /// API: `audio.getLyrics`.
  Future<APIAudioGetLyricsResponse> audioGetLyrics(
    String audioID,
  ) async =>
      await audio_get_lyrics(
        mainToken!,
        audioID,
      );

  /// Ищет треки во ВКонтакте по их названию.
  ///
  /// API: `audio.search`.
  Future<APIAudioSearchResponse> audioSearch(
    String query, {
    bool autoComplete = true,
    int count = 50,
    int offset = 0,
  }) async =>
      await audio_search(
        mainToken!,
        query,
        autoComplete: autoComplete,
        count: count,
        offset: offset,
      );

  /// Ищет треки во ВКонтакте по их названию, дополняя информацию о треках альбомами.
  ///
  /// Требуется токен от Kate Mobile и VK Admin.
  Future<APIAudioSearchResponse> audioSearchWithAlbums(
    String query, {
    bool autoComplete = true,
    int count = 50,
    int offset = 0,
  }) async {
    final APIAudioSearchResponse response = await audio_search(
      mainToken!,
      query,
      autoComplete: autoComplete,
      count: count,
      offset: offset,
    );

    if (response.error != null) return response;

    // Если у пользователя есть токен VK Admin, то тогда нам нужно получить расширенную информацию о треках.
    if (recommendationsToken != null) {
      // Получаем MediaKey треков, делая в запросе не более 200 ключей.
      List<String> audioIDs = [];
      List<Audio> audios = response.response!.items;

      for (int i = 0; i < audios.length; i += 200) {
        int endIndex = i + 200;
        List<Audio> batch = audios.sublist(
          i,
          endIndex.clamp(
            0,
            audios.length,
          ),
        );
        List<String> currentMediaKey =
            batch.map((audio) => audio.mediaKey).toList();

        audioIDs.add(currentMediaKey.join(","));
      }

      final APIMassAudioAlbumsResponse massAlbums =
          await scriptMassAudioAlbums(audioIDs);

      if (massAlbums.error != null) {
        // В случае ошибки создаём копию ответа от первого шага, изменяя там поле error.
        return APIAudioSearchResponse(
          response: response.response,
          error: massAlbums.error,
        );
      }

      // Всё ок, объеденяем данные, что бы у объекта Audio (с первого запроса) была информация о альбомах.

      // Создаём Map, где ключ - медиа ключ доступа, а значение - объект мини-альбома.
      //
      // Использовать массив - идея плохая, поскольку ВКонтакте не возвращает информацию по "недоступным" трекам,
      // ввиду чего происходит смещение, что не очень-то и хорошо.
      Map<String, Audio> albumsData = {
        for (var album in massAlbums.response!) album.mediaKey: album,
      };

      // Мы получили список альбомов, обновляем существующий массив треков.
      for (Audio audio in audios) {
        if (audio.album != null) continue;
        final Audio? extendedAudio = albumsData[audio.mediaKey];

        // Если у нас нет информации по альбому этого трека, то ничего не делаем.
        if (extendedAudio == null || extendedAudio.album == null) continue;

        // Всё ок, заменяем данные в аудио.
        audio.album = extendedAudio.album;
      }
    }

    return response;
  }

  /// Возвращает информацию о категории для раздела "аудио".
  ///
  /// API: `catalog.getAudio`.
  Future<APICatalogGetAudioResponse> catalogGetAudio() async =>
      await catalog_getAudio(
        recommendationsToken!,
      );

  /// Массово извлекает список треков ВКонтакте. Максимум извлекает около 5000 треков.
  ///
  /// Для данного метода требуется токен от Kate Mobile.
  Future<APIMassAudioGetResponse> scriptMassAudioGet(
    int userID, {
    int? albumID,
    String? accessKey,
  }) async =>
      await scripts_massAudioGet(
        mainToken!,
        userID,
        albumID: albumID,
        accessKey: accessKey,
      );

  /// Массово извлекает информацию по альбомам (и, соответственно, изображениям) треков по переданным ID треков.
  ///
  /// Для данного метода требуется токен от VK Admin.
  Future<APIMassAudioAlbumsResponse> scriptMassAudioAlbums(
    List<String> audioMediaIDs,
  ) async =>
      await scripts_massAlbumsGet(
        recommendationsToken!,
        audioMediaIDs,
      );

  /// Извлекает <200 лайкнутых треков, а так же <50 плейлистов пользователя.
  ///
  /// Для данного метода требуется токен от Kate Mobile.
  Future<APIAudioGetDataResponse> scriptGetFavAudioAndPlaylists(
    int userID,
  ) async =>
      await scripts_getFavAudioAndPlaylists(
        mainToken!,
        userID,
      );

  /// Массово извлекает список треков ВКонтакте (до 5000 штук), а так же дополняет выходной объект информацией об альбомах этих треков.
  ///
  /// Для данного метода требуется токен от Kate Mobile, а для дополнительной информации по альбомам должен быть токен от VK Admin.
  Future<APIMassAudioGetResponse> scriptMassAudioGetWithAlbums(
    int ownerID, {
    int? albumID,
    String? accessKey,
  }) async {
    final APIMassAudioGetResponse massAudios = await scripts_massAudioGet(
      mainToken!,
      ownerID,
      albumID: albumID,
      accessKey: accessKey,
    );

    if (massAudios.error != null) return massAudios;

    // Если у пользователя есть токен VK Admin, то тогда нам нужно получить расширенную информацию о треках.
    try {
      if (recommendationsToken != null) {
        // Получаем MediaKey треков, делая в запросе не более 200 ключей.
        List<String> audioIDs = [];
        List<Audio> audios = massAudios.response!.audios;

        for (int i = 0; i < audios.length; i += 200) {
          int endIndex = i + 200;
          List<Audio> batch = audios.sublist(
            i,
            endIndex.clamp(
              0,
              audios.length,
            ),
          );
          List<String> currentMediaKey =
              batch.map((audio) => audio.mediaKey).toList();

          audioIDs.add(currentMediaKey.join(","));
        }

        final APIMassAudioAlbumsResponse massAlbums =
            await scriptMassAudioAlbums(audioIDs);

        if (massAlbums.error != null) {
          // В случае ошибки создаём копию ответа от первого шага, изменяя там поле error.
          return APIMassAudioGetResponse(
            response: massAudios.response,
            error: massAlbums.error,
          );
        }

        // Всё ок, объеденяем данные, что бы у объекта Audio (с первого запроса) была информация о альбомах.

        // Создаём Map, где ключ - медиа ключ доступа, а значение - объект мини-альбома.
        //
        // Использовать массив - идея плохая, поскольку ВКонтакте не возвращает информацию по "недоступным" трекам,
        // ввиду чего происходит смещение, что не очень-то и хорошо.
        Map<String, Audio> albumsData = {
          for (var album in massAlbums.response!) album.mediaKey: album,
        };

        // Мы получили список альбомов, обновляем существующий массив треков.
        for (Audio audio in audios) {
          if (audio.album != null) continue;
          final Audio? extendedAudio = albumsData[audio.mediaKey];

          // Если у нас нет информации по альбому этого трека, то ничего не делаем.
          if (extendedAudio == null || extendedAudio.album == null) continue;

          // Всё ок, заменяем данные в аудио.
          audio.album = extendedAudio.album;
        }
      }
    } catch (e, stackTrace) {
      logger.w(
        "Не удалось получить список альбомов:",
        error: e,
        stackTrace: stackTrace,
      );
    }

    return massAudios;
  }
}
