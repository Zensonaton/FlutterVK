import "package:animations/animations.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:media_kit/media_kit.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";

import "../main.dart";
import "../provider/user.dart";
import "../services/audio_player.dart";
import "../services/logger.dart";
import "../utils.dart";
import "../widgets/audio_player.dart";
import "../widgets/error_dialog.dart";
import "../widgets/wip_dialog.dart";
import "home/messages.dart";
import "home/music.dart";
import "home/profile.dart";

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
        label: AppLocalizations.of(buildContext!)!.music_Label,
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

    // Если поменялось время того, сколько было прослушано у трека.
    player.stream.position.listen((Duration? position) => setState(() {}));

    // Если поменялась громкость плеера.
    player.stream.volume.listen((double volume) => setState(() {}));

    // Если поменялся текущий трек.
    player.indexChangeStream.listen((int index) => setState(() {}));

    // Если произошло какое-то иное событие.
    player.playerStateStream.listen(
      (AudioPlaybackState state) => setState(() {}),
    );

    // Логи плеера.
    if (kDebugMode) {
      player.stream.log.listen((event) {
        logger.d(event.text);
      });
    }

    // TODO: Нормальный обработчик ошибок.
    player.stream.error.listen((event) {
      player.stop();

      showErrorDialog(
        context,
        title: "Ошибка воспроизведения",
        description: event.toString(),
      );
    });
  }

  /// Изменяет выбранную страницу для [BottomNavigationBar] по передаваемому индексу страницы.
  void setNavigationPage(int pageIndex) {
    assert(pageIndex >= 0 && pageIndex < navigationPages.length);

    setState(() => navigationScreenIndex = pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

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

    final bool showMiniPlayer = player.isLoaded;

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
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
            alignment: navigationPage.audioPlayerAlign,
            child: AnimatedOpacity(
              opacity: showMiniPlayer ? 1 : 0,
              curve: Curves.ease,
              duration: const Duration(
                milliseconds: 500,
              ),
              child: AnimatedSlide(
                offset: Offset(
                  0,
                  showMiniPlayer ? 0 : 1,
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
                    favoriteState: true,
                    playbackState: player.state.playing,
                    progress: player.progress,
                    volume: player.state.volume / 100,
                    isBuffering: player.state.buffering,
                    isShuffleEnabled: player.shuffleEnabled,
                    isRepeatEnabled:
                        player.state.playlistMode == PlaylistMode.single,
                    pauseOnMuteEnabled: user.settings.pauseOnMuteEnabled,
                    useBigLayout:
                        !isMobileLayout && navigationPage.allowBigAudioPlayer,
                    onFavoriteStateToggle: (_) => showWipDialog(context),
                    onPlayStateToggle: (bool enabled) async {
                      await player.setPlaying(enabled);

                      setState(() {});
                    },
                    onVolumeChange: (double volume) async {
                      await player.setVolume(volume);

                      setState(() {});
                    },
                    onDismiss: () async {
                      await player.stop();

                      setState(() {});
                    },
                    onFullscreen: () => showWipDialog(
                      context,
                      title: "Полноэкранный плеер",
                    ),
                    onShuffleToggle: (bool enabled) async {
                      await player.setShuffle(enabled);
                      user.settings.shuffleEnabled = enabled;

                      user.markUpdated();
                      setState(() {});
                    },
                    onRepeatToggle: (bool enabled) async {
                      await player.setPlaylistMode(
                        enabled ? PlaylistMode.single : PlaylistMode.none,
                      );

                      setState(() {});
                    },
                    onNextTrack: () => player.next(),
                    onPreviousTrack: () => player.previous(),
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
