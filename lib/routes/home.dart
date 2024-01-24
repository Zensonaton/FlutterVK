import "dart:async";

import "package:animations/animations.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";

import "../api/audio/add.dart";
import "../api/audio/delete.dart";
import "../main.dart";
import "../provider/color.dart";
import "../provider/user.dart";
import "../services/cache_manager.dart";
import "../services/logger.dart";
import "../utils.dart";
import "../widgets/audio_player.dart";
import "../widgets/dialogs.dart";
import "../widgets/loading_overlay.dart";
import "home/messages.dart";
import "home/music.dart";
import "home/profile.dart";

/// Меняет состояние "лайка" у передаваемого трека.
///
/// Учтите, что данный метод делает изменения в интерфейсе.
Future<void> toggleTrackLikeState(
  BuildContext context,
  ExtendedVKAudio audio,
  bool isFavorite,
) async {
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("toggleTrackLikeState");

  LoadingOverlay.of(context).show();

  // Делаем API запрос, что бы либо удалить трек, либо добавить в лайкнутые.
  try {
    if (isFavorite) {
      // Сохраняем трек как лайкнутый.
      final APIAudioAddResponse response = await user.audioAdd(
        audio.id,
        audio.ownerID,
      );

      // Проверяем, что в ответе нет ошибок.
      if (response.error != null) {
        throw Exception(
          "API error ${response.error!.errorCode}: ${response.error!.errorMessage}",
        );
      }

      // Всё ок. Обновляем ID трека в текущем плейлисте, что бы он отображался как лайкнутый.
      // Так же, запоминаем его старый ID и ownerID, в случае, если пользователь захочет его удалить.
      audio.oldID = audio.id;
      audio.oldOwnerID = audio.ownerID;
      audio.id = response.response!;
      audio.ownerID = user.id!;

      // Добавляем трек в список фаворитов.
      user.favoritesPlaylist!.count += 1;
      user.favoritesPlaylist!.audios!.insert(0, audio);
    } else {
      // Удаляем трек из лайкнутых.
      final APIAudioDeleteResponse response = await user.audioDelete(
        audio.id,
        audio.ownerID,
      );

      // Проверяем, что в ответе нет ошибок.
      if (response.error != null) {
        throw Exception(
          "API error ${response.error!.errorCode}: ${response.error!.errorMessage}",
        );
      }

      // Всё ок. Удаляем трек из списка фаворитов.
      user.favoritesPlaylist!.count -= 1;
      user.favoritesPlaylist!.audios!.remove(audio);

      // Если это возможно, то удаляем трек из кэша.
      try {
        VKMusicCacheManager.instance.removeFile(audio.mediaKey);
      } catch (e) {
        logger.w(
          "Не удалось удалить трек из кэша после удаления трека из лайкнутых: ",
          error: e,
        );
      }

      // Если такая информация присутствует, то восстанавливаем старый ID и ownerID трека.
      if (audio.oldID != null && audio.oldOwnerID != null) {
        audio.id = audio.oldID!;
        audio.ownerID = audio.oldOwnerID!;

        audio.oldID = null;
        audio.oldOwnerID = null;
      }
    }

    // Посылаем обновления объекта пользователя.
    user.markUpdated(false);
  } catch (e, stackTrace) {
    // ignore: use_build_context_synchronously
    showLogErrorDialog(
      "Ошибка при попытке сделать трек лайкнутым/дизлайкнутым (новое состояние: $isFavorite): ",
      e,
      stackTrace,
      logger,
      context,
    );
  } finally {
    if (context.mounted) LoadingOverlay.of(context).hide();
  }
}

/// Route, показываемый как "домашняя страница", где расположена навигация между разными частями приложения.
class HomeRoute extends StatefulWidget {
  const HomeRoute({
    super.key,
  });

  @override
  State<HomeRoute> createState() => _HomeRouteState();
}

class _HomeRouteState extends State<HomeRoute> {
  final AppLogger logger = getLogger("HomeRoute");

  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  /// Текущий индекс страницы для [BottomNavigationBar].
  int navigationScreenIndex = 0;

  /// Страницы навигации для [BottomNavigationBar].
  late List<NavigationPage> navigationPages;

  @override
  void initState() {
    super.initState();

    navigationPages = [
      NavigationPage(
        label: AppLocalizations.of(buildContext!)!.home_messagesPageLabel,
        icon: Icons.message_outlined,
        selectedIcon: Icons.message,
        route: const HomeMessagesPage(),
        audioPlayerAlign: Alignment.bottomLeft,
        allowBigAudioPlayer: false,
      ),
      NavigationPage(
        label: AppLocalizations.of(buildContext!)!.music_label,
        icon: Icons.my_library_music_outlined,
        selectedIcon: Icons.my_library_music,
        route: const HomeMusicPage(),
      ),
      NavigationPage(
        label: AppLocalizations.of(buildContext!)!.home_profilePageLabel,
        icon: Icons.person_outlined,
        selectedIcon: Icons.person,
        route: const HomeProfilePage(),
      ),
    ];

    subscriptions = [
      // Событие запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
      ),

      // Событие изменения громкости плеера.
      player.volumeStream.listen(
        (double volume) => setState(() {}),
      ),

      // Изменения состояния работы shuffle.
      player.shuffleModeEnabledStream.listen(
        (bool shuffleEnabled) => setState(() {}),
      ),

      // Изменения состояния работы повтора плейлиста.
      player.loopModeStream.listen(
        (LoopMode loopMode) => setState(() {}),
      ),

      // Событие изменение прогресса "прослушанности" трека.
      player.positionStream.listen(
        (Duration position) => setState(() {}),
      ),

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),

      // Другие события состояния плеера, а так же обработчик ошибок.
      player.playerStateStream.listen(
        (PlayerState? state) => setState(() {}),
        onError: (Object error, StackTrace st) {
          player.stop();

          logger.e(
            "Ошибка воспроизведения плеера: ",
            error: error,
          );

          showErrorDialog(
            context,
            title: "Ошибка воспроизведения",
            description: error.toString(),
          );
        },
      ),
    ];
  }

  /// Изменяет выбранную страницу для [BottomNavigationBar] по передаваемому индексу страницы.
  void setNavigationPage(int pageIndex) {
    assert(pageIndex >= 0 && pageIndex < navigationPages.length);

    setState(() => navigationScreenIndex = pageIndex);
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
    final PlayerSchemeProvider colorScheme =
        Provider.of<PlayerSchemeProvider>(context, listen: false);

    if (!user.isAuthorized) {
      return const Center(
        child: Text(
          "Вы не авторизованы.",
        ),
      );
    }

    final NavigationPage navigationPage =
        navigationPages.elementAt(navigationScreenIndex);

    final bool isMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

    /// Указывает, должен ли быть показан плеер снизу.
    final bool showMusicPlayer = player.loaded;

    /// Запускаем задачу по получению цветовой схемы.
    player
        .getColorSchemeAsync(
      MediaQuery.of(context).platformBrightness,
    )
        .then(
      (ColorScheme? scheme) {
        if (scheme == null) return;

        colorScheme.setScheme(
          scheme,
          mediaKey: player.currentAudio!.mediaKey,
        );
      },
    );

    return Scaffold(
      appBar: isMobileLayout
          ? AppBar(
              title: Text(
                navigationPage.label,
              ),
              centerTitle: true,
            )
          : null,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobileLayout)
                NavigationRail(
                  selectedIndex: navigationScreenIndex,
                  onDestinationSelected: setNavigationPage,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (NavigationPage page in navigationPages)
                      NavigationRailDestination(
                        icon: Icon(
                          page.icon,
                        ),
                        label: Text(page.label),
                        selectedIcon: Icon(
                          page.selectedIcon ?? page.icon,
                        ),
                      )
                  ],
                ),
              if (!isMobileLayout) const VerticalDivider(),
              Expanded(
                child: PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation,
                      Animation<double> secondaryAnimation) {
                    return SharedAxisTransition(
                      transitionType: SharedAxisTransitionType.vertical,
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      child: child,
                    );
                  },
                  child: navigationPage.route,
                ),
              ),
            ],
          ),
          AnimatedAlign(
            duration: const Duration(
              milliseconds: 500,
            ),
            curve: Curves.ease,
            alignment: navigationPage.audioPlayerAlign,
            child: AnimatedOpacity(
              opacity: showMusicPlayer ? 1 : 0,
              curve: Curves.ease,
              duration: const Duration(
                milliseconds: 500,
              ),
              child: AnimatedSlide(
                offset: Offset(
                  0,
                  showMusicPlayer ? 0 : 1,
                ),
                duration: const Duration(
                  milliseconds: 500,
                ),
                curve: Curves.ease,
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 500,
                  ),
                  padding: !isMobileLayout && navigationPage.allowBigAudioPlayer
                      ? null
                      : const EdgeInsets.all(8),
                  curve: Curves.ease,
                  width: isMobileLayout
                      ? null
                      : (navigationPage.allowBigAudioPlayer
                          ? clampDouble(
                              MediaQuery.of(context).size.width,
                              500,
                              double.infinity,
                            )
                          : 360),
                  child: BottomMusicPlayer(
                    audio: player.currentAudio,
                    previousAudio: player.previousAudio,
                    nextAudio: player.nextAudio,
                    scheme: colorScheme.colorScheme ??
                        Theme.of(context).colorScheme,
                    favoriteState: player.currentAudio != null
                        ? user.favoriteMediaKeys
                            .contains(player.currentAudio!.mediaKey)
                        : false,
                    playbackState: player.playing,
                    progress: player.progress,
                    volume: player.volume,
                    isBuffering: const [
                      ProcessingState.buffering,
                      ProcessingState.loading
                    ].contains(
                      player.playerState.processingState,
                    ),
                    isShuffleEnabled: player.shuffleModeEnabled,
                    isRepeatEnabled: player.loopMode == LoopMode.one,
                    pauseOnMuteEnabled: user.settings.pauseOnMuteEnabled,
                    useBigLayout:
                        !isMobileLayout && navigationPage.allowBigAudioPlayer,
                    onFavoriteStateToggle: (bool liked) => toggleTrackLikeState(
                      context,
                      player.currentAudio!,
                      !user.favoriteMediaKeys.contains(
                        player.currentAudio!.mediaKey,
                      ),
                    ),
                    onPlayStateToggle: (bool enabled) =>
                        player.playOrPause(enabled),
                    onVolumeChange: (double volume) => player.setVolume(volume),
                    onDismiss: () => player.stop(),
                    onFullscreen: () => showWipDialog(
                      context,
                      title: "Полноэкранный плеер",
                    ),
                    onShuffleToggle: (bool enabled) async {
                      await player.setShuffle(enabled);
                      user.settings.shuffleEnabled = enabled;

                      user.markUpdated();
                    },
                    onRepeatToggle: (bool enabled) =>
                        player.setLoop(enabled ? LoopMode.one : LoopMode.off),
                    onNextTrack: () => player.next(),
                    onPreviousTrack: () =>
                        player.previous(allowSeekToBeginning: true),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobileLayout
          ? NavigationBar(
              onDestinationSelected: setNavigationPage,
              selectedIndex: navigationScreenIndex,
              destinations: [
                for (NavigationPage page in navigationPages)
                  NavigationDestination(
                    icon: Icon(
                      page.icon,
                    ),
                    label: page.label,
                    selectedIcon: Icon(
                      page.selectedIcon ?? page.icon,
                    ),
                  )
              ],
            )
          : null,
    );
  }
}
