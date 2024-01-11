import "package:flutter/material.dart";
import "package:flutter_cache_manager/flutter_cache_manager.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../api/audio/edit.dart";
import "../api/audio/get.dart";
import "../api/audio/get_playlists.dart";
import "../api/catalog/get_audio.dart";
import "../api/executeScripts/audio_get_data.dart";
import "../api/executeScripts/mass_audio_albums.dart";
import "../api/executeScripts/mass_audio_get.dart";
import "../api/shared.dart";
import "../api/users/get.dart";
import "../consts.dart";
import "../main.dart";
import "../services/logger.dart";

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

  /// Массив с треками пользователя, полученными с API ВКонтакте.
  List<Audio>? audios;

  /// Информация о количестве треков пользователя.
  int? audioCount;

  /// Массив с плейлистами пользователя, полученными с API ВКонтакте.
  List<AudioPlaylist>? playlists;

  /// Информация о количестве плейлистов пользователя.
  int? playlistsCount;

  /// Массив с плейлистами, находящимися в разделе "Плейлисты для Вас".
  List<AudioPlaylist>? recommendationPlaylists;

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
    player.dispose();

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
    audios = null;
    audioCount = null;
    playlists = null;
    playlistsCount = null;
    recommendationPlaylists = null;

    // Удаляем сохранённые данные SharedPreferences.
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.clear();
    markUpdated(false);

    // Очищаем кэш.
    await DefaultCacheManager().emptyCache();
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

  /// Модифицирует параметры трека: его название ([title]) и/ли исполнителя ([artist]).
  ///
  /// API: `audio.edit`.
  Future<APIAudioEditResponse> audioEdit(
    int ownerID,
    int audioID,
    String title,
    String artist,
  ) async =>
      await audio_edit(
        mainToken!,
        ownerID,
        audioID,
        title,
        artist,
      );

  /// Возвращает информацию о категории для раздела "аудио".
  ///
  /// API: `catalog.getAudio`.
  Future<APICatalogGetAudioResponse> catalogGetAudio() async =>
      await catalog_getAudio(
        recommendationsToken!,
      );

  /// Массово извлекает список  треков ВКонтакте. Максимум извлекает около 5000 треков.
  ///
  /// Для данного метода требуется токен от Kate Mobile.
  Future<APIMassAudioGetResponse> scriptMassAudioGet(
    int userID, {
    int? albumID,
  }) async =>
      await scripts_massAudioGet(
        mainToken!,
        userID,
        albumID: albumID,
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
    int userID, {
    int? albumID,
  }) async {
    final APIMassAudioGetResponse massAudios = await scripts_massAudioGet(
      mainToken!,
      userID,
      albumID: albumID,
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
