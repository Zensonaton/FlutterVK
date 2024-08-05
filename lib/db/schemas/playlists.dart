import "package:isar/isar.dart";

import "../../api/vk/audio/get_lyrics.dart";
import "../../api/vk/shared.dart";
import "../../enums.dart";
import "../../provider/user.dart";
import "../../utils.dart";

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

  /// Создаёт из передаваемого объекта [ExtendedThumbnails] объект данного класа.
  static DBExtendedThumbnail fromExtendedThumbnail(
    ExtendedThumbnails thumbnail,
  ) =>
      DBExtendedThumbnail(
        photoSmall: thumbnail.photoSmall,
        photoMedium: thumbnail.photoMedium,
        photoBig: thumbnail.photoBig,
        photoMax: thumbnail.photoMax,
      );

  /// Возвращает копию данного класса в виде объекта [ExtendedThumbnails].
  @Ignore()
  ExtendedThumbnails get asExtendedThumbnails =>
      ExtendedThumbnails.fromDBExtendedThumbnail(this);

  @override
  String toString() => "DBExtendedThumbnails";

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

  /// Создаёт из передаваемого объекта [Thumbnails] объект данного класа.
  static DBThumbnails fromAPIPhoto(Thumbnails photo) => DBThumbnails(
        width: photo.width,
        height: photo.height,
        photo34: photo.photo34,
        photo68: photo.photo68,
        photo135: photo.photo135,
        photo270: photo.photo270,
        photo300: photo.photo300,
        photo600: photo.photo600,
        photo1200: photo.photo1200,
      );

  /// Возвращает копию данного класса в виде объекта [Thumbnails].
  @Ignore()
  Thumbnails get asThumbnails => Thumbnails.fromDBThumbnails(this);

  @override
  String toString() => "DBThumbnails $width*$height";

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

  /// Создаёт из передаваемого объекта [LyricTimestamp] объект данного класа.
  static DBLyricTimestamp fromLyricTimestamp(LyricTimestamp timestamp) =>
      DBLyricTimestamp(
        line: timestamp.line,
        interlude: timestamp.interlude,
        begin: timestamp.begin,
        end: timestamp.end,
      );

  /// Возвращает копию данного класса в виде объекта [LyricTimestamp].
  @Ignore()
  LyricTimestamp get asLyricTimestamp =>
      LyricTimestamp.fromDBLyricTimestamp(this);

  @override
  String toString() =>
      "DBLyricTimestamp \"${interlude ? "** interlude **" : line}\"";

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

  /// Создаёт из передаваемого объекта [Lyrics] объект данного класа.
  static DBLyrics fromLyrics(Lyrics lyrics) => DBLyrics(
        language: lyrics.language,
        timestamps: lyrics.timestamps
            ?.map(
              (LyricTimestamp timestamp) => timestamp.asDBTimestamp,
            )
            .toList(),
        text: lyrics.text,
      );

  /// Возвращает копию данного класса в виде объекта [Lyrics].
  @Ignore()
  Lyrics get asLyrics => Lyrics.fromDBLyrics(this);

  @override
  String toString() =>
      "DBLyrics $language with ${timestamps != null ? "${timestamps!.length} sync lyrics" : "text lyrics"}";

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

  /// Изображения альбома.
  final DBThumbnails? thumb;

  /// Создаёт из передаваемого объекта [Album] объект данного класа.
  static DBAlbum fromAudioAlbum(Album album) => DBAlbum(
        id: album.id,
        title: album.title,
        ownerID: album.ownerID,
        accessKey: album.accessKey,
        thumb: album.thumbnails?.asDBThumbnails,
      );

  /// Возвращает копию данного класса в виде объекта [Album].
  @Ignore()
  Album get asAudioAlbum => Album.fromDBAlbum(this);

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  String get mediaKey => "${ownerID}_$id";

  @override
  String toString() => "DBAlbum $mediaKey \"$title\"";

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
    this.thumb,
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

  /// Timestamp добавления аудиозаписи.
  final int? date;

  /// Информация об альбоме данной аудиозаписи.
  DBAlbum? album;

  /// Информация об обложке данного трека, полученного с ВКонтакте.
  DBExtendedThumbnail? vkThumbs;

  /// Информация об обложке данного трека, полученного с Deezer.
  DBExtendedThumbnail? deezerThumbs;

  /// Указывает наличие текста песни.
  final bool? hasLyrics;

  /// Информация о тексте песни.
  final DBLyrics? lyrics;

  /// ID жанра аудиозаписи. Список жанров описан [здесь](https://dev.vk.com/ru/reference/objects/audio-genres).
  final int? genreID;

  /// Указывает, кэширован ли данный трек.
  final bool? isCached;

  /// Указывает размер кэша трека в байтах.
  ///
  /// null если трек не кэширован ([isCached]).
  final int? cachedSize;

  /// {@macro ImageSchemeExtractor.colorInts}
  final List<int>? colorInts;

  /// {@macro ImageSchemeExtractor.scoredColorInts}
  final List<int>? scoredColorInts;

  /// {@macro ImageSchemeExtractor.frequentColorInt}
  final int? frequentColorInt;

  /// {@macro ImageSchemeExtractor.colorCount}
  final int? colorCount;

  /// Создаёт из передаваемого объекта [ExtendedAudio] объект данного класа.
  static DBAudio fromExtendedAudio(ExtendedAudio audio) => DBAudio(
        id: audio.id,
        ownerID: audio.ownerID,
        artist: audio.artist,
        title: audio.title,
        duration: audio.duration,
        accessKey: audio.accessKey,
        subtitle: audio.subtitle,
        isExplicit: audio.isExplicit,
        isRestricted: audio.isRestricted,
        date: audio.date,
        hasLyrics: audio.hasLyrics,
        lyrics: audio.lyrics?.asDBLyrics,
        genreID: audio.genreID,
        album: audio.album?.asDBAlbum,
        vkThumbs: audio.vkThumbs?.asDBExtendedThumbnail,
        deezerThumbs: audio.deezerThumbs?.asDBExtendedThumbnail,
        isCached: audio.isCached,
        cachedSize: audio.cachedSize,
        colorInts: audio.colorInts?.keys.toList(),
        scoredColorInts: audio.scoredColorInts,
        frequentColorInt: audio.frequentColorInt,
        colorCount: audio.colorCount,
      );

  /// Возвращает копию данного класса в виде объекта [ExtendedAudio].
  @Ignore()
  ExtendedAudio get asExtendedAudio => ExtendedAudio.fromDBAudio(this);

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
    int? date,
    DBAlbum? album,
    DBExtendedThumbnail? vkThumbs,
    DBExtendedThumbnail? deezerThumbs,
    bool? hasLyrics,
    DBLyrics? lyrics,
    int? genreID,
    bool? isCached,
    int? cachedSize,
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
        date: date ?? this.date,
        album: album ?? this.album,
        vkThumbs: vkThumbs ?? this.vkThumbs,
        deezerThumbs: deezerThumbs ?? this.deezerThumbs,
        hasLyrics: hasLyrics ?? this.hasLyrics,
        lyrics: lyrics ?? this.lyrics,
        genreID: genreID ?? this.genreID,
        isCached: isCached ?? this.isCached,
        cachedSize: cachedSize ?? this.cachedSize,
        colorInts: colorInts ?? this.colorInts,
        scoredColorInts: scoredColorInts ?? this.scoredColorInts,
        frequentColorInt: frequentColorInt ?? this.frequentColorInt,
        colorCount: colorCount ?? this.colorCount,
      );

  /// Возвращает строку, которая используется как идентификатор пользователя и медиа.
  @Ignore()
  String get mediaKey => "${ownerID}_$id";

  @override
  String toString() => "DBAudio $mediaKey $artist - $title";

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
    this.date,
    this.album,
    this.vkThumbs,
    this.deezerThumbs,
    this.hasLyrics,
    this.lyrics,
    this.genreID,
    this.isCached,
    this.cachedSize,
    this.colorInts,
    this.scoredColorInts,
    this.frequentColorInt,
    this.colorCount,
  });
}

/// Класс, олицетворяющий запись плейлиста в базе данных Isar.
@Collection()
class DBPlaylist {
  Id get isarId => fastHash(mediaKey);

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
  final int count;

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

  /// Создаёт объект [DBPlaylist] из передаваемого объекта [ExtendedPlaylist].
  static DBPlaylist fromExtendedPlaylist(ExtendedPlaylist playlist) =>
      DBPlaylist(
        id: playlist.id,
        ownerID: playlist.ownerID,
        type: playlist.type,
        title: playlist.title,
        description: playlist.description,
        subtitle: playlist.subtitle,
        count: playlist.count,
        accessKey: playlist.accessKey,
        isFollowing: playlist.isFollowing,
        photo: playlist.photo?.asDBThumbnails,
        audios: playlist.audios
            ?.map(
              (ExtendedAudio audio) => audio.asDBAudio,
            )
            .toList(),
        mixID: playlist.mixID,
        backgroundAnimationUrl: playlist.backgroundAnimationUrl,
        simillarity: playlist.simillarity,
        color: playlist.color,
        knownTracks: playlist.knownTracks
            ?.map(
              (ExtendedAudio audio) => audio.asDBAudio,
            )
            .toList(),
        isCachingAllowed: playlist.cacheTracks ?? false,
        colorInts: playlist.colorInts?.keys.toList(),
        scoredColorInts: playlist.scoredColorInts,
        frequentColorInt: playlist.frequentColorInt,
        colorCount: playlist.colorCount,
      );

  /// Возвращает копию данного класса в виде объекта [ExtendedPlaylist].
  @Ignore()
  ExtendedPlaylist get asExtendedPlaylist =>
      ExtendedPlaylist.fromDBPlaylist(this);

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
  String toString() =>
      "DBPlaylist $mediaKey with ${audios?.length}/$count tracks";

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
    required this.count,
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
