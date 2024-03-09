import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../../../consts.dart";
import "../../../../extensions.dart";
import "../../../../main.dart";
import "../../../../provider/user.dart";
import "../../../../services/logger.dart";
import "../../../../utils.dart";
import "../../../../widgets/page_route_builders.dart";
import "../../music.dart";
import "../playlist.dart";

/// Виджет, отображающий несколько треков из плейлиста раздела "Совпадения по вкусам".
class SimillarMusicPlaylistWidget extends StatefulWidget {
  /// Название плейлиста.
  final String name;

  /// Число от `0.0` до `1.0`, показывающий процент того, насколько плейлист схож с музыкальным вкусом текущего пользователя.
  final double simillarity;

  /// Список со строго первыми тремя треками из этого плейлиста, которые будут отображены.
  final List<ExtendedAudio> tracks;

  /// Цвет данного блока.
  ///
  /// Если не указан, то будет использоваться значение [ColorScheme.primaryContainer].
  final Color? color;

  /// Указывает, что музыка играет из этого плейлиста.
  final bool selected;

  /// Указывает, что плеер сейчас воспроизводит музыку.
  final bool currentlyPlaying;

  /// Вызывается при открытии плейлиста во весь экран.
  ///
  /// Вызывается при нажатии не по центру плейлиста. При нажатии по центру плейлиста запускается воспроизведение музыки, либо же она ставится на паузу, если музыка играет из этого плейлиста.
  final VoidCallback? onOpen;

  /// Действие, вызываемое при переключения паузы/возобновления при нажатии по центру плейлиста.
  ///
  /// Если не указывать, то возможность нажать на центр плейлиста будет выключена.
  final Function(bool)? onPlayToggle;

  const SimillarMusicPlaylistWidget({
    super.key,
    required this.name,
    required this.simillarity,
    required this.tracks,
    this.color,
    this.selected = false,
    this.currentlyPlaying = false,
    this.onOpen,
    this.onPlayToggle,
  });

  @override
  State<SimillarMusicPlaylistWidget> createState() =>
      _SimillarMusicPlaylistWidgetState();
}

class _SimillarMusicPlaylistWidgetState
    extends State<SimillarMusicPlaylistWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    assert(
      widget.tracks.length == 3,
      "Expected tracks amount to be 3, but got ${widget.tracks.length} instead",
    );

    final Color topColor =
        widget.color ?? Theme.of(context).colorScheme.primaryContainer;
    final bool selectedAndPlaying = widget.selected && widget.currentlyPlaying;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(
          globalBorderRadius * 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Верхняя часть такового плейлиста, в которой отображается название плейлиста, а так же его "схожесть".
          Padding(
            padding: const EdgeInsets.only(
              bottom: 14,
            ),
            child: Tooltip(
              message: widget.name,
              waitDuration: const Duration(
                seconds: 1,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  globalBorderRadius * 2,
                ),
                onTap: widget.onOpen,
                onSecondaryTap: widget.onOpen,
                onHover: (bool value) => setState(
                  () => isHovered = value,
                ),
                child: Stack(
                  children: [
                    // Название и прочая информация.
                    Container(
                      height: 90,
                      padding: const EdgeInsets.all(
                        10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            topColor,
                            topColor.withOpacity(0.8),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(
                          globalBorderRadius * 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // "80% совпадения".
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Процент.
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 4,
                                ),
                                child: Text(
                                  "${(widget.simillarity * 100).truncate()}%",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              // "совпадения".
                              Text(
                                AppLocalizations.of(context)!
                                    .music_simillarityPercentTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          // Название плейлиста.
                          Flexible(
                            child: Text(
                              widget.name,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.fade,
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Кнопки для совершения действий над этим плейлистом при наведении.
                    AnimatedOpacity(
                      opacity: isHovered ? 1.0 : 0.0,
                      duration: const Duration(
                        milliseconds: 300,
                      ),
                      curve: Curves.ease,
                      child: Container(
                        height: 90,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(
                            globalBorderRadius * 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Запуск воспроизведения.
                            IconButton(
                              icon: Icon(
                                selectedAndPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 32,
                                color: Colors.white,
                              ),
                              onPressed: isHovered
                                  ? () => widget.onPlayToggle?.call(
                                        !selectedAndPlaying,
                                      )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Отображение треков в этом плейлисте.
          for (ExtendedAudio audio in widget.tracks)
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: 8,
              ),
              child: AudioTrackTile(
                audio: audio,
                selected: audio == player.currentAudio,
                currentlyPlaying: player.loaded && player.playing,
                isLoading: player.buffering,
                glowIfSelected: true,
                forceAvailable: true,
              ),
            ),
          const SizedBox(
            height: 4,
          ),
        ],
      ),
    );
  }
}

/// Виджет, показывающий раздел "Совпадения по вкусам".
class SimillarMusicBlock extends StatefulWidget {
  static AppLogger logger = getLogger("SimillarMusicBlock");

  const SimillarMusicBlock({
    super.key,
  });

  @override
  State<SimillarMusicBlock> createState() => _SimillarMusicBlockState();
}

class _SimillarMusicBlockState extends State<SimillarMusicBlock> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Изменения состояния остановки/запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
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
    final UserProvider user = Provider.of<UserProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Совпадения по вкусам".
        Padding(
          padding: const EdgeInsets.only(
            bottom: 14,
          ),
          child: Text(
            AppLocalizations.of(context)!.music_similarMusicChip,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Содержимое.
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SizedBox(
            height: 284,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: user.simillarPlaylists.isEmpty
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: user.simillarPlaylists.isNotEmpty
                  ? user.recommendationPlaylists.length
                  : null,
              itemBuilder: (BuildContext context, int index) {
                final List<ExtendedPlaylist> simillarPlaylists = user
                    .simillarPlaylists
                    .sorted((a, b) => b.simillarity!.compareTo(a.simillarity!));

                // Skeleton loader.
                if (simillarPlaylists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: Skeletonizer(
                      child: SimillarMusicPlaylistWidget(
                        name:
                            fakePlaylistNames[index % fakePlaylistNames.length],
                        simillarity: 0.9,
                        tracks: List.generate(
                          3,
                          (int index) => ExtendedAudio(
                            id: -1,
                            ownerID: -1,
                            title:
                                fakeTrackNames[index % fakeTrackNames.length],
                            artist: fakeTrackNames[
                                (index + 1) % fakeTrackNames.length],
                            duration: 60 * 3,
                            accessKey: "",
                            url: "",
                            date: 0,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Настоящие данные.
                final ExtendedPlaylist playlist = simillarPlaylists[index];

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: SimillarMusicPlaylistWidget(
                    name: playlist.title!,
                    simillarity: playlist.simillarity!,
                    color: HexColor.fromHex(playlist.color!),
                    tracks: playlist.knownTracks!,
                    selected: player.currentPlaylist == playlist,
                    currentlyPlaying: player.playing && player.loaded,
                    onOpen: () => Navigator.push(
                      context,
                      Material3PageRoute(
                        builder: (context) => PlaylistInfoRoute(
                          playlist: playlist,
                        ),
                      ),
                    ),
                    onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                      context,
                      playlist,
                      playing,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
