import "dart:async";

import "../../../api/vk/shared.dart";
import "../../../enums.dart";
import "../../../provider/playlists.dart";
import "../../../provider/user.dart";
import "../../../provider/vk_api.dart";
import "../../../utils.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для загрузки дополнительных треков для плейлистов типа [PlaylistType.audioMix].
class AudioMixPlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("AudioMixPlayerSubscriber");

  /// Указывает минимальное треков из аудио микса, которое обязано быть в очереди плеера.
  ///
  /// Если очередь воспроизведения состоит из меньшего количества треков, то очередь будет восполнена этим значением.
  static const int requiredMixAudiosCount = 3;

  AudioMixPlayerSubscriber(Player player) : super("Audio mix", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.audioStream.listen(onAudio),
    ];
  }

  /// События изменения трека, играющий в данный момент.
  void onAudio(ExtendedAudio audio) async {
    final api = player.ref.read(vkAPIProvider);
    final playlists = player.ref.read(playlistsProvider.notifier);

    if (player.playlist?.type != PlaylistType.audioMix) return;

    final queueItemCount = player.queue?.length ?? 0;
    final index = player.index!;
    final tracksBeforeEnd = queueItemCount - index;
    final tracksToAdd = clampInt(
      requiredMixAudiosCount - tracksBeforeEnd,
      0,
      requiredMixAudiosCount,
    );

    logger.d(
      "Mix index: $index/$queueItemCount, will add $tracksToAdd tracks",
    );

    if (tracksToAdd <= 0) return;

    try {
      final List<Audio> response =
          await api.audio.getStreamMixAudiosWithAlbums(count: tracksToAdd);
      if (response.length != tracksToAdd) {
        throw Exception(
          "Invalid response length, expected $tracksToAdd, got ${response.length} instead",
        );
      }

      final List<ExtendedAudio> newAudios = response
          .map(
            (audio) => ExtendedAudio.fromAPIAudio(audio),
          )
          .toList();

      await playlists.updatePlaylist(
        player.playlist!.basicCopyWith(
          audiosToUpdate: newAudios,
          count: queueItemCount + tracksToAdd,
        ),
      );

      // Треки добавляются в очередь благодаря методу .updatePlaylist.
    } catch (error, stackTrace) {
      logger.e(
        "Couldn't load audio mix tracks: ",
        error: error,
        stackTrace: stackTrace,
      );

      return;
    }

    logger.d(
      "Successfully added $tracksToAdd tracks to mix queue (current: ${player.queue?.length})",
    );
  }
}
