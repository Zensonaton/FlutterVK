import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:lottie/lottie.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../../../consts.dart";
import "../../../../main.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/player_events.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/user.dart";
import "../../../../services/logger.dart";
import "../../../../utils.dart";
import "../playlist.dart";

/// Указывает минимальное треков из аудио микса, которое обязано быть в очереди плеера. Если очередь плейлиста состоит из меньшего количества треков, то очередь будет восполнена этим значением.
const int minMixAudiosCount = 3;

/// Метод, вызываемый при нажатии нажатии по аудио микс-плейлисту (VK Mix). Данный метод либо ставит плейлист на паузу, либо возобновляет воспроизведение.
Future<void> onMixPlayToggle(
  BuildContext context,
  ExtendedPlaylist playlist,
  bool playing,
) async {
  assert(
    playlist.isAudioMixPlaylist,
    "onMixPlayToggle can only be called for audio mix playlists",
  );

  // final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  // final AppLogger logger = getLogger("onMixPlayToggle");

  // // Уточняем, разрешает ли пользователь отправку информации для работы рекомендаций.
  // if (!(await recommendationsStatsAllowedDialog(context, playlist))) return;

  // // Если у нас играет этот же плейлист, то тогда мы попросту должны поставить на паузу/убрать паузу.
  // if (player.currentPlaylist == playlist) {
  //   return await player.playOrPause(playing);
  // }

  // // Мы запускаем этот аудио микс впервые, поэтому мы должны загрузить несколько его треков.
  // if (context.mounted) LoadingOverlay.of(context).show();

  // try {
  //   final APIAudioGetStreamMixAudiosResponse response =
  //       await user.audioGetStreamMixAudiosWithAlbums(count: minMixAudiosCount);
  //   raiseOnAPIError(response);

  //   playlist.audios = response.response!
  //       .map(
  //         (audio) => ExtendedAudio.fromAPIAudio(audio),
  //       )
  //       .toList();
  //   playlist.count = response.response!.length;
  // } catch (e, stackTrace) {
  //   showLogErrorDialog(
  //     "Ошибка при загрузке информации по аудио миксу: ",
  //     e,
  //     stackTrace,
  //     logger,
  //     // ignore: use_build_context_synchronously
  //     context,
  //   );

  //   return;
  // } finally {
  //   if (context.mounted) {
  //     LoadingOverlay.of(context).hide();
  //   }
  // }

  // // Всё ок, запускаем воспроизведение, отключив при этом shuffle, а так же зацикливание плейлиста.
  // if (player.shuffleModeEnabled) {
  //   await player.setShuffle(false);
  // }
  // if (player.loopMode != LoopMode.off) {
  //   await player.setLoop(LoopMode.off);
  // }

  // await player.setPlaylist(
  //   playlist,
  //   setLoopAll: false,
  // );
}

/// Fallback-виджет, отображаемый вместо аудио миксов по типу VK Mix.
class FallbackMixPlaylistWidget extends StatelessWidget {
  const FallbackMixPlaylistWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      color: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

/// Виджет, отображающий плейлист типа "VK Mix" или подобный.
class LivePlaylistWidget extends StatelessWidget {
  /// Название плейлиста.
  final String title;

  /// Описание плейлиста.
  final String? description;

  /// URL на Lottie-анимацию, которая используется для фона.
  final String? lottieUrl;

  /// Указывает, что будет использоваться большой размер данного плейлиста.
  final bool bigLayout;

  /// Указывает, что музыка играет из этого плейлиста.
  final bool selected;

  /// Указывает, что плеер сейчас воспроизводит музыку.
  final bool currentlyPlaying;

  /// Действие, вызываемое при переключения паузы/возобновления при нажатии по центру плейлиста.
  ///
  /// Если не указывать, то возможность нажать на центр плейлиста будет выключена.
  final Function(bool)? onPlayToggle;

  const LivePlaylistWidget({
    super.key,
    required this.title,
    this.description,
    this.lottieUrl,
    this.bigLayout = false,
    this.selected = false,
    this.currentlyPlaying = false,
    this.onPlayToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool selectedAndPlaying = selected && currentlyPlaying;

    return AnimatedContainer(
      height: bigLayout ? 250 : 200,
      width: double.infinity,
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.ease,
      child: InkWell(
        onTap: () => onPlayToggle?.call(
          !selectedAndPlaying,
        ),
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            globalBorderRadius,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Фоновая анимация, если задана ссылка на это.
              if (lottieUrl != null)
                Lottie.network(
                  lottieUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.fill,
                  addRepaintBoundary: true,
                  backgroundLoading: true,
                  frameBuilder: (
                    BuildContext context,
                    Widget child,
                    LottieComposition? composition,
                  ) {
                    return child;
                  },
                  animate: true,
                  repeat: true,
                ),

              // Заменяющий фоновый анимацию контейнер.
              if (lottieUrl == null) const FallbackMixPlaylistWidget(),

              // Текст, а так же кнопка запуска.
              Theme(
                data: ThemeData(
                  brightness: Brightness.dark,
                ),
                child: SizedBox(
                  width: bigLayout ? 500 : 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Запуск воспроизведения.
                      IconButton.filled(
                        icon: Icon(
                          selectedAndPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        iconSize: bigLayout ? 36 : null,
                        onPressed: () => onPlayToggle?.call(
                          !selectedAndPlaying,
                        ),
                      ),
                      const Gap(12),

                      // "Слушать VK Mix".
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(2),

                      // Описание плейлиста, при наличии.
                      if (description != null)
                        Text(
                          description!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет, отображающий "плоский" плейлист из раздела "Какой сейчас вайб?" ВКонтакте.
class MoodPlaylistWidget extends StatelessWidget {
  /// Название плейлиста.
  final String title;

  /// Описание плейлиста. Отображается при наведении.
  final String? description;

  /// URL на изображение плейлиста.
  final String? backgroundUrl;

  /// Поле, спользуемое как ключ для кэширования [backgroundUrl].
  final String? cacheKey;

  /// Указывает, что музыка играет из этого плейлиста.
  final bool selected;

  /// Указывает, что плеер сейчас воспроизводит музыку.
  final bool currentlyPlaying;

  /// Действие, вызываемое при переключения паузы/возобновления при нажатии по центру плейлиста.
  ///
  /// Если не указывать, то возможность нажать на центр плейлиста будет выключена.
  final Function(bool)? onPlayToggle;

  const MoodPlaylistWidget({
    super.key,
    required this.title,
    this.description,
    this.backgroundUrl,
    this.cacheKey,
    this.selected = false,
    this.currentlyPlaying = false,
    this.onPlayToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (backgroundUrl != null) {
      assert(
        cacheKey != null,
        "Expected cacheKey to be set",
      );
    }

    final bool selectedAndPlaying = selected && currentlyPlaying;

    return AnimatedContainer(
      width: 200,
      height: 50,
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.ease,
      decoration: BoxDecoration(
        boxShadow: [
          if (selected)
            BoxShadow(
              blurRadius: 15,
              spreadRadius: -3,
              color: Theme.of(context).colorScheme.tertiary,
              blurStyle: BlurStyle.outer,
            ),
        ],
      ),
      child: Tooltip(
        message: description ?? "",
        waitDuration: const Duration(
          seconds: 1,
        ),
        child: InkWell(
          onTap: () => onPlayToggle?.call(
            !selectedAndPlaying,
          ),
          borderRadius: BorderRadius.circular(
            globalBorderRadius,
          ),
          child: Container(
            width: 200,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                globalBorderRadius,
              ),
            ),
            child: Stack(
              children: [
                // Фоновое изображение.
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    globalBorderRadius,
                  ),
                  child: backgroundUrl != null
                      ? CachedNetworkImage(
                          imageUrl: backgroundUrl!,
                          cacheKey: cacheKey,
                          fit: BoxFit.fill,
                          width: 200,
                          height: 50,
                          memCacheWidth:
                              (200 * MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                          memCacheHeight:
                              (50 * MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                        )
                      : const SizedBox(
                          width: 200,
                          height: 50,
                        ),
                ),

                // Затемняющий эффект (градиент) поверх изображения.
                if (backgroundUrl != null)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        globalBorderRadius,
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                // Название, а так же кнопка запуска.
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 6,
                    ),
                    child: Theme(
                      data: ThemeData(
                        brightness: Brightness.dark,
                      ),
                      child: Row(
                        children: [
                          // Название плейлиста.
                          Expanded(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          // Кнопка для запуска.
                          IconButton(
                            onPressed: () => onPlayToggle?.call(
                              !selectedAndPlaying,
                            ),
                            icon: Icon(
                              selectedAndPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Виджет, показывающий раздел "В реальном времени".
class RealtimePlaylistsBlock extends HookConsumerWidget {
  static final AppLogger logger = getLogger("RealtimePlaylistsBlock");

  const RealtimePlaylistsBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixPlaylists = ref.watch(mixPlaylistsProvider);
    final moodPlaylists = ref.watch(moodPlaylistsProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerStateProvider);
    ref.watch(playerLoadedStateProvider);

    final bool isMobile = isMobileLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "В реальном времени".
        Text(
          l18n.music_realtimePlaylistsChip,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(14),

        // Проходимся по доступным аудио миксам.
        // Skeleton loader.
        if (mixPlaylists == null)
          Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
            ),
            child: LivePlaylistWidget(
              title: fakePlaylistNames.first,
              bigLayout: !isMobile,
            ),
          ),

        // Настоящие данные.
        if (mixPlaylists != null)
          for (ExtendedPlaylist playlist in mixPlaylists)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
              ),
              child: LivePlaylistWidget(
                // TODO: Сделать, что бы Lottie-анимация не играла, если этот плейлист не воспроизводится.
                title: playlist.title!,
                description: playlist.description,
                lottieUrl: playlist.backgroundAnimationUrl!,
                bigLayout: !isMobile,
                selected: player.currentPlaylist == playlist,
                currentlyPlaying: player.playing,
                onPlayToggle: (bool playing) => onMixPlayToggle(
                  context,
                  playlist,
                  playing,
                ),
              ),
            ),

        // Содержимое плейлистов из раздела "Какой сейчас вайб?".
        ScrollConfiguration(
          behavior: AlwaysScrollableScrollBehavior(),
          child: SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: moodPlaylists == null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: moodPlaylists?.length,
              itemBuilder: (BuildContext context, int index) {
                // Skeleton loader.
                if (moodPlaylists == null) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: Skeletonizer(
                      child: MoodPlaylistWidget(
                        title:
                            fakePlaylistNames[index % fakePlaylistNames.length],
                      ),
                    ),
                  );
                }

                // Настоящие данные.
                final ExtendedPlaylist playlist = moodPlaylists[index];

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: MoodPlaylistWidget(
                    title: playlist.title!,
                    description: playlist.description ?? playlist.subtitle,
                    backgroundUrl: playlist.photo!.photo270!,
                    cacheKey: "${playlist.mediaKey}270",
                    selected: player.currentPlaylist == playlist,
                    currentlyPlaying: player.playing,
                    onPlayToggle: (bool playing) => onPlaylistPlayToggle(
                      ref,
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
