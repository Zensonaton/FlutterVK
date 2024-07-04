import "dart:async";

import "package:audio_service/audio_service.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:just_audio/just_audio.dart";

import "../main.dart";
import "../provider/color.dart";
import "../provider/player_events.dart";
import "../provider/preferences.dart";
import "../provider/user.dart";
import "../routes/fullscreen_player.dart";
import "../routes/home.dart";
import "../services/cache_manager.dart";
import "../services/logger.dart";
import "../utils.dart";
import "audio_player.dart";
import "dialogs.dart";

/// Класс для отображения Route'ов в [BottomNavigationBar], вместе с их названиями, а так же иконками.
class NavigationItem {
  /// Путь к данному элементу.
  final String path;

  /// Страница, которая будет отображена при выборе данного элемента. Если не будет указано, то Route будет отключён.
  final WidgetBuilder? body;

  /// Иконка, которая используется на [BottomNavigationBar].
  final IconData icon;

  /// Иконка, которая используется при выборе элемента в [BottomNavigationBar]. Если не указано, то будет использоваться [icon].
  final IconData? selectedIcon;

  /// Текст, используемый в [BottomNavigationBar].
  final String label;

  /// Указывает, что данная запись будет показана и в [BottomNavigationBar] при Mobile Layout'е.
  final bool showOnMobileLayout;

  /// Опциональный список из путей, которые могут быть использованы в [GoRouter].
  final List<RouteBase> routes;

  NavigationItem({
    required this.path,
    this.body,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.showOnMobileLayout = true,
    this.routes = const [],
  });
}

/// Виджет, который содержит в себе [Scaffold] с [NavigationRail] или [BottomNavigationBar] в зависимости от того, какой используется Layout: Desktop ([isDesktopLayout]) или Mobile ([isMobileLayout]), а так же мини-плеер снизу ([BottomMusicPlayerWrapper]).
class ShellRouteWrapper extends HookConsumerWidget {
  final Widget child;
  final String currentPath;
  final List<NavigationItem> navigationItems;

  const ShellRouteWrapper({
    super.key,
    required this.child,
    required this.currentPath,
    required this.navigationItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<NavigationItem> mobileNavigationItems = useMemoized(
      () => navigationItems.where((item) => item.showOnMobileLayout).toList(),
    );

    final bool isMobile = isMobileLayout(context);
    final int currentIndex =
        navigationItems.indexWhere((item) => item.path == currentPath);
    final int mobileCurrentIndex =
        mobileNavigationItems.indexWhere((item) => item.path == currentPath);

    /// TODO: Проверка на то, что мы попали на недопустимую страницу.

    /// Обработчик выбора элемента в [NavigationRail].
    void onDestinationSelected(int index) {
      if (index == currentIndex) return;

      context.go(navigationItems[index].path);
    }

    return Scaffold(
      body: Stack(
        children: [
          // Содержимое.
          Row(
            children: [
              // NavigationRail слева.
              if (!isMobile)
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final item in navigationItems)
                      NavigationRailDestination(
                        icon: Icon(
                          item.icon,
                        ),
                        selectedIcon: Icon(
                          item.selectedIcon ?? item.icon,
                        ),
                        label: Text(
                          item.label,
                        ),
                        disabled: item.body == null,
                      ),
                  ],
                  // TODO: Настройка, что бы дать юзеру возможность расширить NavigatorRail. (extended)
                ),

              // Само содержимое страницы.
              Expanded(
                child: child,
              ),
            ],
          ),

          // Мини-плеер снизу.
          const RepaintBoundary(
            child: BottomMusicPlayerWrapper(),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: mobileCurrentIndex >= 0 ? mobileCurrentIndex : 2,
              onDestinationSelected: (int index) {
                final List<NavigationItem> realNavigationItems = [
                  ...mobileNavigationItems,
                ];

                // Учитываем, что у нас появляется элемент в [NavigationBar] на 2 индексе,
                // если мы находимся на странице, которая не показывается в [NavigationBar].
                if (navigationItems.any(
                  (item) =>
                      item.path == currentPath && !item.showOnMobileLayout,
                )) {
                  realNavigationItems.insert(
                    2,
                    navigationItems.firstWhere(
                      (item) => item.path == currentPath,
                    ),
                  );
                }

                // Поскольку мы используем [mobileNavigationItems] вместо [navigationItems],
                // мы должны найти реальный индекс относительно [navigationItems].
                final NavigationItem mobilePage = realNavigationItems[index];

                onDestinationSelected(
                  navigationItems.indexWhere(
                    (page) => page == mobilePage,
                  ),
                );
              },
              destinations: [
                for (final item in navigationItems)
                  if (item.showOnMobileLayout || item.path == currentPath)
                    NavigationDestination(
                      icon: Icon(
                        item.icon,
                      ),
                      selectedIcon: Icon(
                        item.selectedIcon ?? item.icon,
                      ),
                      label: item.label,
                      enabled: item.body != null,
                    ),
              ],
            )
          : null,
    );
  }
}

/// Виджет, являющийся wrapper'ом для [BottomMusicPlayer], который добавляет обработку для различных событий.
///
/// Данный виджет так же регистрирует listener'ы для некоторых событий плеера, благодаря чему появляется поддержка кэширования, получения цветов обложек и прочего.
class BottomMusicPlayerWrapper extends StatefulHookConsumerWidget {
  const BottomMusicPlayerWrapper({
    super.key,
  });

  @override
  ConsumerState<BottomMusicPlayerWrapper> createState() =>
      _BottomMusicPlayerWrapperState();
}

class _BottomMusicPlayerWrapperState
    extends ConsumerState<BottomMusicPlayerWrapper> {
  static final AppLogger logger = getLogger("BottomMusicPlayerWrapper");

  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Слушаем события нажатия на медиа-уведомление.
      AudioService.notificationClicked.listen((tapped) {
        logger.d("Handling player notification clicked event");

        // AudioService иногда создаёт это событие при запуске плеера. Такой случай мы игнорируем.
        if (!tapped) return;

        // Если плеер не загружен, то ничего не делаем.
        if (!player.loaded) return;

        openFullscreenPlayer(context);
      }),

      // Слушаем события изменения текущего трека в плеере, что бы загружать обложку, текст песни, а так же создание цветовой схемы.
      player.currentIndexStream.listen((int? index) async {
        if (index == null || !player.loaded) return;

        final ExtendedAudio audio = player.currentAudio!;

        /// Внутренний метод, который создаёт [ColorScheme], после чего сохраняет его внутрь [PlayerSchemeProvider].
        void getColorScheme() async {
          // Если обложек у трека нету, то ничего не делаем.
          if (audio.thumbnail == null) return;

          // Загружаем изображение трека.
          final CachedNetworkImageProvider imageProvider =
              CachedNetworkImageProvider(
            player.currentAudio!.smallestThumbnail!,
            cacheKey: audio.mediaKey,
            cacheManager: CachedAlbumImagesManager.instance,
          );

          // Заставляем плеер извлекать цветовую схему из обложки трека.
          ref
              .read(trackSchemeInfoProvider.notifier)
              .fromImageProvider(imageProvider);
        }

        // Загружаем информацию по треку, если есть соединение с интернетом.
        if (connectivityManager.hasConnection) {
          // TODO

          // CachedStreamedAudio.downloadTrackData(
          //   audio,
          //   player.currentPlaylist!,
          //   allowDeezer: preferences.deezerThumbnails,
          //   allowSpotifyLyrics: preferences.spotifyLyrics &&
          //       ref.read(spotifySPDCCookieProvider) != null,
          //   saveInDB: true,
          // ).then((updatedDB) async {
          //   // Делаем так, что бы плеер обновил обложку трека.
          //   await player.updateMusicSessionTrack();

          //   getColorScheme();
          // });
        }

        // Запускаем задачу по получению цветовой схемы.
        getColorScheme();
      }),
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
    final preferences = ref.watch(preferencesProvider);
    final trackImageInfo = ref.watch(trackSchemeInfoProvider);
    ref.watch(playerCurrentIndexProvider);
    ref.watch(playerStateProvider);
    ref.watch(playerVolumeProvider);
    ref.watch(playerLoopModeProvider);
    ref.watch(playerLoadedStateProvider);

    final bool isMobile = isMobileLayout(context);

    const Alignment alignment =
        Alignment.bottomLeft; // TODO: navigationPage.audioPlayerAlign,
    const bool allowBigPlayer =
        true; // TODO: navigationPage.allowBigAudioPlayer

    final bool isMixPlaylistPlaying =
        player.currentPlaylist?.isAudioMixPlaylist ?? false;

    return AnimatedAlign(
      duration: const Duration(
        milliseconds: 500,
      ),
      alignment: alignment,
      child: StreamBuilder<Duration>(
        stream: player.positionStream,
        builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
          return AnimatedOpacity(
            opacity: player.loaded ? 1.0 : 0.0,
            curve: Curves.ease,
            duration: const Duration(
              milliseconds: 500,
            ),
            child: AnimatedSlide(
              offset: Offset(
                0,
                player.loaded ? 0.0 : 1.0,
              ),
              duration: const Duration(
                milliseconds: 500,
              ),
              curve: Curves.ease,
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 500,
                ),
                padding: !isMobile && allowBigPlayer
                    ? null
                    : const EdgeInsets.all(
                        8,
                      ),
                curve: Curves.ease,
                width: isMobile
                    ? null
                    : (allowBigPlayer
                        ? MediaQuery.sizeOf(context)
                            .width
                            .clamp(500, double.infinity)
                        // ignore: dead_code
                        : 360),
                child: BottomMusicPlayer(
                  audio: player.smartCurrentAudio,
                  nextAudio: player.smartNextAudio,
                  previousAudio: player.smartPreviousAudio,
                  scheme: trackImageInfo
                          ?.colorScheme(Theme.of(context).brightness) ??
                      Theme.of(context).colorScheme,
                  favoriteState: player.currentAudio != null
                      ? player.currentAudio!.isLiked
                      : false,
                  playbackState: player.playing,
                  progress: player.progress,
                  volume: player.volume,
                  position: player.position,
                  duration: player.duration ?? Duration.zero,
                  isBuffering: player.buffering,
                  isShuffleEnabled: player.shuffleModeEnabled,
                  isRepeatEnabled: player.loopMode == LoopMode.one,
                  pauseOnMuteEnabled: preferences.pauseOnMuteEnabled,
                  useBigLayout: !isMobile,
                  onFavoriteStateToggle: (bool liked) {
                    if (!networkRequiredDialog(ref, context)) return;

                    toggleTrackLikeState(
                      context,
                      player.currentAudio!,
                      !player.currentAudio!.isLiked,
                    );
                  },
                  onDislike:
                      (player.currentPlaylist?.isRecommendationTypePlaylist ??
                              false)
                          ? () async {
                              if (!networkRequiredDialog(ref, context)) return;

                              // Делаем трек дизлайкнутым.
                              final bool result = await dislikeTrackState(
                                context,
                                player.currentAudio!,
                              );
                              if (!result) return;

                              // Запускаем следующий трек в плейлисте.
                              await player.next();
                            }
                          : null,
                  onPlayStateToggle: (_) => player.togglePlay(),
                  onProgressChange: (double progress) =>
                      player.seekNormalized(progress),
                  onVolumeChange: (double volume) => player.setVolume(volume),
                  onDismiss: () => player.stop(),
                  onFullscreen: (bool viaSwipeUp) => openFullscreenPlayer(
                    context,
                    fullscreenOnDesktop:
                        !isMobile && !HardwareKeyboard.instance.isShiftPressed,
                  ),
                  onMiniplayer: () => openMiniPlayer(context),
                  onShuffleToggle: !isMixPlaylistPlaying
                      ? (bool enabled) async {
                          await player.setShuffle(enabled);

                          ref
                              .read(preferencesProvider.notifier)
                              .setShuffleEnabled(enabled);
                        }
                      : null,
                  onRepeatToggle: (_) => player.setLoop(
                    player.loopMode == LoopMode.all
                        ? LoopMode.one
                        : LoopMode.all,
                  ),
                  onNextTrack: () => player.next(),
                  onPreviousTrack: () => player.previous(
                    allowSeekToBeginning: true,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
