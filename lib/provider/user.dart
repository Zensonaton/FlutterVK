import "package:audio_service/audio_service.dart";
import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../api/deezer/shared.dart";
import "../api/vk/audio/get_lyrics.dart";
import "../api/vk/shared.dart";
import "../db/schemas/playlists.dart";
import "../enums.dart";
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

  /// Тип плейлиста.
  PlaylistType type;

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

  /// Указывает, подписан ли данный пользователь на данный плейлист или нет.
  bool isFollowing;

  /// Фотография плейлиста.
  Thumbnails? photo;

  /// Список из аудио в данном плейлисте.
  List<ExtendedAudio>? audios;

  /// {@macro ImageSchemeExtractor.colorInts}
  final Map<int, int?>? colorInts;

  /// {@macro ImageSchemeExtractor.scoredColorInts}
  final List<int>? scoredColorInts;

  /// {@macro ImageSchemeExtractor.frequentColorInt}
  final int? frequentColorInt;

  /// {@macro ImageSchemeExtractor.colorCount}
  final int? colorCount;

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
  final bool isLiveData;

  /// Указывает, что данный плейлист был загружен с БД Isar, т.е., данные этого плейлиста являются кэшированными.
  ///
  /// Данное поле является противоположностью поля [isLiveData].
  bool get isDataCached => !isLiveData;

  /// Указывает, что треки данного плейлиста были загружены с API ВКонтакте. Если данное поле false, то это значит, что все треки из этого плейлиста являются кешированными (т.е., загружены из БД Isar).
  ///
  /// Не стоит путать с [isLiveData], данное поле указывает только то, что треки в данном плейлисте были загружены с API ВКонтакте, данное поле не отображает состояние загруженности данных о самом плейлисте.
  final bool areTracksLive;

  /// Указывает, что треки данного плейлиста были загружены с БД Isar, т.е., данные этого плейлиста являются кэшированными.
  ///
  /// Данное поле является противоположностью поля [areTracksLive].
  bool get areTracksCached => !areTracksLive;

  /// Указывает, что в данном плейлисте разрешено кэширование треков.
  final bool? cacheTracks;

  /// Указывает, что данный плейлист является плейлистом рекомендательного типа. Обычно, при прослушивании музыки у таких плейлистов, в интерфейсе показывается кнопка дизлайка.
  bool get isRecommendationTypePlaylist =>
      ![PlaylistType.favorites, PlaylistType.regular].contains(type);

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
    Playlist playlist,
    PlaylistType type, {
    List<ExtendedAudio>? audios,
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
        type: type,
        title: playlist.title,
        description: playlist.description,
        count: playlist.count,
        accessKey: playlist.accessKey,
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
        type: playlist.type,
        title: playlist.title,
        description: playlist.description,
        count: playlist.count,
        accessKey: playlist.accessKey,
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
        colorInts: playlist.colorInts != null
            ? Map.fromIterable(playlist.colorInts!, key: (item) => item)
            : null,
        scoredColorInts: playlist.scoredColorInts,
        frequentColorInt: playlist.frequentColorInt,
        colorCount: playlist.colorCount,
      );

  /// Возвращает копию данного класса в виде объекта [DBPlaylist].
  DBPlaylist get asDBPlaylist => DBPlaylist.fromExtendedPlaylist(this);

  /// Делает копию этого класа с новыми передаваемыми значениями.
  ExtendedPlaylist copyWith({
    int? id,
    int? ownerID,
    PlaylistType? type,
    String? title,
    String? description,
    int? count,
    String? accessKey,
    bool? isFollowing,
    String? subtitle,
    Thumbnails? photo,
    List<ExtendedAudio>? audios,
    String? mixID,
    String? backgroundAnimationUrl,
    double? simillarity,
    String? color,
    List<ExtendedAudio>? knownTracks,
    bool? isLiveData,
    bool? areTracksLive,
    bool? cacheTracks,
    Map<int, int?>? colorInts,
    List<int>? scoredColorInts,
    int? frequentColorInt,
    int? colorCount,
  }) =>
      ExtendedPlaylist(
        id: id ?? this.id,
        ownerID: ownerID ?? this.ownerID,
        type: type ?? this.type,
        title: title ?? this.title,
        description: description ?? this.description,
        count: count ?? this.count,
        accessKey: accessKey ?? this.accessKey,
        isFollowing: isFollowing ?? this.isFollowing,
        subtitle: subtitle ?? this.subtitle,
        photo: photo ?? this.photo,
        audios: audios ?? this.audios,
        mixID: mixID ?? this.mixID,
        backgroundAnimationUrl:
            backgroundAnimationUrl ?? this.backgroundAnimationUrl,
        simillarity: simillarity ?? this.simillarity,
        color: color ?? this.color,
        knownTracks: knownTracks ?? this.knownTracks,
        isLiveData: isLiveData ?? this.isLiveData,
        areTracksLive: areTracksLive ?? this.areTracksLive,
        cacheTracks: cacheTracks ?? this.cacheTracks,
        colorInts: colorInts ?? this.colorInts,
        scoredColorInts: scoredColorInts ?? this.scoredColorInts,
        frequentColorInt: frequentColorInt ?? this.frequentColorInt,
        colorCount: colorCount ?? this.colorCount,
      );

  /// Возвращает копию этого плейлиста с добавленным треком [audio] в начало плейлиста. Если этот трек уже есть, то заменяет его новым.
  ExtendedPlaylist copyWithNewAudio(ExtendedAudio audio) {
    List<ExtendedAudio> newAudios = [...audios!];

    // Пытаемся найти индекс трека.
    final int index = newAudios.indexWhere(
      (item) => item.ownerID == audio.ownerID && item.id == audio.id,
    );

    // Если такого трека нет, то просто добавляем его в начале.
    if (index == -1) {
      newAudios.insert(0, audio);
    } else {
      // Удаляем старый трек и вставляем новый.
      newAudios.removeAt(index);
      newAudios.insert(index, audio);
    }

    return copyWith(audios: newAudios);
  }

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
        other.title == title &&
        other.isLiveData == isLiveData &&
        other.areTracksLive == areTracksLive &&
        other.cacheTracks == cacheTracks &&
        other.colorCount == colorCount &&
        listEquals(other.audios, audios);
  }

  @override
  int get hashCode => audios.hashCode;

  ExtendedPlaylist({
    required this.id,
    required this.ownerID,
    required this.type,
    this.title,
    this.description,
    required this.count,
    this.accessKey,
    this.isFollowing = false,
    this.subtitle,
    this.photo,
    this.audios,
    this.simillarity,
    this.color,
    this.knownTracks,
    this.mixID,
    this.backgroundAnimationUrl,
    this.isLiveData = false,
    this.areTracksLive = false,
    this.cacheTracks,
    this.colorInts,
    this.scoredColorInts,
    this.frequentColorInt,
    this.colorCount,
  });
}

/// Класс, выступающий в роли упрощённой версии класса [Thumbnails].
class ExtendedThumbnails {
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
  static ExtendedThumbnails fromDBExtendedThumbnail(
    DBExtendedThumbnail thumbnail,
  ) =>
      ExtendedThumbnails(
        photoSmall: thumbnail.photoSmall!,
        photoMedium: thumbnail.photoMedium!,
        photoBig: thumbnail.photoBig!,
        photoMax: thumbnail.photoMax!,
      );

  /// Возвращает копию данного класса в виде объекта [DBExtendedThumbnail].
  DBExtendedThumbnail get asDBExtendedThumbnail =>
      DBExtendedThumbnail.fromExtendedThumbnail(this);

  /// Создаёт из передаваемого объекта [Thumbnails] объект данного класа.
  static ExtendedThumbnails fromThumbnail(Thumbnails thumbnails) =>
      ExtendedThumbnails(
        photoSmall: thumbnails.photo68,
        photoMedium: thumbnails.photo270,
        photoBig: thumbnails.photo600,
        photoMax: thumbnails.photo1200,
      );

  /// Создаёт из передаваемого объекта [DeezerTrack] объект данного класса.
  static ExtendedThumbnails fromDeezerTrack(DeezerTrack track) =>
      ExtendedThumbnails(
        photoSmall: track.album.coverSmall!,
        photoMedium: track.album.coverMedium!,
        photoBig: track.album.coverBig!,
        photoMax: track.album.coverXL!,
      );

  @override
  String toString() => "ExtendedThumbnails";

  @override
  bool operator ==(covariant ExtendedThumbnails other) {
    if (identical(this, other)) return true;

    return other.runtimeType == ExtendedAudio && other.photoSmall == photoSmall;
  }

  @override
  int get hashCode => photoSmall.hashCode;

  ExtendedThumbnails({
    required this.photoSmall,
    required this.photoMedium,
    required this.photoBig,
    required this.photoMax,
  });
}

/// Класс, копирующий поля объекта [Audio] от API ВКонтакте, добавляя некоторые новые поля.
class ExtendedAudio {
  /// ID аудиозаписи.
  final int id;

  /// ID владельца аудиозаписи.
  final int ownerID;

  /// Имя исполнителя.
  final String artist;

  /// Название аудиозаписи.
  final String title;

  /// Длительность аудиозаписи в секундах.
  final int duration;

  /// Подпись трека.
  final String? subtitle;

  /// Ключ доступа.
  final String accessKey;

  /// Указывает, если это Explicit-аудиозапись.
  final bool isExplicit;

  /// Указывает, что данный трек ограничен.
  final bool isRestricted;

  /// URL на `mp3` данной аудиозаписи.
  ///
  /// Очень часто он отсутствует, выдавая пустую строку.
  final String? url;

  /// Timestamp добавления аудиозаписи.
  final int date;

  /// Информация об альбоме данной аудиозаписи.
  final Album? album;

  /// Информация об обложке данного трека, полученного с ВКонтакте.
  final ExtendedThumbnails? vkThumbs;

  /// Информация об обложке данного трека, полученного с Deezer.
  final ExtendedThumbnails? deezerThumbs;

  /// Возвращает объект типа [ExtendedThumbnails], берущий значение с переменной [vkThumbs] или [deezerThumbs].
  ExtendedThumbnails? get thumbnail => vkThumbs ?? deezerThumbs;

  /// Возвращает URL самой маленькой обложки ([ExtendedThumbnails.photoSmall]) из переменной [vkThumbs] либо [deezerThumbs].
  String? get smallestThumbnail => thumbnail?.photoSmall;

  /// Возвращает URL самой большой обложки ([ExtendedThumbnails.photoMax]) из переменной [vkThumbs] либо [deezerThumbs].
  String? get maxThumbnail => thumbnail?.photoMax;

  /// Указывает наличие текста песни.
  final bool? hasLyrics;

  /// ID жанра аудиозаписи. Список жанров описан [здесь](https://dev.vk.com/ru/reference/objects/audio-genres).
  final int? genreID;

  /// Информация о тексте песни.
  final Lyrics? lyrics;

  /// Указывает, что данный трек лайкнут (если находится в плейлисте "любимые треки").
  ///
  /// Данное поле может стать false только в том случае, если пользователь удалил трек, который ранее был лайкнутым.
  final bool isLiked;

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
  final bool? isCached;

  /// Указывает размер кэша трека в байтах.
  ///
  /// null если трек не кэширован ([isCached]).
  final int? cachedSize;

  /// Указывает, возможно ли воспроизвести данный трек. Данное поле проверяет наличие интернета и существование Url на mp3 файл, либо же то, что трек кэширован.
  bool get canPlay =>
      (isCached ?? false) || (connectivityManager.hasConnection && url != null);

  /// Указывает, что данный трек был сохранён из другого плейлиста, и значит, что вместо [id] (и его подобным) стоит пользоваться [relativeID].
  final bool savedFromPlaylist;

  /// Значение, используемое как [id], обозначающее ID этого трека относительно этого пользователя после сохранения трека ([toggleTrackLike]).
  ///
  /// После удаления трека, это поле должно быть равно null.
  final int? relativeID;

  /// Значение, используемое как [ownerID], обозначающее ID этого трека относительно этого пользователя после сохранения трека ([toggleTrackLike]).
  ///
  /// После удаления трека, это поле должно быть равно null.
  final int? relativeOwnerID;

  /// ID плейлиста, из которого этот трек был сохранён.
  final int? savedPlaylistID;

  /// ID владельца плейлиста, из которого этот трек был сохранён.
  final int? savedPlaylistOwnerID;

  /// {@macro ImageSchemeExtractor.colorInts}
  final Map<int, int?>? colorInts;

  /// {@macro ImageSchemeExtractor.scoredColorInts}
  final List<int>? scoredColorInts;

  /// {@macro ImageSchemeExtractor.frequentColorInt}
  final int? frequentColorInt;

  /// {@macro ImageSchemeExtractor.colorCount}
  final int? colorCount;

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
        cachedSize: audio.cachedSize,
        colorInts: audio.colorInts != null
            ? Map.fromIterable(audio.colorInts!, key: (item) => item)
            : null,
        scoredColorInts: audio.scoredColorInts,
        frequentColorInt: audio.frequentColorInt,
        colorCount: audio.colorCount,
      );

  /// Возвращает копию данного объекта с новыми передаваемыми значениями.
  ExtendedAudio copyWith({
    int? id,
    int? ownerID,
    String? artist,
    String? title,
    int? duration,
    String? subtitle,
    String? accessKey,
    bool? isExplicit,
    bool? isRestricted,
    String? url,
    int? date,
    Album? album,
    ExtendedThumbnails? vkThumbs,
    ExtendedThumbnails? deezerThumbs,
    bool? hasLyrics,
    int? genreID,
    Lyrics? lyrics,
    bool? isLiked,
    bool? isCached,
    int? cachedSize,
    bool? savedFromPlaylist,
    int? relativeID,
    int? relativeOwnerID,
    int? savedPlaylistID,
    int? savedPlaylistOwnerID,
    Map<int, int?>? colorInts,
    List<int>? scoredColorInts,
    int? frequentColorInt,
    int? colorCount,
  }) =>
      ExtendedAudio(
        id: id ?? this.id,
        ownerID: ownerID ?? this.ownerID,
        artist: artist ?? this.artist,
        title: title ?? this.title,
        duration: duration ?? this.duration,
        subtitle: subtitle ?? this.subtitle,
        accessKey: accessKey ?? this.accessKey,
        isExplicit: isExplicit ?? this.isExplicit,
        isRestricted: isRestricted ?? this.isRestricted,
        url: url ?? this.url,
        date: date ?? this.date,
        album: album ?? this.album,
        vkThumbs: vkThumbs ?? this.vkThumbs,
        deezerThumbs: deezerThumbs ?? this.deezerThumbs,
        hasLyrics: hasLyrics ?? this.hasLyrics,
        genreID: genreID ?? this.genreID,
        lyrics: lyrics ?? this.lyrics,
        isLiked: isLiked ?? this.isLiked,
        isCached: isCached ?? this.isCached,
        cachedSize: cachedSize ?? this.cachedSize,
        savedFromPlaylist: savedFromPlaylist ?? this.savedFromPlaylist,
        relativeID: relativeID ?? this.relativeID,
        relativeOwnerID: relativeOwnerID ?? this.relativeOwnerID,
        savedPlaylistID: savedPlaylistID ?? this.savedPlaylistID,
        savedPlaylistOwnerID: savedPlaylistOwnerID ?? this.savedPlaylistOwnerID,
        colorInts: colorInts ?? this.colorInts,
        scoredColorInts: scoredColorInts ?? this.scoredColorInts,
        frequentColorInt: frequentColorInt ?? this.frequentColorInt,
        colorCount: colorCount ?? this.colorCount,
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
        other.ownerID == ownerID &&
        other.isLiked == isLiked &&
        other.isCached == isCached;
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
    this.cachedSize,
    this.savedFromPlaylist = false,
    this.relativeID,
    this.relativeOwnerID,
    this.savedPlaylistID,
    this.savedPlaylistOwnerID,
    this.colorInts,
    this.scoredColorInts,
    this.frequentColorInt,
    this.colorCount,
  });
}

/// Класс для хранения данных о пользователе ВКонтакте, авторизованного в приложении.
///
/// Для получения данных воспользуйтесь [Provider]'ом [userProvider].
class UserData {
  /// ID пользователя.
  int id;

  /// Имя пользователя.
  String firstName;

  /// Фамилия пользователя.
  String lastName;

  /// Возвращает имя и фамилию пользователя в формате `Имя Фамилия`.
  String get fullName => "$firstName $lastName";

  /// @domain пользователя.
  String? domain;

  /// URL к квадратной фотографии с шириной в 50 пикселей.
  String? photo50Url;

  /// URL к квадратной фотографии с максимальным размером.
  String? photoMaxUrl;

  UserData({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.domain,
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

    final SharedPreferences prefs = ref.read(sharedPrefsProvider);

    return UserData(
      id: prefs.getInt("ID")!,
      firstName: prefs.getString("FirstName")!,
      lastName: prefs.getString("LastName")!,
      domain: prefs.getString("Domain"),
      photo50Url: prefs.getString("Photo50"),
      photoMaxUrl: prefs.getString("PhotoMax"),
    );
  }

  /// Сохраняет вторичный токен (VK Admin) ВКонтакте в [SharedPreferences] ([sharedPrefsProvider]), а так же обновляет состояние этого Provider.
  ///
  /// Если Вы желаете сохранить не вторичный, а основной токен (Kate Mobile), то воспользуйтесь [currentAuthStateProvider].
  Future<void> loginSecondary(String token) async {
    final SharedPreferences prefs = ref.read(sharedPrefsProvider);

    // Авторизуем пользователя, и сохраняем флаг авторизации в [SharedPreferences].
    prefs.setString("RecommendationsToken", token);

    // Обновляем состояние авторизации.
    ref.invalidateSelf();
    ref.invalidate(secondaryTokenProvider);
  }
}
