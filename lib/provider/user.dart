import "package:audio_service/audio_service.dart";
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../api/deezer/shared.dart";
import "../api/vk/audio/add.dart";
import "../api/vk/audio/add_dislike.dart";
import "../api/vk/audio/delete.dart";
import "../api/vk/audio/edit.dart";
import "../api/vk/audio/get.dart";
import "../api/vk/audio/get_lyrics.dart";
import "../api/vk/audio/get_playlists.dart";
import "../api/vk/audio/get_stream_mix_audios.dart";
import "../api/vk/audio/restore.dart";
import "../api/vk/audio/search.dart";
import "../api/vk/audio/send_start_event.dart";
import "../api/vk/catalog/get_audio.dart";
import "../api/vk/consts.dart";
import "../api/vk/executeScripts/audio_get_data.dart";
import "../api/vk/executeScripts/mass_audio_albums.dart";
import "../api/vk/executeScripts/mass_audio_get.dart";
import "../api/vk/shared.dart";
import "../api/vk/users/get.dart";
import "../db/schemas/playlists.dart";
import "../main.dart";
import "../utils.dart";
import "auth.dart";
import "shared_prefs.dart";

part "user.g.dart";

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
  List<ExtendedAudio>? audios;

  /// Указывает, что данный плейлист является плейлистом с "любимыми" треками пользователя.
  bool get isFavoritesPlaylist => id == 0;

  /// Указывает, что данный плейлист является обычным плейлистом пользователя, который он либо создал либо сохранил.
  bool get isRegularPlaylist =>
      id > 0 &&
      ownerID != vkMusicGroupID &&
      !isSimillarPlaylist &&
      !isMoodPlaylist &&
      !isAudioMixPlaylist;

  /// Указывает, что данный плейлист является плейлистом из раздела "Какой сейчас вайб?" ВКонтакте.
  final bool isMoodPlaylist;

  /// Указывает, что данный плейлист является фейковым плейлистом, олицетворяющий аудио микс ВКонтакте.
  final bool isAudioMixPlaylist;

  /// Указывает, что данный плейлист является плейлистом из рекомендаций.
  bool get isRecommendationsPlaylist => id < 0 && !isMoodPlaylist;

  /// Указывает, что данный плейлист является плейлистом из раздела "Совпадения по вкусам".
  bool get isSimillarPlaylist => simillarity != null;

  /// Указывает, что данный плейлист является плейлистом от ВКонтакте (плейлист из раздела "Собрано редакцией")
  bool get isMadeByVKPlaylist => ownerID == vkMusicGroupID;

  /// Указывает, пуст ли данный плейлист. Данный метод всегда возвращает true, если треки не были загружены.
  bool get isEmpty => audios == null ? true : count == 0;

  /// Указывает, что этот плейлист является плейлистом любого рекомендательного типа.
  bool get isRecommendationTypePlaylist =>
      isRecommendationsPlaylist ||
      isSimillarPlaylist ||
      isMoodPlaylist ||
      isAudioMixPlaylist ||
      isMadeByVKPlaylist;

  /// Указывает процент "схожести" данного плейлиста. Данное поле не-null только для плейлистов из раздела "совпадения по вкусам".
  final double? simillarity;

  /// Указывает Hex-цвет для данного плейлиста. Данное поле не-null только для плейлистов из раздела "совпадения по вкусам".
  final String? color;

  /// Указывает первые 3 известных трека для данного плейлиста. Данное поле не-null только для плейлистов из раздела "совпадения по вкусам".
  final List<ExtendedAudio>? knownTracks;

  /// ID данного аудио микса. Данное поле не-null только для аудио микс-плейлистов.
  final String? mixID;

  /// URL на Lottie-анимацию, которая используется как фон данного микса. Данное поле не-null только для аудио микс-плейлистов.
  String? backgroundAnimationUrl;

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
    List<ExtendedAudio>? audios,
    int? totalAudios,
    bool isMoodPlaylist = false,
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
        isMoodPlaylist: isMoodPlaylist,
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
            .toList(),
        isMoodPlaylist: playlist.isMoodPlaylist ?? false,
        isAudioMixPlaylist: playlist.isAudioMixPlaylist ?? false,
        mixID: playlist.mixID,
        backgroundAnimationUrl: playlist.backgroundAnimationUrl,
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

    return other.runtimeType == ExtendedPlaylist &&
        other.id == id &&
        other.ownerID == ownerID &&
        other.isDataCached == isDataCached &&
        other.areTracksCached == areTracksCached;
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
    this.isMoodPlaylist = false,
    this.isAudioMixPlaylist = false,
    this.simillarity,
    this.color,
    this.knownTracks,
    this.mixID,
    this.backgroundAnimationUrl,
    this.isLiveData = false,
    this.areTracksLive = false,
    this.cacheTracks,
  });
}

/// Класс, выступающий в роли упрощённой версии класса [Thumbnails].
class ExtendedThumbnail {
  /// URL на изображение альбома самого маленького размера. Рекомендуется использовать там, где нужно самое маленькое изображение трека: в списке треков, миниплеере и так далее.
  ///
  /// Размеры изображений, в зависимости от источника:
  /// - ВКонтакте: `68x68`.
  /// - Deezer: `56x56`.
  final String photoSmall;

  /// URL на изображение альбома среднего размера.
  ///
  /// Размеры изображений, в зависимости от источника:
  /// - ВКонтакте: `270x270`.
  /// - Deezer: `250x250`.
  final String photoMedium;

  /// URL на изображение альбома большого размера.
  ///
  /// Размеры изображений, в зависимости от источника:
  /// - ВКонтакте: `600x600`.
  /// - Deezer: `500x500`.
  final String photoBig;

  /// URL на изображение альбома самого большого размера из всех. Именно это изображение имеет самое высокое качество, и поэтому его рекомендуется использовать в полноэкранном плеере.
  ///
  /// Размеры изображений, в зависимости от источника:
  /// - ВКонтакте: `1200x1200`.
  /// - Deezer: `1000x1000`.
  final String photoMax;

  /// Создаёт из передаваемого объекта [DBExtendedThumbnail] объект данного класа.
  static ExtendedThumbnail fromDBExtendedThumbnail(
    DBExtendedThumbnail thumbnail,
  ) =>
      ExtendedThumbnail(
        photoSmall: thumbnail.photoSmall!,
        photoMedium: thumbnail.photoMedium!,
        photoBig: thumbnail.photoBig!,
        photoMax: thumbnail.photoMax!,
      );

  /// Возвращает копию данного класса в виде объекта [DBExtendedThumbnail].
  DBExtendedThumbnail get asDBExtendedThumbnail =>
      DBExtendedThumbnail.fromExtendedThumbnail(this);

  /// Создаёт из передаваемого объекта [Thumbnails] объект данного класа.
  static ExtendedThumbnail fromThumbnail(Thumbnails thumbnails) =>
      ExtendedThumbnail(
        photoSmall: thumbnails.photo68!,
        photoMedium: thumbnails.photo270!,
        photoBig: thumbnails.photo600!,
        photoMax: thumbnails.photo1200!,
      );

  /// Создаёт из передаваемого объекта [DeezerTrack] объект данного класса.
  static ExtendedThumbnail fromDeezerTrack(DeezerTrack track) =>
      ExtendedThumbnail(
        photoSmall: track.album.coverSmall!,
        photoMedium: track.album.coverMedium!,
        photoBig: track.album.coverBig!,
        photoMax: track.album.coverXL!,
      );

  @override
  String toString() => "DBExtendedThumbnails";

  ExtendedThumbnail({
    required this.photoSmall,
    required this.photoMedium,
    required this.photoBig,
    required this.photoMax,
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

  /// Информация об обложке данного трека, полученного с ВКонтакте.
  ExtendedThumbnail? vkThumbs;

  /// Информация об обложке данного трека, полученного с Deezer.
  ExtendedThumbnail? deezerThumbs;

  /// Возвращает объект типа [ExtendedThumbnail], берущий значение с переменной [vkThumbs] или [deezerThumbs].
  ExtendedThumbnail? get thumbnail => vkThumbs ?? deezerThumbs;

  /// Возвращает URL самой маленькой обложки ([ExtendedThumbnail.photoSmall]) из переменной [vkThumbs] либо [deezerThumbs].
  String? get smallestThumbnail => thumbnail?.photoSmall;

  /// Возвращает URL самой большой обложки ([ExtendedThumbnail.photoMax]) из переменной [vkThumbs] либо [deezerThumbs].
  String? get maxThumbnail => thumbnail?.photoMax;

  /// Указывает наличие текста песни.
  bool? hasLyrics;

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

  /// Указывает, возможно ли воспроизвести данный трек. Данное поле проверяет наличие интернета и существование Url на mp3 файл, либо же то, что трек кэширован.
  bool get canPlay =>
      (isCached ?? false) || (connectivityManager.hasConnection && url != null);

  /// [ValueNotifier] для указания прогресса загрузки трека этого трека.
  ///
  /// Указывает значение от 0.0 до 1.0.
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);

  /// Возвращает данный объект как [MediaItem] для аудио плеера.
  MediaItem get asMediaItem {
    final String mediaTitle = subtitle != null ? "$title ($subtitle)" : title;
    final String mediaArtist = isExplicit ? "🅴 $artist" : artist;
    final String? mediaAlbum = album?.title;
    final Uri? mediaArtUri =
        maxThumbnail != null ? Uri.parse(maxThumbnail!) : null;
    final Duration mediaDuration = Duration(
      seconds: duration,
    );
    final Map<String, dynamic> mediaExtras = {
      "albumID": album?.id,
      "mediaKey": mediaKey,
    };

    return MediaItem(
      id: mediaKey,
      title: mediaTitle,
      artist: mediaArtist,
      album: mediaAlbum,
      artUri: mediaArtUri,
      duration: mediaDuration,
      extras: mediaExtras,
    );
  }

  /// Создаёт из передаваемого объекта [Audio] объект данного класа.
  static ExtendedAudio fromAPIAudio(
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
        vkThumbs: audio.album?.thumbnails?.asExtendedThumbnail,
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
        vkThumbs: audio.vkThumbs?.asExtendedThumbnails,
        deezerThumbs: audio.deezerThumbs?.asExtendedThumbnails,
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

    return other.runtimeType == ExtendedAudio &&
        other.id == id &&
        other.ownerID == ownerID;
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
    this.vkThumbs,
    this.deezerThumbs,
    this.hasLyrics = false,
    this.genreID,
    this.lyrics,
    this.isLiked = false,
    this.isCached,
  });
}

/// Класс для хранения данных о пользователе ВКонтакте, авторизованного в приложении.
///
/// Для получения данных воспользуйтесь [Provider]'ом [userProvider].
class UserData {
  /// Указывает ID данного пользователя.
  int id;

  /// Имя пользователя.
  String firstName;

  /// Фамилия пользователя.
  String lastName;

  /// Возвращает имя и фамилию пользователя.
  String get fullName => "$firstName $lastName";

  /// URL к квадратной фотографии с шириной в 50 пикселей.
  String? photo50Url;

  /// URL к квадратной фотографии с максимальным размером.
  String? photoMaxUrl;

  UserData({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photo50Url,
    this.photoMaxUrl,
  });
}

/// [Provider] для получения данных о пользователе ВКонтакте, авторизованного во Flutter VK.
@riverpod
class User extends _$User {
  @override
  UserData build() {
    final AuthState state = ref.read(currentAuthStateProvider);
    assert(
      state == AuthState.authenticated,
      "Attempted to read userProvider without authorization ($state)",
    );

    final SharedPreferences prefs = ref.read(sharedPrefsProvider).requireValue;

    return UserData(
      id: prefs.getInt("ID")!,
      firstName: prefs.getString("FirstName")!,
      lastName: prefs.getString("LastName")!,
      photo50Url: prefs.getString("Photo50"),
      photoMaxUrl: prefs.getString("PhotoMax"),
    );
  }

  /// Сохраняет вторичный токен (VK Admin) ВКонтакте в [SharedPreferences] ([sharedPrefsProvider]), а так же обновляет состояние этого Provider.
  ///
  /// Если Вы желаете сохранить не вторичный, а основной токен (Kate Mobile), то воспользуйтесь [currentAuthStateProvider].
  Future<void> loginSecondary(String token) async {
    final SharedPreferences prefs = ref.read(sharedPrefsProvider).requireValue;

    // Авторизуем пользователя, и сохраняем флаг авторизации в [SharedPreferences].
    prefs.setString("RecommendationsToken", token);

    // Обновляем состояние авторизации.
    ref.invalidateSelf();
    ref.invalidate(secondaryTokenProvider);
  }

//   /// Вставляет в [allPlaylists] указанный плейлист [playlists], объеденяя старые и новые поля. Если плейлист не существовал ранее, то он будет создан. [saveToDB] указывает, будет ли изменение сохранено в БД Isar.
//   void updatePlaylist(
//     ExtendedPlaylist playlist, {
//     bool saveToDB = true,
//   }) async {
//     ExtendedPlaylist? existingPlaylist = allPlaylists[playlist.mediaKey];

//     // Не позволяем пользователю сохранить плейлист "Музыка из результатов поиска".
//     if (playlist.ownerID == id! && playlist.id == -1) {
//       logger.w(
//         "Attempted to call updatePlaylist for 'search results' playlist!",
//         stackTrace: StackTrace.current,
//       );

//       return;
//     }

//     if (existingPlaylist == null) {
//       // Ранее такового плейлиста не было, просто сохраняем и ничего не делаем.

//       existingPlaylist = playlist;
//     } else {
//       // Мы должны сделать объединение полей из старого и нового плейлиста.

//       existingPlaylist.count = playlist.count;
//       existingPlaylist.title = playlist.title;
//       existingPlaylist.description = playlist.description;
//       existingPlaylist.subtitle = playlist.subtitle;
//       existingPlaylist.cacheTracks =
//           playlist.cacheTracks ?? existingPlaylist.cacheTracks;
//       existingPlaylist.photo = playlist.photo;
//       existingPlaylist.createTime = playlist.createTime;
//       existingPlaylist.updateTime = playlist.updateTime;
//       existingPlaylist.followers = playlist.followers;
//       existingPlaylist.isLiveData = playlist.isLiveData;
//       existingPlaylist.areTracksLive = playlist.areTracksLive;
//       existingPlaylist.backgroundAnimationUrl = playlist.backgroundAnimationUrl;

//       // Проходимся по новому списку треков, если он вообще был передан.
//       if (playlist.audios != null) {
//         // Создаём отдельный List с shadow copy списка треков.
//         final List<ExtendedAudio> newAudios = [...playlist.audios!];
//         final List<ExtendedAudio> oldAudios = existingPlaylist.audios ?? [];
//         existingPlaylist.audios = [];

//         for (ExtendedAudio audio in newAudios) {
//           ExtendedAudio newAudio =
//               oldAudios.firstWhereOrNull((oldAudio) => oldAudio == audio) ??
//                   audio;

//           newAudio.title = audio.title;
//           newAudio.artist = audio.artist;
//           newAudio.url ??= audio.url;
//           newAudio.isCached = audio.isCached ?? newAudio.isCached;
//           newAudio.album ??= audio.album;
//           newAudio.hasLyrics ??= audio.hasLyrics;
//           newAudio.lyrics ??= audio.lyrics;
//           newAudio.vkThumbs ??= audio.vkThumbs;

//           existingPlaylist.audios!.add(newAudio);
//         }

//         // Проходимся по тому списку треков, которые кэшированы, но больше нет в плейлисте.
//         final List<ExtendedAudio> removedAudios = oldAudios
//             .where(
//               (audio) =>
//                   (audio.isCached ?? false) &&
//                   !existingPlaylist!.audios!.contains(audio),
//             )
//             .toList();

//         for (ExtendedAudio audio in removedAudios) {
//           logger.d("Audio $audio will be deleted");

//           // Удаляем трек из кэша.
//           try {
//             CachedStreamedAudio(audio: audio).delete();

//             audio.isCached = false;
//           } catch (e) {
//             // No-op.
//           }
//         }
//       }
//     }

//     // Сохраняем новый плейлист, очищая кэш плейлистов в памяти.
//     allPlaylists[playlist.mediaKey] = existingPlaylist;
//     _favoritesPlaylist = null;
//     _regularPlaylists = null;
//     _moodPlaylists = null;
//     _audioMixPlaylists = null;
//     _recommendationPlaylists = null;
//     _simillarPlaylists = null;
//     _madeByVKPlaylists = null;

//     // Сохраняем в БД.
//     if (saveToDB) {
//       await appStorage.savePlaylists(
//         allPlaylists.values
//             .map(
//               (playlist) => playlist.asDBPlaylist,
//             )
//             .toList(),
//       );
//     }
//   }

//   /// Вставляет в [allPlaylists] указанный список из плейлистов [playlists], объеденяя старые и новые поля. Если какой то из плейлистов [playlists] не существовал ранее, то он будет создан. [saveToDB] указывает, будет ли изменение сохранено в БД Isar.
//   void updatePlaylists(
//     List<ExtendedPlaylist> playlists, {
//     bool saveToDB = true,
//   }) async {
//     for (ExtendedPlaylist playlist in playlists) {
//       updatePlaylist(
//         playlist,
//         saveToDB: false,
//       );
//     }

//     if (saveToDB) {
//       await appStorage.savePlaylists(
//         allPlaylists.values
//             .map(
//               (playlist) => playlist.asDBPlaylist,
//             )
//             .toList(),
//       );
//     }
//   }

  /// Возвращает основной токен.
  String? get _mainToken => ref.read(tokenProvider);

  /// Возвращает основной токен.
  String? get _secondaryToken => ref.read(secondaryTokenProvider);

  /// Получает публичную информацию о пользователях с передаваемым ID, либо же о владельце текущей страницы, если ID не передаётся.
  Future<APIUsersGetResponse> usersGet({
    List<int>? userIDs,
    String? fields = vkAPIallUserFields,
  }) async =>
      await users_get(
        _mainToken!,
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
        _mainToken!,
        userID,
      );

  /// Возвращает информацию о аудио плейлистах указанного пользователя.
  ///
  /// API: `audio.getPlaylists`.
  Future<APIAudioGetPlaylistsResponse> audioGetPlaylists(
    int userID,
  ) async =>
      audio_getPlaylists(
        _mainToken!,
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
        _mainToken!,
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
        _mainToken!,
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
        _mainToken!,
        audioID,
        ownerID ?? state.id,
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
        _mainToken!,
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
        _mainToken!,
        audioID,
      );

  /// Информирует ВКонтакте о том, что передавемый трек сейчас прослушивается. Благодаря этому методу, рекомендации ВКонтакте перестают рекомендовать этот трек снова и снова.
  ///
  /// API: `audio.sendStartEvent`.
  Future<APIAudioSendStartEventResponse> audioSendStartEvent(
    String id,
  ) async =>
      await audio_send_start_event(
        _mainToken!,
        id,
      );

  /// Помечает передаваемые треки как дизлайкнутые.
  ///
  /// API: `audio.addDislike`.
  Future<APIAudioAddDislikeResponse> audioAddDislike(
    List<String> ids,
  ) async =>
      await audio_add_dislike(
        _mainToken!,
        ids,
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
      _mainToken!,
      query,
      autoComplete: autoComplete,
      count: count,
      offset: offset,
    );

    if (response.error != null) return response;

    // TODO: Избавиться от этих костылей.

    // Если у пользователя есть токен VK Admin, то тогда нам нужно получить расширенную информацию о треках.
    if (_secondaryToken != null) {
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
        _mainToken!,
        query,
        autoComplete: autoComplete,
        count: count,
        offset: offset,
      );

  /// Возвращает список треков для аудио микса (VK Mix).
  ///
  /// Требуется токен от Kate Mobile.
  Future<APIAudioGetStreamMixAudiosResponse> audioGetStreamMixAudios({
    String mixID = "common",
    int count = 10,
  }) async =>
      await audio_get_stream_mix_audios(
        _mainToken!,
        mixID: mixID,
        count: count,
      );

  /// Возвращает список треков для аудио микса (VK Mix), дополняя треки информацией об их альбомах.
  ///
  /// Требуется токен от Kate Mobile и VK Admin.
  Future<APIAudioGetStreamMixAudiosResponse> audioGetStreamMixAudiosWithAlbums({
    String mixID = "common",
    int count = 10,
  }) async {
    final APIAudioGetStreamMixAudiosResponse response =
        await audioGetStreamMixAudios(
      mixID: mixID,
      count: count,
    );

    if (response.error != null) return response;

    // TODO: Избавиться от этих костылей.

    // Если у пользователя есть токен VK Admin, то тогда нам нужно получить расширенную информацию о треках.
    if (_secondaryToken != null) {
      // Получаем MediaKey треков, делая в запросе не более 200 ключей.
      List<String> audioIDs = [];
      List<Audio> audios = response.response!;

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
        return APIAudioGetStreamMixAudiosResponse(
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
        _secondaryToken!,
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
        _mainToken!,
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
        _secondaryToken!,
        audioMediaIDs,
      );

  /// Извлекает <200 лайкнутых треков, а так же <50 плейлистов пользователя.
  ///
  /// Для данного метода требуется токен от Kate Mobile.
  Future<APIAudioGetDataResponse> scriptGetFavAudioAndPlaylists(
    int userID,
  ) async =>
      await scripts_getFavAudioAndPlaylists(
        _mainToken!,
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
      _mainToken!,
      ownerID,
      albumID: albumID,
      accessKey: accessKey,
    );

    if (massAudios.error != null) return massAudios;

    // TODO: Избавиться от этих костылей.

    // Если у пользователя есть токен VK Admin, то тогда нам нужно получить расширенную информацию о треках.
    if (_secondaryToken != null) {
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

    return massAudios;
  }
}
