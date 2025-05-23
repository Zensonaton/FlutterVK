import "package:isar/isar.dart";

import "../api/vk/audio/get_lyrics.dart";
import "../api/vk/shared.dart";
import "../enums.dart";
import "../provider/user.dart";
import "../services/db.dart"
    if (dart.library.js_interop) "../services/db_stub.dart";

part "playlists.g.dart";

/// Класс, олицетворяющий копию класса [ExtendedThumbnails].
@Embedded()
class DBExtendedThumbnail {
  /// URL на изображение альбома самого маленького размера. Рекомендуется использовать там, где нужно самое маленькое изображение трека: в списке треков, миниплеере и так далее.
  final String? photoSmall;

  /// URL на изображение альбома среднего размера.
  final String? photoMedium;

  /// URL на изображение альбома большого размера.
  final String? photoBig;

  /// URL на изображение альбома самого большого размера из всех. Именно это изображение имеет самое высокое качество, и поэтому его рекомендуется использовать в полноэкранном плеере.
  final String? photoMax;

  /// Преобразовывает переданный объект типа [ExtendedThumbnails], преобразовывая его в [DBExtendedThumbnail].
  static DBExtendedThumbnail fromExtended(ExtendedThumbnails thumbnails) {
    return DBExtendedThumbnail(
      photoSmall: thumbnails.photoSmall,
      photoMedium: thumbnails.photoMedium,
      photoBig: thumbnails.photoBig,
      photoMax: thumbnails.photoMax,
    );
  }

  /// Преобразовывает переданный объект типа [DBExtendedThumbnail], преобразовывая его в [ExtendedThumbnails].
  static ExtendedThumbnails toExtended(DBExtendedThumbnail thumbnails) {
    return ExtendedThumbnails(
      photoSmall: thumbnails.photoSmall!,
      photoMedium: thumbnails.photoMedium!,
      photoBig: thumbnails.photoBig!,
      photoMax: thumbnails.photoMax!,
    );
  }

  DBExtendedThumbnail({
    this.photoSmall,
    this.photoMedium,
    this.photoBig,
    this.photoMax,
  });
}

/// Класс, олицетворяющий изображения плейлиста или трека.
@Embedded()
class DBThumbnails {
  /// Ширина изображения альбома.
  final int? width;

  /// Высота изображения альбома.
  final int? height;

  /// URL на изображение альбома в размере `34`.
  final String? photo34;

  /// URL на изображение альбома в размере `68`.
  final String? photo68;

  /// URL на изображение альбома в размере `135`.
  final String? photo135;

  /// URL на изображение альбома в размере `270`.
  final String? photo270;

  /// URL на изображение альбома в размере `300`.
  final String? photo300;

  /// URL на изображение альбома в размере `600`.
  final String? photo600;

  /// URL на изображение альбома в размере `1200`.
  final String? photo1200;

  /// Преобразовывает переданный объект типа [Thumbnails], преобразовывая его в [DBThumbnails].
  static DBThumbnails fromExtended(Thumbnails thumbnails) {
    return DBThumbnails(
      width: thumbnails.width,
      height: thumbnails.height,
      photo34: thumbnails.photo34,
      photo68: thumbnails.photo68,
      photo135: thumbnails.photo135,
      photo270: thumbnails.photo270,
      photo300: thumbnails.photo300,
      photo600: thumbnails.photo600,
      photo1200: thumbnails.photo1200,
    );
  }

  /// Преобразовывает переданный объект типа [DBThumbnails], преобразовывая его в [Thumbnails].
  static Thumbnails toExtended(DBThumbnails thumbnails) {
    return Thumbnails(
      width: thumbnails.width!,
      height: thumbnails.height!,
      photo34: thumbnails.photo34!,
      photo68: thumbnails.photo68!,
      photo135: thumbnails.photo135!,
      photo270: thumbnails.photo270!,
      photo300: thumbnails.photo300!,
      photo600: thumbnails.photo600!,
      photo1200: thumbnails.photo1200!,
    );
  }

  DBThumbnails({
    this.width,
    this.height,
    this.photo34,
    this.photo68,
    this.photo135,
    this.photo270,
    this.photo300,
    this.photo600,
    this.photo1200,
  });
}

/// Класс, олицетворяющий отдельную синхроинизрованную строку у трека.
///
/// Строчки текстов песен хранятся внутри объектов [DBLyrics].
@Embedded()
class DBLyricTimestamp {
  /// Текст данной строки.
  ///
  /// Иногда может отсутствовать, в случае, если [interlude] равен true.
  final String? line;

  /// Указывает, что здесь находится "заполнитель".
  ///
  /// Чаще всего в интерфейсе он отображается символом ноты.
  final bool interlude;

  /// Время начала данной линии в тексте песни в миллисекундах.
  final int? begin;

  /// Время окончания данной линиий в тексте песни в миллисекундах.
  final int? end;

  /// Преобразовывает переданный объект типа [LyricTimestamp], преобразовывая его в [DBLyricTimestamp].
  static DBLyricTimestamp fromExtended(LyricTimestamp timestamp) {
    return DBLyricTimestamp(
      line: timestamp.line,
      interlude: timestamp.interlude,
      begin: timestamp.begin,
      end: timestamp.end,
    );
  }

  /// Преобразовывает переданный объект типа [DBLyricTimestamp], преобразовывая его в [LyricTimestamp].
  static LyricTimestamp toExtended(DBLyricTimestamp timestamp) {
    return LyricTimestamp(
      line: timestamp.line,
      interlude: timestamp.interlude,
      begin: timestamp.begin,
      end: timestamp.end,
    );
  }

  DBLyricTimestamp({
    this.line,
    this.interlude = false,
    this.begin,
    this.end,
  });
}

/// Класс, олицетворяющий текст у трека.
///
/// Тексты песен хранятся внутри объектов [DBPlaylist].
@Embedded()
class DBLyrics {
  /// Язык данного трека.
  ///
  /// Передаётся строка в виде `en`.
  final String? language;

  /// Перечисление всех линий в тексте песни, разделённых по времени.
  ///
  /// Может отсутствовать в случае, если у данного трека нету синхронизированных по времени lyrics'ов.
  final List<DBLyricTimestamp>? timestamps;

  /// Список всех линий в тексте песни. Может отсутствовать в пользу [timestamps].
  final List<String>? text;

  /// Преобразовывает переданный объект типа [Lyrics], преобразовывая его в [DBLyrics].
  static DBLyrics fromExtended(Lyrics lyrics) {
    return DBLyrics(
      language: lyrics.language,
      timestamps: lyrics.timestamps
          ?.map(
            (timestamp) => DBLyricTimestamp.fromExtended(timestamp),
          )
          .toList(),
      text: lyrics.text,
    );
  }

  /// Преобразовывает переданный объект типа [DBLyrics], преобразовывая его в [Lyrics].
  static Lyrics toExtended(DBLyrics lyrics) {
    return Lyrics(
      language: lyrics.language,
      timestamps: lyrics.timestamps
          ?.map(
            (timestamp) => DBLyricTimestamp.toExtended(timestamp),
          )
          .toList(),
      text: lyrics.text,
    );
  }

  DBLyrics({
    this.language,
    this.timestamps,
    this.text,
  });
}

/// Класс, олицетворяющий альбом, храняющийся в базе данных Isar.
///
/// Альбомы хранятся внутри объектов [DBPlaylist].
@Embedded()
class DBAlbum {
  /// ID альбома.
  final int? id;

  /// Название альбома.
  final String? title;

  /// ID владельца альбома.
  final int? ownerID;

  /// Ключ доступа.
  final String? accessKey;

  /// Преобразовывает переданный объект типа [Album], преобразовывая его в [DBAlbum].
  static DBAlbum fromExtended(Album album) {
    return DBAlbum(
      id: album.id,
      title: album.title,
      ownerID: album.ownerID,
      accessKey: album.accessKey,
    );
  }

  /// Преобразовывает переданный объект типа [DBAlbum], преобразовывая его в [Album].
  static Album toExtended(DBAlbum album) {
    return Album(
      id: album.id!,
      title: album.title!,
      ownerID: album.ownerID!,
      accessKey: album.accessKey!,
    );
  }

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  String get mediaKey => "${ownerID}_$id";

  @override
  bool operator ==(covariant DBAlbum other) {
    if (identical(this, other)) return true;

    return other.runtimeType == DBAlbum &&
        other.id == id &&
        other.ownerID == ownerID;
  }

  @override
  int get hashCode => mediaKey.hashCode;

  DBAlbum({
    this.id,
    this.title,
    this.ownerID,
    this.accessKey,
  });
}

/// Класс, олицетворяющий трек в базе данных Isar.
///
/// Все треки хранятся внутри объектов [DBPlaylist].
@Embedded()
class DBAudio {
  /// ID аудиозаписи.
  final int? id;

  /// ID владельца аудиозаписи.
  final int? ownerID;

  /// Имя исполнителя.
  final String? artist;

  /// Название аудиозаписи.
  final String? title;

  /// Длительность аудиозаписи в секундах.
  final int? duration;

  /// Подпись трека.
  final String? subtitle;

  /// Ключ доступа.
  final String? accessKey;

  /// Указывает, если это Explicit-аудиозапись.
  final bool? isExplicit;

  /// Указывает, что данный трек ограничен.
  final bool? isRestricted;

  /// URL на `mp3` данной аудиозаписи.
  final String? url;

  /// Timestamp добавления аудиозаписи.
  final int? date;

  /// Информация об альбоме данной аудиозаписи.
  DBAlbum? album;

  /// Информация об обложке данного трека, полученного с ВКонтакте.
  DBExtendedThumbnail? vkThumbs;

  /// Информация об обложке данного трека, полученного с Deezer.
  DBExtendedThumbnail? deezerThumbs;

  /// Указывает, что вместо [vkThumbs] будет использоваться [deezerThumbs].
  final bool? forceDeezerThumbs;

  /// Указывает наличие текста песни.
  final bool? hasLyrics;

  /// Информация о тексте песни со ВКонтакте.
  final DBLyrics? vkLyrics;

  /// Информация о тексте песни с LRCLIB.
  final DBLyrics? lrcLibLyrics;

  /// ID жанра аудиозаписи. Список жанров описан [здесь](https://dev.vk.com/ru/reference/objects/audio-genres).
  final int? genreID;

  /// Указывает, кэширован ли данный трек.
  final bool? isCached;

  /// Указывает размер кэша трека в байтах.
  ///
  /// null если трек не кэширован ([isCached]).
  final int? cachedSize;

  /// Указывает, что этот трек был заменён локально.
  final bool? replacedLocally;

  /// Преобразовывает переданный объект типа [ExtendedAudio], преобразовывая его в [DBAudio].
  static DBAudio fromExtended(ExtendedAudio audio) {
    return DBAudio(
      id: audio.id,
      ownerID: audio.ownerID,
      artist: audio.artist,
      title: audio.title,
      duration: audio.duration.inSeconds,
      accessKey: audio.accessKey,
      subtitle: audio.subtitle,
      isExplicit: audio.isExplicit,
      isRestricted: audio.isRestricted,
      url: audio.url,
      date: audio.date,
      hasLyrics: audio.hasLyrics,
      vkLyrics: audio.vkLyrics != null
          ? DBLyrics.fromExtended(audio.vkLyrics!)
          : null,
      lrcLibLyrics: audio.lrcLibLyrics != null
          ? DBLyrics.fromExtended(audio.lrcLibLyrics!)
          : null,
      genreID: audio.genreID,
      album: audio.album != null ? DBAlbum.fromExtended(audio.album!) : null,
      vkThumbs: audio.vkThumbs != null
          ? DBExtendedThumbnail.fromExtended(audio.vkThumbs!)
          : null,
      deezerThumbs: audio.deezerThumbs != null
          ? DBExtendedThumbnail.fromExtended(audio.deezerThumbs!)
          : null,
      forceDeezerThumbs: audio.forceDeezerThumbs,
      isCached: audio.isCached,
      cachedSize: (audio.isCached == true || audio.replacedLocally == true)
          ? audio.cachedSize
          : null,
      replacedLocally: audio.replacedLocally,
    );
  }

  /// Преобразовывает переданный объект типа [DBAudio], преобразовывая его в [ExtendedAudio].
  static ExtendedAudio toExtended(DBAudio audio, {bool isLiked = false}) {
    return ExtendedAudio(
      id: audio.id!,
      ownerID: audio.ownerID!,
      artist: audio.artist!,
      title: audio.title!,
      duration: Duration(seconds: audio.duration!),
      subtitle: audio.subtitle,
      accessKey: audio.accessKey,
      isExplicit: audio.isExplicit!,
      isRestricted: audio.isRestricted!,
      url: audio.url,
      date: audio.date,
      album: audio.album != null ? DBAlbum.toExtended(audio.album!) : null,
      vkThumbs: audio.vkThumbs != null
          ? DBExtendedThumbnail.toExtended(audio.vkThumbs!)
          : null,
      deezerThumbs: audio.deezerThumbs != null
          ? DBExtendedThumbnail.toExtended(audio.deezerThumbs!)
          : null,
      forceDeezerThumbs: audio.forceDeezerThumbs,
      hasLyrics: audio.hasLyrics,
      isLiked: isLiked,
      genreID: audio.genreID ?? 18,
      vkLyrics:
          audio.vkLyrics != null ? DBLyrics.toExtended(audio.vkLyrics!) : null,
      lrcLibLyrics: audio.lrcLibLyrics != null
          ? DBLyrics.toExtended(audio.lrcLibLyrics!)
          : null,
      isCached: audio.isCached ?? false,
      cachedSize: (audio.isCached == true || audio.replacedLocally == true)
          ? audio.cachedSize
          : null,
      replacedLocally: audio.replacedLocally,
    );
  }

  /// Делает копию этого класа с новыми передаваемыми значениями.
  DBAudio copyWith({
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
    DBAlbum? album,
    DBExtendedThumbnail? vkThumbs,
    DBExtendedThumbnail? deezerThumbs,
    bool? hasLyrics,
    DBLyrics? vkLyrics,
    DBLyrics? lrcLibLyrics,
    int? genreID,
    bool? isCached,
    int? cachedSize,
    bool? replacedLocally,
    List<int>? colorInts,
    List<int>? scoredColorInts,
    int? frequentColorInt,
    int? colorCount,
  }) =>
      DBAudio(
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
        vkLyrics: vkLyrics ?? this.vkLyrics,
        lrcLibLyrics: lrcLibLyrics ?? this.lrcLibLyrics,
        genreID: genreID ?? this.genreID,
        isCached: isCached ?? this.isCached,
        cachedSize: cachedSize ?? this.cachedSize,
        replacedLocally: replacedLocally ?? this.replacedLocally,
      );

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  @Ignore()
  String get mediaKey => "${ownerID}_$id";

  @override
  bool operator ==(covariant DBAudio other) {
    if (identical(this, other)) return true;

    return other.runtimeType == DBAudio &&
        other.id == id &&
        other.ownerID == ownerID;
  }

  @override
  int get hashCode => mediaKey.hashCode;

  DBAudio({
    this.id,
    this.ownerID,
    this.artist,
    this.title,
    this.duration,
    this.accessKey,
    this.subtitle,
    this.isExplicit,
    this.isRestricted,
    this.url,
    this.date,
    this.album,
    this.vkThumbs,
    this.deezerThumbs,
    this.forceDeezerThumbs,
    this.hasLyrics,
    this.vkLyrics,
    this.lrcLibLyrics,
    this.genreID,
    this.isCached,
    this.cachedSize,
    this.replacedLocally,
  });
}

/// Класс, олицетворяющий запись плейлиста в базе данных Isar.
@Collection()
class DBPlaylist {
  Id get isarId => AppStorage.fastHash(mediaKey);

  /// ID плейлиста ВКонтакте.
  final int id;

  /// ID владельца плейлиста.
  final int ownerID;

  /// Тип плейлиста.
  @enumerated
  final PlaylistType type;

  /// Название плейлиста.
  final String? title;

  /// Описание плейлиста.
  final String? description;

  /// Подпись плейлиста, обычно присутствует в плейлистах-рекомендациях.
  final String? subtitle;

  /// Количество аудиозаписей в данном плейлисте. Это значение возвращает общее количество треков в плейлисте, вне зависимости от того, загружен ли был список треков или нет.
  final int? count;

  /// Ключ доступа.
  final String? accessKey;

  /// Указывает, подписан ли данный пользователь на данный плейлист или нет.
  final bool? isFollowing;

  /// Фотография плейлиста.
  final DBThumbnails? photo;

  /// Список треков в данном плейлисте.
  final List<DBAudio>? audios;

  /// ID данного аудио микса. Данное поле не-null только для аудио микс-плейлистов.
  final String? mixID;

  /// URL на Lottie-анимацию, которая используется как фон данного микса. Данное поле не-null только для аудио микс-плейлистов.
  final String? backgroundAnimationUrl;

  /// Указывает процент "схожести" данного плейлиста. Данное поле не-null только для плейлистов из раздела "совпадения по вкусам".
  final double? simillarity;

  /// Указывает Hex-цвет для данного плейлиста. Данное поле не-null только для плейлистов из раздела "совпадения по вкусам".
  final String? color;

  /// Указывает первые 3 известных трека для данного плейлиста. Данное поле не-null только для плейлистов из раздела "совпадения по вкусам".
  final List<DBAudio>? knownTracks;

  /// Указывает, что в данном плейлисте разрешено кэширование треков.
  final bool isCachingAllowed;

  /// {@macro ImageSchemeExtractor.colorInts}
  final List<int>? colorInts;

  /// {@macro ImageSchemeExtractor.scoredColorInts}
  final List<int>? scoredColorInts;

  /// {@macro ImageSchemeExtractor.frequentColorInt}
  final int? frequentColorInt;

  /// {@macro ImageSchemeExtractor.colorCount}
  final int? colorCount;

  /// Преобразовывает переданный объект типа [ExtendedPlaylist], преобразовывая его в [DBPlaylist].
  static DBPlaylist fromExtended(ExtendedPlaylist playlist) {
    List<DBAudio>? audios;

    // VK Mix плейлисты не должны содержать треки.
    if (playlist.type != PlaylistType.audioMix) {
      audios = playlist.audios
          ?.where(
            (ExtendedAudio audio) {
              // Все плейлисты кроме "любимой музыки" должны содержать все треки.
              if (playlist.type != PlaylistType.favorites) return true;

              // Для "любимой музыки" должны быть сохранены в БД лишь те треки,
              // которые были лайкнуты, нелайкнутым трек может быть, если
              // пользователь убрал лайк, но трек ещё не был удалён из плейлиста.
              return audio.isLiked;
            },
          )
          .map(
            (ExtendedAudio audio) => DBAudio.fromExtended(audio),
          )
          .toList();
    }

    return DBPlaylist(
      id: playlist.id,
      ownerID: playlist.ownerID,
      type: playlist.type,
      title: playlist.title,
      description: playlist.description,
      subtitle: playlist.subtitle,
      count: playlist.count,
      accessKey: playlist.accessKey,
      isFollowing: playlist.isFollowing,
      photo: playlist.photo != null
          ? DBThumbnails.fromExtended(playlist.photo!)
          : null,
      audios: audios,
      mixID: playlist.mixID,
      backgroundAnimationUrl: playlist.backgroundAnimationUrl,
      simillarity: playlist.simillarity,
      color: playlist.color,
      knownTracks: playlist.knownTracks
          ?.map(
            (ExtendedAudio audio) => DBAudio.fromExtended(audio),
          )
          .toList(),
      isCachingAllowed: playlist.cacheTracks ?? false,
      colorInts: playlist.colorInts?.keys.toList(),
      scoredColorInts: playlist.scoredColorInts,
      frequentColorInt: playlist.frequentColorInt,
      colorCount: playlist.colorCount,
    );
  }

  /// Преобразовывает переданный объект типа [DBPlaylist], преобразовывая его в [ExtendedPlaylist].
  static ExtendedPlaylist toExtended(DBPlaylist playlist) {
    return ExtendedPlaylist(
      id: playlist.id,
      ownerID: playlist.ownerID,
      type: playlist.type,
      title: playlist.title,
      description: playlist.description,
      count: playlist.count,
      accessKey: playlist.accessKey,
      isFollowing: playlist.isFollowing ?? false,
      subtitle: playlist.subtitle,
      photo: playlist.photo != null
          ? DBThumbnails.toExtended(playlist.photo!)
          : null,
      audios: playlist.audios
          ?.map(
            (DBAudio audio) => DBAudio.toExtended(
              audio,
              isLiked: playlist.type == PlaylistType.favorites,
            ),
          )
          .toList(),
      mixID: playlist.mixID,
      backgroundAnimationUrl: playlist.backgroundAnimationUrl,
      simillarity: playlist.simillarity,
      color: playlist.color,
      knownTracks: playlist.knownTracks
          ?.map(
            (DBAudio audio) => DBAudio.toExtended(audio),
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
  }

  /// Делает копию этого класа с новыми передаваемыми значениями.
  DBPlaylist copyWith({
    int? id,
    int? ownerID,
    PlaylistType? type,
    String? title,
    String? description,
    String? subtitle,
    int? count,
    String? accessKey,
    bool? isFollowing,
    DBThumbnails? photo,
    List<DBAudio>? audios,
    String? mixID,
    String? backgroundAnimationUrl,
    double? simillarity,
    String? color,
    List<DBAudio>? knownTracks,
    bool? isCachingAllowed,
    List<int>? colorInts,
    List<int>? scoredColorInts,
    int? frequentColorInt,
    int? colorCount,
  }) =>
      DBPlaylist(
        id: id ?? this.id,
        ownerID: ownerID ?? this.ownerID,
        type: type ?? this.type,
        title: title ?? this.title,
        description: description ?? this.description,
        subtitle: subtitle ?? this.subtitle,
        count: count ?? this.count,
        accessKey: accessKey ?? this.accessKey,
        isFollowing: isFollowing ?? this.isFollowing,
        photo: photo ?? this.photo,
        audios: audios ?? this.audios,
        mixID: mixID ?? this.mixID,
        backgroundAnimationUrl:
            backgroundAnimationUrl ?? this.backgroundAnimationUrl,
        simillarity: simillarity ?? this.simillarity,
        color: color ?? this.color,
        knownTracks: knownTracks ?? this.knownTracks,
        isCachingAllowed: isCachingAllowed ?? this.isCachingAllowed,
        colorInts: colorInts ?? this.colorInts,
        scoredColorInts: scoredColorInts ?? this.scoredColorInts,
        frequentColorInt: frequentColorInt ?? this.frequentColorInt,
        colorCount: colorCount ?? this.colorCount,
      );

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  @Ignore()
  String get mediaKey => "${ownerID}_$id";

  @override
  bool operator ==(covariant DBPlaylist other) {
    if (identical(this, other)) return true;

    return other.runtimeType == DBPlaylist &&
        other.id == id &&
        other.ownerID == ownerID;
  }

  @override
  int get hashCode => mediaKey.hashCode;

  DBPlaylist({
    required this.id,
    required this.ownerID,
    required this.type,
    this.title,
    this.description,
    this.subtitle,
    this.count,
    this.accessKey,
    this.isFollowing,
    this.photo,
    this.audios,
    this.mixID,
    this.backgroundAnimationUrl,
    this.simillarity,
    this.color,
    this.knownTracks,
    required this.isCachingAllowed,
    this.colorInts,
    this.scoredColorInts,
    this.frequentColorInt,
    this.colorCount,
  });
}
