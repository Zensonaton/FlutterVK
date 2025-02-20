import "dart:async";

import "../../../provider/playlists.dart";
import "../../../provider/user.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [PlaylistsState] для обнаружения изменений в том плейлисте, который играет в данный момент.
class PlaylistModificationsPlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger =
      getLogger("PlaylistModificationsPlayerSubscriber");

  PlaylistModificationsPlayerSubscriber(Player player)
      : super("Playlist modifications", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      PlaylistsState.playlistModificationsStream.listen(onPlaylistModification),
    ];
  }

  /// События обновления плейлистов.
  void onPlaylistModification(ExtendedPlaylist playlist) async {
    final current = player.playlist;
    final isCurrent =
        playlist.ownerID == current?.ownerID && playlist.id == current?.id;
    if (!isCurrent) return;

    logger.d("Playlist modified");

    await player.updateCurrentPlaylist(playlist);
  }
}
