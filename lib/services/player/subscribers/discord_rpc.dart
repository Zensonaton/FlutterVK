import "dart:async";
import "dart:io";

import "package:discord_rpc/discord_rpc.dart";

import "../../../consts.dart";
import "../../../provider/user.dart";
import "../../../utils.dart";
import "../../logger.dart";
import "../player.dart";
import "../subscriber.dart";

/// Класс подписчика на события [Player] для работы с Discord RPC.
class DiscordRPCPlayerSubscriber extends PlayerSubscriber {
  static final AppLogger logger = getLogger("DiscordRPCPlayerSubscriber");

  /// ID приложения Discord, используемый для работы Rich Presence.
  static const String discordAppID = "1195224178996027412";

  DiscordRPCPlayerSubscriber(Player player) : super("Discord RPC", player);

  /// Объект Discord RPC для работы с Rich Presence.
  late final DiscordRPC _rpc;

  @override
  Future<void> initialize() async {
    if (!(Platform.isWindows || Platform.isLinux)) {
      throw UnsupportedError(
        "Discord RPC is only supported on Windows and Linux.",
      );
    }

    DiscordRPC.initialize();
    _rpc = DiscordRPC(
      applicationId: discordAppID,
    );
  }

  @override
  Future<void> dispose() async {
    _rpc.clearPresence();
    _rpc.shutDown();
  }

  @override
  List<StreamSubscription> subscribe(Player player) {
    return [
      player.isLoadedStream.listen(onIsLoaded),
      player.isPlayingStream.listen(onIsPlaying),
      player.isBufferingStream.listen(onIsBuffering),
      player.audioStream.listen(onAudio),
      player.seekStream.listen(onSeek),
      player.isDiscordRPCEnabledStream.listen(onIsDiscordRPCEnabled),
    ];
  }

  /// События запуска плеера.
  void onIsLoaded(bool isLoaded) async {
    _rpc.clearPresence();

    if (isLoaded) {
      _rpc.start(autoRegister: true);

      return;
    }

    _rpc.shutDown();
  }

  /// События паузы/воспроизведения музыки.
  void onIsPlaying(bool isPlaying) async {
    updatePlaybackStatus();
  }

  /// События буфферизации музыки.
  void onIsBuffering(bool isBuffering) async {
    updatePlaybackStatus();
  }

  /// События изменения трека, играющий в данный момент.
  void onAudio(ExtendedAudio audio) async {
    updatePlaybackStatus();
  }

  /// События резкого скачка позиции трека.
  void onSeek(Duration position) async {
    updatePlaybackStatus();
  }

  /// События изменения настроек Discord RPC.
  void onIsDiscordRPCEnabled(bool isEnabled) async {
    onIsLoaded(isEnabled);

    if (player.isLoaded) {
      updatePlaybackStatus();
    }
  }

  /// Обновляет отображаемый статус воспроизведения музыки.
  void updatePlaybackStatus() async {
    final audio = player.audio;
    final playing = player.isPlaying && !player.isBuffering;
    final position = player.position;

    if (!player.isDiscordRPCEnabled || !playing) {
      _rpc.clearPresence();

      return;
    }

    String? audioTitle;
    String? audioFullTitle;
    String? audioArtist;
    if (audio != null) {
      audioTitle = audio.title;
      audioArtist = audio.artist;
      if (audio.subtitle != null) {
        audioTitle += " (${audio.subtitle})";
      }
      if (audio.isExplicit) {
        audioTitle += " $explicitChar";
      }
      audioFullTitle = "$audioTitle • $audioArtist";
    }

    int? startTimestamp;
    if (playing) {
      startTimestamp = getUnixTimestamp() - position.inSeconds;
    }

    _rpc.updatePresence(
      DiscordPresence(
        state: audioTitle,
        details: audioArtist,
        largeImageKey: "flutter-vk-logo",
        largeImageText: appName,
        smallImageKey: "playing",
        smallImageText: audioFullTitle,
        startTimeStamp: startTimestamp,
      ),
    );
  }
}
