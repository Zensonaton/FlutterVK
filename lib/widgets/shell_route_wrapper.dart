import "dart:async";

import "package:audio_service/audio_service.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:just_audio/just_audio.dart";

import "../api/vk/api.dart";
import "../api/vk/audio/get_lyrics.dart";
import "../api/vk/audio/get_stream_mix_audios.dart";
import "../api/vk/audio/send_start_event.dart";
import "../enums.dart";
import "../main.dart";
import "../provider/color.dart";
import "../provider/l18n.dart";
import "../provider/player_events.dart";
import "../provider/playlists.dart";
import "../provider/preferences.dart";
import "../provider/user.dart";
import "../routes/fullscreen_player.dart";
import "../routes/home/music.dart";
import "../routes/home/music/categories/realtime_playlists.dart";
import "../services/cache_manager.dart";
import "../services/logger.dart";
import "../services/updater.dart";
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
///
/// Данный виджет так же подписывается на некоторые события, по типу проверки на наличия новых обновлений.
class ShellRouteWrapper extends HookConsumerWidget {
  static final AppLogger logger = getLogger("ShellRouteWrapper");

  final Widget child;
  final String currentPath;
  final List<NavigationItem> navigationItems;

  const ShellRouteWrapper({
    super.key,
    required this.child,
    required this.currentPath,
    required this.navigationItems,
  });

  /// Проверяет на наличие обновлений, и дальше предлагает пользователю обновиться, если есть новое обновление.
  void checkForUpdates(WidgetRef ref, BuildContext context) {
    final preferences = ref.read(preferencesProvider);

    // Проверяем, есть ли разрешение на обновления, а так же работу интернета.
    if (preferences.updatePolicy == UpdatePolicy.disabled ||
        !connectivityManager.hasConnection) return;

    // Проверяем на наличие обновлений.
    Updater.checkForUpdates(
      context,
      allowPre: preferences.updateBranch == UpdateBranch.prereleases,
      useSnackbarOnUpdate: preferences.updatePolicy == UpdatePolicy.popup,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    useEffect(
      () {
        // Проверяем на наличие обновлений, если мы не в debug-режиме.
        if (!kDebugMode) checkForUpdates(ref, context);

        // Слушаем события подключения к интернету.
        final subscription =
            connectivityManager.connectionChange.listen((bool isConnected) {
          logger.d("Network connectivity state: $isConnected");

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(
                seconds: isConnected ? 2 : 6,
              ),
              content: Text(
                isConnected
                    ? l18n.internetConnectionRestoredDescription
                    : l18n.noInternetConnectionDescription,
              ),
            ),
          );
        });

        return subscription.cancel;
      },
      [],
    );

    final List<NavigationItem> mobileNavigationItems = useMemoized(
      () => navigationItems.where((item) => item.showOnMobileLayout).toList(),
    );

    final bool mobileLayout = isMobileLayout(context);
    final int currentIndex =
        navigationItems.indexWhere((item) => currentPath.startsWith(item.path));
    final int mobileCurrentIndex = mobileNavigationItems
        .indexWhere((item) => currentPath.startsWith(item.path));

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
              if (!mobileLayout)
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
      bottomNavigationBar: mobileLayout
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
class BottomMusicPlayerWrapper extends HookConsumerWidget {
  static final AppLogger logger = getLogger("BottomMusicPlayerWrapper");

  const BottomMusicPlayerWrapper({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackImageInfo = ref.watch(trackSchemeInfoProvider);
    final l18n = ref.watch(l18nProvider);
    final user = ref.read(userProvider.notifier);
    ref.watch(playerCurrentIndexProvider);
    ref.watch(playerStateProvider);
    ref.watch(playerVolumeProvider);
    ref.watch(playerShuffleModeEnabledProvider);
    ref.watch(playerLoopModeProvider);
    ref.watch(playerLoadedStateProvider);
    ref.watch(playerPlaylistModificationsProvider);

    useEffect(
      () {
        final List<StreamSubscription> subscriptions = [
          // Слушаем события нажатия на медиа-уведомление.
          AudioService.notificationClicked.listen((tapped) {
            logger.d("Handling player notification clicked event");

            // AudioService иногда создаёт это событие при запуске плеера. Такой случай мы игнорируем.
            // Если плеер не загружен, то ничего не делаем.
            if (!tapped || !player.loaded) return;

            openFullscreenPlayer(context);
          }),

          // Слушаем события изменения текущего трека в плеере, что бы загружать обложку, текст песни, а так же создание цветовой схемы.
          player.currentIndexStream.listen((int? index) async {
            if (index == null || !player.loaded) return;

            final ExtendedPlaylist playlist =
                player.currentPlaylist!.copyWith();
            final ExtendedAudio audio = player.currentAudio!.copyWith();
            final schemeInfoNotifier =
                ref.read(trackSchemeInfoProvider.notifier);
            final userNotifier = ref.read(userProvider.notifier);
            final playlistsNotifier = ref.read(playlistsProvider.notifier);

            /// Метод, создающий цветовую схему из обложки трека, если таковая имеется.
            void getColorScheme() async {
              if (audio.thumbnail == null) return;

              // Заставляем плеер извлекать цветовую схему из обложки трека.
              schemeInfoNotifier.fromImageProvider(
                CachedNetworkImageProvider(
                  audio.smallestThumbnail!,
                  cacheKey: "${audio.mediaKey}small",
                  cacheManager: CachedAlbumImagesManager.instance,
                ),
              );

              // TODO: Сохранить цвета в БД.
            }

            /// Метод, загружающий текст трека.
            void getLyrics() async {
              if (!(audio.hasLyrics ?? false) || audio.lyrics != null) return;

              // Загружаем текст песни.
              final APIAudioGetLyricsResponse response =
                  await userNotifier.audioGetLyrics(audio.mediaKey);
              raiseOnAPIError(response);

              // Сохраняем в БД.
              playlistsNotifier.updatePlaylist(
                playlist.copyWithNewAudio(
                  audio.copyWith(lyrics: response.response?.lyrics),
                ),
                saveInDB: true,
              );
            }

            // Запускаем задачу по получению цветовой схемы.
            getColorScheme();

            // Загружаем текст песни.
            getLyrics();
          }),

          // Слушаем события изменения текущего трека, что бы в случае, если запущен рекомендательный плейлист, мы передавали информацию об этом ВКонтакте.
          player.currentIndexStream.listen((int? index) async {
            if (index == null) return;

            // Если нет доступа к интернету, то ничего не делаем.
            if (!connectivityManager.hasConnection) return;

            // Если это не рекомендуемый плейлист, то ничего не делаем.
            if (!(player.currentPlaylist?.isRecommendationTypePlaylist ??
                false)) {
              return;
            }

            // Делаем API-запрос, передавая информацию серверам ВКонтакте.
            try {
              final APIAudioSendStartEventResponse response =
                  await user.audioSendStartEvent(player.currentAudio!.mediaKey);
              raiseOnAPIError(response);
            } catch (e, stackTrace) {
              logger.w(
                "Couldn't notify VK about track listening state: ",
                error: e,
                stackTrace: stackTrace,
              );
            }
          }),

          // Отдельно слушаем события изменения индекса текущего трека, что бы добавлять треки в реальном времени, если это аудио микс.
          player.currentIndexStream.listen((int? index) async {
            if (index == null ||
                !player.loaded ||
                !(player.currentPlaylist?.isAudioMixPlaylist ?? false)) return;

            final int count = player.currentPlaylist!.count;
            final int tracksLeft = count - index;
            final int tracksToAdd = tracksLeft <= minMixAudiosCount
                ? (minMixAudiosCount - tracksLeft)
                : 0;

            logger.d(
              "Mix index: $index/$count, should add $tracksToAdd tracks",
            );

            // Если у нас достаточно треков в очереди, то ничего не делаем.
            if (tracksToAdd <= 0) return;

            logger.d("Adding $tracksToAdd tracks to mix queue");
            try {
              final APIAudioGetStreamMixAudiosResponse response = await user
                  .audioGetStreamMixAudiosWithAlbums(count: tracksToAdd);
              raiseOnAPIError(response);

              final List<ExtendedAudio> newAudios = response.response!
                  .map(
                    (audio) => ExtendedAudio.fromAPIAudio(audio),
                  )
                  .toList();

              // Добавляем треки в объект плейлиста.
              player.currentPlaylist!.audios!.addAll(newAudios);
              player.currentPlaylist!.count += response.response!.length;

              // Добавляем треки в очередь воспроизведения плеера.
              for (ExtendedAudio audio in newAudios) {
                await player.addToQueueEnd(audio);
              }
            } catch (e, stackTrace) {
              logger.e(
                "Couldn't load audio mix tracks: ",
                error: e,
                stackTrace: stackTrace,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l18n.musicMixAudiosAddError(e.toString()),
                    ),
                  ),
                );
              }

              return;
            }

            logger.d(
              "Successfully added $tracksToAdd tracks to mix queue (current: ${player.currentPlaylist!.count})",
            );
          }),
        ];

        return () {
          for (StreamSubscription subscription in subscriptions) {
            subscription.cancel();
          }
        };
      },
      [],
    );

    final bool mobileLayout = isMobileLayout(context);

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
                padding: !mobileLayout && allowBigPlayer
                    ? null
                    : const EdgeInsets.all(
                        8,
                      ),
                curve: Curves.ease,
                width: mobileLayout
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
                  progress: player.progress,
                  volume: player.volume,
                  position: player.position,
                  duration: player.duration ?? Duration.zero,
                  isPlaying: player.playing,
                  isBuffering: player.buffering,
                  isShuffleEnabled: player.shuffleModeEnabled,
                  isRepeatEnabled: player.loopMode == LoopMode.one,
                  isLiked: player.currentAudio != null
                      ? player.currentAudio!.isLiked
                      : false,
                  useBigLayout: !mobileLayout,
                  onLikeTap: () async {
                    if (!networkRequiredDialog(ref, context)) return;

                    if (!player.currentAudio!.isLiked &&
                        ref.read(preferencesProvider).checkBeforeFavorite) {
                      if (!await checkForDuplicates(
                        ref,
                        context,
                        player.currentAudio!,
                      )) return;
                    }
                    await toggleTrackLike(
                      ref,
                      player.currentAudio!,
                      !player.currentAudio!.isLiked,
                      sourcePlaylist: player.currentPlaylist,
                    );
                  },
                  onDislike:
                      (player.currentPlaylist?.isRecommendationTypePlaylist ??
                              false)
                          ? () async {
                              if (!networkRequiredDialog(ref, context)) return;

                              await dislikeTrack(
                                ref,
                                player.currentAudio!,
                              );

                              await player.next();
                            }
                          : null,
                  onPlayStateToggle: () => player.togglePlay(),
                  onProgressChange: (double progress) =>
                      player.seekNormalized(progress),
                  onVolumeChange: (double volume) => player.setVolume(volume),
                  onDismiss: () => player.stop(),
                  onFullscreen: (bool viaSwipeUp) => openFullscreenPlayer(
                    context,
                    fullscreenOnDesktop: !mobileLayout &&
                        !HardwareKeyboard.instance.isShiftPressed,
                  ),
                  onMiniplayer: () => openMiniPlayer(context),
                  onShuffleToggle: !isMixPlaylistPlaying
                      ? () async {
                          await player.toggleShuffle();

                          ref
                              .read(preferencesProvider.notifier)
                              .setShuffleEnabled(player.shuffleModeEnabled);
                        }
                      : null,
                  onRepeatToggle: () => player.setLoop(
                    player.loopMode == LoopMode.all
                        ? LoopMode.one
                        : LoopMode.all,
                  ),
                  onNextTrack: () => player.next(),
                  onPreviousTrack: () =>
                      player.previous(allowSeekToBeginning: true),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
