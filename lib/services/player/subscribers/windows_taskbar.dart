import "dart:async";

import "package:windows_taskbar/windows_taskbar.dart";

import "../../../enums.dart";
import "../../../extensions.dart";
import "../../../provider/l18n.dart";
import "../../../provider/user.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для отображения кнопок управления в Windows Taskbar.
///
/// Данный [PlayerSubscriber] выключен, поскольку иногда происходят ошибки при обновлении кнопок, из-за чего приложение зависает.
class WindowsTaskbarPlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("WindowsTaskbarPlayerSubscriber");

  WindowsTaskbarPlayerSubscriber(Player player)
      : super("Windows Taskbar", player);

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.isLoadedStream.listen(onIsLoaded),
      player.isPlayingStream.listen(onIsPlaying),
      player.isBufferingStream.listen(onIsBuffering),
      player.isShufflingStream.listen(onIsShuffling),
      player.isRepeatingStream.listen(onIsRepeating),
      player.audioStream.listen(onAudio),
      player.playlistStream.listen(onPlaylist),
    ];
  }

  /// Возвращает путь к иконке.
  static ThumbnailToolbarAssetIcon _getTaskbarIcon(String name) =>
      ThumbnailToolbarAssetIcon("assets/taskbar/$name.ico");

  /// Возвращает [ThumbnailToolbarButton.mode] для кнопки.
  static int _getButtonMode(bool enabled) =>
      enabled ? 0x0 : ThumbnailToolbarButtonMode.disabled;

  /// События запуска плеера.
  void onIsLoaded(bool isLoaded) async {
    updatePlaybackStatus();
  }

  /// События паузы/воспроизведения музыки.
  void onIsPlaying(bool isPlaying) async {
    updatePlaybackStatus();
  }

  /// События буфферизации музыки.
  void onIsBuffering(bool isBuffering) async {
    updatePlaybackStatus();
  }

  /// События изменения режима перемешивания треков.
  void onIsShuffling(bool isShuffling) async {
    updatePlaybackStatus();
  }

  /// События изменения режима повторения треков.
  void onIsRepeating(bool isRepeating) async {
    updatePlaybackStatus();
  }

  /// События изменения трека, играющий в данный момент.
  void onAudio(ExtendedAudio audio) async {
    updatePlaybackStatus();
  }

  /// События изменения плейлиста.
  void onPlaylist(ExtendedPlaylist playlist) async {
    updatePlaybackStatus();
  }

  /// Обновляет отображаемый статус воспроизведения музыки.
  void updatePlaybackStatus() async {
    if (!player.isLoaded) {
      try {
        await WindowsTaskbar.resetThumbnailToolbar();
      } catch (error, stackTrace) {
        logger.e(
          "Failed to reset taskbar state, no updates will be made:",
          error: error,
          stackTrace: stackTrace,
        );
      }

      return;
    }

    final l18n = player.ref.read(l18nProvider);
    final isPlaying = player.isPlaying;
    final isShuffling = player.isShuffling;
    final isRepeating = player.isRepeating;
    final playlist = player.playlist;
    final audio = player.audio;
    final isAudioMix = playlist?.type == PlaylistType.audioMix;
    final isRecommended = playlist?.isRecommendationTypePlaylist == true;
    final isLiked = audio?.isLiked == true;

    try {
      await WindowsTaskbar.setThumbnailToolbar(
        [
          // Дизлайк.
          ThumbnailToolbarButton(
            _getTaskbarIcon("dislike"),
            l18n.dislike_track_action,
            () async {
              await audio!.dislike(player.ref);

              await player.next();
            },
            mode: _getButtonMode(isRecommended),
          ),

          // Перемешка.
          ThumbnailToolbarButton(
            _getTaskbarIcon("shuffle_${isShuffling ? "on" : "off"}"),
            isShuffling
                ? l18n.disable_shuffle_action
                : l18n.enable_shuffle_action,
            player.toggleShuffle,
            mode: _getButtonMode(!isAudioMix && !isRecommended),
          ),

          // Предыдущий.
          ThumbnailToolbarButton(
            _getTaskbarIcon("previous"),
            l18n.previous_track_action,
            player.smartPrevious,
          ),

          // Пауза/воспроизведение.
          ThumbnailToolbarButton(
            _getTaskbarIcon(isPlaying ? "pause" : "play"),
            isPlaying ? l18n.pause_track_action : l18n.play_track_action,
            player.togglePlay,
          ),

          // Следующий.
          ThumbnailToolbarButton(
            _getTaskbarIcon("next"),
            l18n.next_track_action,
            player.next,
          ),

          // Повтор.
          ThumbnailToolbarButton(
            _getTaskbarIcon("repeat_${isRepeating ? "on" : "off"}"),
            isRepeating
                ? l18n.disable_repeat_action
                : l18n.enable_repeat_action,
            player.toggleRepeat,
          ),

          // Лайк.
          ThumbnailToolbarButton(
            _getTaskbarIcon("favorite_${isLiked ? "on" : "off"}"),
            isLiked
                ? l18n.remove_favorite_track_action
                : l18n.add_track_as_liked,
            () {
              audio!.likeDislikeRestore(player.ref, sourcePlaylist: playlist!);
            },
          ),
        ],
      );
    } catch (error, stackTrace) {
      logger.e(
        "Failed to update taskbar state, no updates will be made:",
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
