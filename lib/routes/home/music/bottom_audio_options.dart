import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";

import "../../../main.dart";
import "../../../provider/user.dart";
import "../../../services/audio_player.dart";
import "../../../services/download_manager.dart";
import "../../../services/logger.dart";
import "../../../widgets/dialogs.dart";
import "../music.dart";
import "track_info.dart";

/// Диалог, появляющийся снизу экрана, дающий пользователю действия над выбранным треком.
///
/// Пример использования:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (BuildContext context) => const BottomAudioOptionsDialog(...),
/// ),
/// ```
class BottomAudioOptionsDialog extends StatefulWidget {
  /// Трек типа [ExtendedAudio], над которым производится манипуляция.
  final ExtendedAudio audio;

  /// Плейлист, в котором находится данный трек.
  final ExtendedPlaylist playlist;

  const BottomAudioOptionsDialog({
    super.key,
    required this.audio,
    required this.playlist,
  });

  @override
  State<BottomAudioOptionsDialog> createState() =>
      _BottomAudioOptionsDialogState();
}

class _BottomAudioOptionsDialogState extends State<BottomAudioOptionsDialog> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playingStream.listen(
        (bool playing) => setState(() {}),
      ),

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),
    ];
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLogger logger = getLogger("BottomAudioOptionsDialog");
    final UserProvider user = Provider.of<UserProvider>(context);

    return DraggableScrollableSheet(
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return Container(
          width: 500,
          height: 300,
          padding: const EdgeInsets.all(24),
          child: SizedBox.expand(
            child: ListView(
              controller: controller,
              children: [
                // Трек.
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: AudioTrackTile(
                    audio: widget.audio,
                    selected: widget.audio == player.currentAudio,
                    currentlyPlaying: player.loaded && player.playing,
                  ),
                ),

                // Разделитель.
                const Padding(
                  padding: EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Divider(),
                ),

                // Редактировать данные трека.
                ListTile(
                  enabled: widget.audio.album == null &&
                      widget.audio.ownerID == user.id!,
                  onTap: () {
                    if (!networkRequiredDialog(context)) return;

                    Navigator.of(context).pop();

                    showDialog(
                      context: context,
                      builder: (BuildContext context) => TrackInfoEditDialog(
                        audio: widget.audio,
                      ),
                    );
                  },
                  leading: const Icon(
                    Icons.edit,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.music_detailsEditTitle,
                  ),
                ),

                // Удалить из текущего плейлиста.
                ListTile(
                  onTap: () {
                    if (!networkRequiredDialog(context)) return;

                    showWipDialog(context);
                  },
                  leading: const Icon(
                    Icons.playlist_remove,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.music_detailsDeleteTrackTitle,
                  ),
                ),

                // Добавить в другой плейлист.
                ListTile(
                  onTap: () {
                    if (!networkRequiredDialog(context)) return;

                    showWipDialog(context);
                  },
                  leading: const Icon(
                    Icons.playlist_add,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!
                        .music_detailsAddToOtherPlaylistTitle,
                  ),
                ),

                // Добавить в очередь.
                ListTile(
                  onTap: () async {
                    await player.addNextToQueue(
                      widget.audio,
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.general_addedToQueue,
                        ),
                        duration: const Duration(
                          seconds: 3,
                        ),
                      ),
                    );

                    Navigator.of(context).pop();
                  },
                  enabled: widget.audio.canPlay,
                  leading: const Icon(
                    Icons.queue_music,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.music_detailsPlayNextTitle,
                  ),
                ),

                // Кэшировать этот трек.
                ListTile(
                  onTap: () async {
                    if (!networkRequiredDialog(context)) return;

                    Navigator.of(context).pop();

                    // Загружаем трек.
                    try {
                      await CacheItem.cacheTrack(
                        widget.audio,
                        widget.playlist,
                        true,
                        user,
                      );
                    } catch (error, stackTrace) {
                      // ignore: use_build_context_synchronously
                      showLogErrorDialog(
                        "Ошибка при принудительном кэшировании отдельного трека: ",
                        error,
                        stackTrace,
                        logger,
                        context,
                      );

                      return;
                    }

                    if (!context.mounted) return;

                    user.markUpdated();
                  },
                  enabled: !widget.audio.isRestricted &&
                      !(widget.audio.isCached ?? false),
                  leading: const Icon(
                    Icons.download,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.music_detailsCacheTrackTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!
                        .music_detailsCacheTrackDescription,
                  ),
                ),

                // Перезалить с Youtube.
                ListTile(
                  onTap: () {
                    if (!networkRequiredDialog(context)) return;

                    showWipDialog(context);
                  },
                  leading: const Icon(
                    Icons.rotate_left,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!
                        .music_detailsReuploadFromYoutubeTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!
                        .music_detailsReuploadFromYoutubeDescription,
                  ),
                ),

                // Debug-опции.
                if (kDebugMode) ...[
                  ListTile(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: widget.audio.mediaKey,
                        ),
                      );

                      Navigator.of(context).pop();
                    },
                    leading: const Icon(
                      Icons.link,
                    ),
                    title: const Text(
                      "Скопировать ID трека",
                    ),
                    subtitle: const Text(
                      "Debug-режим",
                    ),
                  ),
                  if (Platform.isWindows)
                    ListTile(
                      onTap: () async {
                        Navigator.of(context).pop();

                        final File path =
                            await CachedStreamedAudio.getCachedAudioByKey(
                          widget.audio.mediaKey,
                        );
                        await Process.run(
                          "explorer.exe",
                          ["/select,", path.path],
                        );
                      },
                      enabled: widget.audio.isCached ?? false,
                      leading: const Icon(
                        Icons.folder_open,
                      ),
                      title: const Text(
                        "Открыть папку с треком",
                      ),
                      subtitle: const Text(
                        "Debug-режим",
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
