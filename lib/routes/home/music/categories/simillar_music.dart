import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/tags/styled_text_tag.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../../../consts.dart";
import "../../../../extensions.dart";
import "../../../../main.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/player_events.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/preferences.dart";
import "../../../../provider/user.dart";
import "../../../../services/logger.dart";
import "../../../../utils.dart";
import "../../../../widgets/audio_track.dart";
import "../../../../widgets/music_category.dart";
import "../playlist.dart";

/// Виджет, отображающий несколько треков из плейлиста раздела "Совпадения по вкусам".
class SimillarMusicPlaylistWidget extends HookConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (tracks.length != 3) {
      throw ArgumentError(
        "Expected tracks amount to be 3, but got ${tracks.length} instead",
      );
    }

    final l18n = ref.watch(l18nProvider);

    final isHovered = useState(false);

    final Color topColor =
        color ?? Theme.of(context).colorScheme.primaryContainer;
    final bool selectedAndPlaying = selected && currentlyPlaying;

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
          Tooltip(
            message: name,
            waitDuration: const Duration(
              seconds: 1,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(
                globalBorderRadius * 2,
              ),
              onTap: onOpen,
              onSecondaryTap: onOpen,
              onHover: (bool value) => isHovered.value = value,
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
                          topColor.withValues(alpha: 0.8),
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
                        // Процент совпадения.
                        SizedBox(
                          width: double.infinity,
                          child: StyledText(
                            text: l18n.simillarity_percent(
                              simillarity: (simillarity * 100).truncate(),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            tags: {
                              "bold": StyledTextTag(
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            },
                          ),
                        ),

                        // Название плейлиста.
                        Flexible(
                          child: Text(
                            name,
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
                    opacity: isHovered.value ? 1.0 : 0.0,
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    curve: Curves.easeInOutCubicEmphasized,
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
                            onPressed: isHovered.value
                                ? () => onPlayToggle?.call(
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
          const Gap(14),

          // Отображение треков в этом плейлисте.
          for (ExtendedAudio audio in tracks)
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: 8,
              ),
              child: AudioTrackTile(
                audio: audio,
                isSelected: player.playing && audio == player.currentAudio,
                isPlaying: player.loaded && player.playing,
                isLoading: player.buffering && audio == player.currentAudio,
                showDuration: false,
              ),
            ),
        ],
      ),
    );
  }
}

/// Виджет, показывающий раздел "Совпадения по вкусам".
class SimillarMusicBlock extends HookConsumerWidget {
  static final AppLogger logger = getLogger("SimillarMusicBlock");

  const SimillarMusicBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(simillarPlaylistsProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerStateProvider);
    ref.watch(playerLoadedStateProvider);

    return MusicCategory(
      title: l18n.simillar_music_chip,
      onDismiss: () {
        final preferences = ref.read(preferencesProvider.notifier);

        preferences.setSimilarMusicChipEnabled(false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l18n.category_closed(
                category: l18n.simillar_music_chip,
              ),
            ),
            duration: const Duration(
              seconds: 5,
            ),
            action: SnackBarAction(
              label: l18n.general_restore,
              onPressed: () => preferences.setSimilarMusicChipEnabled(true),
            ),
          ),
        );
      },
      children: [
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SizedBox(
            height: 284,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: playlists == null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: playlists?.length ?? 10,
              separatorBuilder: (BuildContext context, int index) {
                return const Gap(8);
              },
              itemBuilder: (BuildContext context, int index) {
                // Skeleton loader.
                if (playlists == null) {
                  return Skeletonizer(
                    child: SimillarMusicPlaylistWidget(
                      name: fakePlaylistNames[index % fakePlaylistNames.length],
                      simillarity: 0.9,
                      tracks: List.generate(
                        3,
                        (int index) => ExtendedAudio(
                          id: -1,
                          ownerID: -1,
                          title: fakeTrackNames[index % fakeTrackNames.length],
                          artist: fakeTrackNames[
                              (index + 1) % fakeTrackNames.length],
                          duration: 60 * 3,
                          accessKey: "",
                          url: "",
                          date: 0,
                        ),
                      ),
                    ),
                  );
                }

                // Настоящие данные.
                final ExtendedPlaylist playlist = playlists[index];

                return SimillarMusicPlaylistWidget(
                  name: playlist.title!,
                  simillarity: playlist.simillarity!,
                  color: HexColor.fromHex(
                    playlist.color!,
                  ),
                  tracks: playlist.knownTracks!,
                  selected:
                      player.currentPlaylist?.mediaKey == playlist.mediaKey,
                  currentlyPlaying: player.playing && player.loaded,
                  onOpen: () => context.push(
                    "/music/playlist/${playlist.ownerID}/${playlist.id}",
                  ),
                  onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                    ref,
                    context,
                    playlist,
                    playing,
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
