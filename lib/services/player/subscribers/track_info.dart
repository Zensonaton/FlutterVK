import "dart:async";

import "package:cached_network_image/cached_network_image.dart";

import "../../../provider/color.dart";
import "../../../provider/playlists.dart";
import "../../../provider/preferences.dart";
import "../../../provider/user.dart";
import "../../cache_manager.dart";
import "../../download_manager.dart";
import "../../image_to_color_scheme.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для загрузки дополнительных данных о текущем, потом о следующем и предыдущем треках.
///
/// Данные, загружаемые этим классом:
/// - Кэширование обложки с ВК и Deezer.
/// - Получение цветов обложки.
/// - Текст песни с ВК и LRCLib.
///
/// Сначала загружается информация о текущем треке, затем о следующем, и потом, предыдущем.
class TrackInfoPlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("TrackInfoPlayerSubscriber");

  /// Список из относительных индексов треков в очереди воспроизведения, которые будут загружены.
  static const List<int> _loadTrackInfoIndexes = [0, 1, -1];

  TrackInfoPlayerSubscriber(Player player) : super("Track info", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.audioStream.listen(onAudio),
    ];
  }

  /// Метод, получающий цвета из обложки трека [audio].
  Future<ImageSchemeExtractor?> getColorScheme(
    ExtendedAudio audio,
    bool setAsCurrent,
  ) async {
    final trackImageInfoNotifier =
        player.ref.read(trackSchemeInfoProvider.notifier);

    if (audio.thumbnail == null) return null;

    ImageSchemeExtractor? extractedColors;

    // Если цвета обложки уже были получены, и они хранятся в БД, то просто возвращаем их.
    if (audio.colorCount != null) {
      extractedColors = ImageSchemeExtractor(
        colorInts: audio.colorInts!,
        scoredColorInts: audio.scoredColorInts!,
        frequentColorInt: audio.frequentColorInt!,
        colorCount: audio.colorCount!,
      );
    }

    extractedColors ??= await ImageSchemeExtractor.fromImageProvider(
      CachedNetworkImageProvider(
        audio.smallestThumbnail!,
        cacheKey: "${audio.mediaKey}small",
        cacheManager: CachedAlbumImagesManager.instance,
      ),
    );

    if (setAsCurrent) {
      trackImageInfoNotifier.fromExtractor(extractedColors);
    }

    return extractedColors;
  }

  /// Метод, загружающий данные по [audio] (обложки, цвета, ...) и сохраняющий их в БД.
  Future<void> loadAudioData(ExtendedAudio audio) async {
    final playlistsNotifier = player.ref.read(playlistsProvider.notifier);
    final preferences = player.ref.read(preferencesProvider);
    final playlist = player.playlist!.copyWith();

    bool isCurrent() => player.audio?.id == audio.id;

    // Пытаемся получить цвета обложки трека.
    // Метод [getColorScheme] вернёт null, если обложки нет.
    ImageSchemeExtractor? extractedColors =
        await getColorScheme(audio, isCurrent());

    // Загружаем метаданные трека (его обложки, текст песни, ...)
    final newAudio = await PlaylistCacheDownloadItem.downloadWithMetadata(
      player.ref,
      playlist,
      audio,
      downloadAudio: false,
      deezerThumbnails: preferences.deezerThumbnails,
      lrcLibLyricsEnabled: preferences.lrcLibEnabled,
      appleMusicThumbs: preferences.appleMusicAnimatedCovers,
    );
    if (newAudio == null) return;

    // Повторно пытаемся получить цвета обложек трека, если они не были загружены ранее.
    extractedColors ??= await getColorScheme(newAudio, isCurrent());

    // Сохраняем новую версию трека.
    await playlistsNotifier.updatePlaylist(
      playlist.basicCopyWith(
        audiosToUpdate: [
          newAudio.basicCopyWith(
            vkLyrics: newAudio.lyrics,
            lrcLibLyrics: newAudio.lyrics,
            deezerThumbs: newAudio.deezerThumbs,
            appleMusicThumbs: newAudio.appleMusicThumbs,
            colorInts: extractedColors?.colorInts,
            scoredColorInts: extractedColors?.scoredColorInts,
            frequentColorInt: extractedColors?.frequentColorInt,
            colorCount: extractedColors?.colorCount,
          ),
        ],
      ),
      saveInDB: true,
    );
  }

  /// События изменения трека, играющий в данный момент.
  void onAudio(ExtendedAudio audio) async {
    for (final index in _loadTrackInfoIndexes) {
      final audio = player.audioAtIndex(player.index! + index);
      if (audio == null) continue;

      await loadAudioData(audio);
    }
  }
}
