import "package:audio_service/audio_service.dart";
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
import "../enums.dart";
import "../main.dart";
import "../services/cache_manager.dart";
import "../services/logger.dart";
import "../utils.dart";

/// Класс, расширяющий обычный объект [AudioPlaylist] от API ВКонтакте, добавляющий информацию о треках в данном плейлисте.
class ExtendedVKPlaylist extends AudioPlaylist {
  /// Список из аудио в данном плейлисте.
  List<ExtendedVKAudio>? audios;

  /// Указывает, что данный плейлист является плейлистом с "любимыми" треками пользователя.
  bool get isFavoritesPlaylist => id == 0;

  /// Указывает, что данный плейлист является обычным плейлистом пользователя, который он либо создал либо сохранил.
  bool get isRegularPlaylist => id > 0 && ownerID != vkMusicGroupID;

  /// Указывает, что данный плейлист является плейлистом из рекомендаций.
  bool get isRecommendationsPlaylist => id < 0;

  /// Указывает, что данный плейлист является плейлистом от ВКонтакте (плейлист из раздела "Собрано редакцией")
  bool get isMadeByVKPlaylist => ownerID == vkMusicGroupID;

  /// Указывает, пуст ли данный плейлист. Данный метод всегда возвращает true, если треки не были загружены.
  bool get isEmpty => audios == null ? true : count == 0;

  /// Возвращает instance данного класса из передаваемого объекта типа [AudioPlaylist].
  static ExtendedVKPlaylist fromAudioPlaylist(
    AudioPlaylist playlist, {
    List<ExtendedVKAudio>? audios,
    int? totalAudios,
  }) =>
      ExtendedVKPlaylist(
        id: playlist.id,
        ownerID: playlist.ownerID,
        type: playlist.type,
        title: playlist.title,
        description: playlist.description,
        count: playlist.count,
        accessKey: playlist.accessKey,
        followers: playlist.followers,
        plays: playlist.plays,
        createTime: playlist.createTime,
        updateTime: playlist.updateTime,
        isFollowing: playlist.isFollowing,
        subtitleBadge: playlist.subtitleBadge,
        playButton: playlist.playButton,
        albumType: playlist.albumType,
        exclusive: playlist.exclusive,
        subtitle: playlist.subtitle,
        genres: playlist.genres,
        photo: playlist.photo,
        permissions: playlist.permissions,
        meta: playlist.meta,
        audios: audios,
      );

  ExtendedVKPlaylist({
    required super.id,
    required super.ownerID,
    super.type,
    super.title,
    super.description,
    required super.count,
    super.accessKey,
    super.followers,
    super.plays,
    super.createTime,
    super.updateTime,
    super.isFollowing,
    super.subtitleBadge,
    super.playButton,
    super.albumType,
    super.exclusive,
    super.subtitle,
    super.genres,
    super.photo,
    super.permissions,
    super.meta,
    this.audios,
  });
}

/// Класс, расширяющий объект [Audio] от API ВКонтакте, добавляя некоторые новые поля.
class ExtendedVKAudio extends Audio {
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

  /// Возвращает данный объект как [MediaItem] для аудио плеера.
  MediaItem get asMediaItem => MediaItem(
        id: mediaKey,
        title: title,
        album: album?.title,
        artist: artist,
        artUri: album?.thumb != null
            ? Uri.parse(
                album!.thumb!.photo!,
              )
            : null,
        duration: Duration(
          seconds: duration,
        ),
      );

  @override
  bool operator ==(covariant Audio other) {
    if (identical(this, other)) return true;

    return other.runtimeType == ExtendedVKAudio && other.mediaKey == mediaKey;
  }

  @override
  int get hashCode => mediaKey.hashCode;

  ExtendedVKAudio({
    required super.id,
    required super.ownerID,
    required super.artist,
    required super.title,
    required super.duration,
    super.subtitle,
    required super.accessKey,
    super.ads,
    super.isExplicit = false,
    super.isFocusTrack,
    super.isLicensed,
    super.isRestricted = false,
    super.shortVideosAllowed,
    super.storiesAllowed,
    super.storiesCoverAllowed,
    super.trackCode,
    required super.url,
    required super.date,
    super.album,
    super.hasLyrics,
    super.albumID,
    super.genreID,
    this.lyrics,
    this.isLiked = false,
  });

  /// Возвращает instance данного класса из передаваемого объекта типа [Audio].
  static ExtendedVKAudio fromAudio(
    Audio audio, {
    Lyrics? lyrics,
    bool? isLiked,
  }) =>
      ExtendedVKAudio(
        id: audio.id,
        ownerID: audio.ownerID,
        artist: audio.artist,
        title: audio.title,
        duration: audio.duration,
        subtitle: audio.subtitle,
        accessKey: audio.accessKey,
        ads: audio.ads,
        isExplicit: audio.isExplicit,
        isFocusTrack: audio.isFocusTrack,
        isLicensed: audio.isLicensed,
        isRestricted: audio.isRestricted,
        shortVideosAllowed: audio.shortVideosAllowed,
        storiesAllowed: audio.storiesAllowed,
        storiesCoverAllowed: audio.storiesCoverAllowed,
        trackCode: audio.trackCode,
        url: audio.url,
        date: audio.date,
        album: audio.album,
        hasLyrics: audio.hasLyrics,
        albumID: audio.albumID,
        genreID: audio.genreID,
        lyrics: lyrics,
        isLiked: isLiked ?? false,
      );
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
  final AppLogger logger = getLogger("UserProvider");

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
  Map<int, ExtendedVKPlaylist> allPlaylists = {};

  /// Плейлист с "лайкнутыми" треками пользователя.
  ///
  /// Тоже самое, что и `allPlaylists[0]`.
  ExtendedVKPlaylist? get favoritesPlaylist => allPlaylists[0];

  List<String>? _favoriteMediaKeys;

  /// Список из [Audio.mediaKey] лайкнутых треков.
  List<String> get favoriteMediaKeys {
    _favoriteMediaKeys ??=
        favoritesPlaylist != null && favoritesPlaylist!.audios != null
            ? favoritesPlaylist!.audios!
                .where((ExtendedVKAudio audio) => audio.isLiked)
                .map((ExtendedVKAudio audio) => audio.mediaKey)
                .toList()
            : [];

    return _favoriteMediaKeys!;
  }

  /// Сбрасывает список из [Audio.mediaKey] у [favoriteMediaKeys].
  ///
  /// Данный вызов стоит совершать только если поменялся список лайкнутых треков.
  void resetFavoriteMediaKeys() => _favoriteMediaKeys = null;

  /// Перечисление всех обычных плейлистов, которые были сделаны данным пользователем.
  List<ExtendedVKPlaylist> get regularPlaylists => allPlaylists.values
      .where(
        (ExtendedVKPlaylist playlist) => playlist.isRegularPlaylist,
      )
      .toList();

  /// Перечисление всех "рекомендованных" плейлистов.
  List<ExtendedVKPlaylist> get recommendationPlaylists => allPlaylists.values
      .where(
        (ExtendedVKPlaylist playlist) => playlist.isRecommendationsPlaylist,
      )
      .toList();

  /// Перечисление всех плейлистов, которые были сделаны ВКонтакте (раздел "Собрано редакцией").
  List<ExtendedVKPlaylist> get madeByVKPlaylists => allPlaylists.values
      .where(
        (ExtendedVKPlaylist playlist) => playlist.isMadeByVKPlaylist,
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

    // Очищаем кэш.
    await CachedNetworkImagesManager.instance.emptyCache();
    await VKMusicCacheManager.instance.emptyCache();
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
          response.response,
          massAlbums.error,
        );
      }

      // Всё ок, объеденяем данные, что бы у объекта Audio (с первого запроса) была информация о альбомах.

      // Создаём Map, где ключ - медиа ключ доступа, а значение - объект мини-альбома.
      //
      // Использовать массив - идея плохая, поскольку ВКонтакте не возвращает информацию по "недоступным" трекам,
      // ввиду чего происходит смещение, что не очень-то и хорошо.
      Map<String, Audio> albumsData = {
        for (var album in massAlbums.response!) album.mediaKey: album
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
          massAudios.response,
          massAlbums.error,
        );
      }

      // Всё ок, объеденяем данные, что бы у объекта Audio (с первого запроса) была информация о альбомах.

      // Создаём Map, где ключ - медиа ключ доступа, а значение - объект мини-альбома.
      //
      // Использовать массив - идея плохая, поскольку ВКонтакте не возвращает информацию по "недоступным" трекам,
      // ввиду чего происходит смещение, что не очень-то и хорошо.
      Map<String, Audio> albumsData = {
        for (var album in massAlbums.response!) album.mediaKey: album
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

    return massAudios;
  }
}
