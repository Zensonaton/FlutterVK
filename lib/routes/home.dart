import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";

import "../api/vk/api.dart";
import "../api/vk/audio/add.dart";
import "../api/vk/audio/delete.dart";
import "../api/vk/audio/restore.dart";
import "../enums.dart";
import "../main.dart";
import "../provider/color.dart";
import "../provider/user.dart";
import "../services/audio_player.dart";
import "../services/logger.dart";
import "../services/updater.dart";
import "../utils.dart";
import "../widgets/audio_player.dart";
import "../widgets/dialogs.dart";
import "../widgets/loading_overlay.dart";
import "fullscreen_player.dart";
import "home/messages.dart";
import "home/music.dart";
import "home/profile.dart";

/// Диалог, предупреждающий о том, что трек уже сохранён.
class DuplicateWarningDialog extends StatelessWidget {
  /// Аудио, которое пользователь попытался лайкнуть.
  final ExtendedVKAudio audio;

  /// Плейлист с лайкнутыми треками.
  final ExtendedVKPlaylist playlist;

  const DuplicateWarningDialog({
    super.key,
    required this.audio,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialDialog(
      icon: Icons.copy,
      title: AppLocalizations.of(context)!.checkBeforeFavoriteWarningTitle,
      text: AppLocalizations.of(context)!.checkBeforeFavoriteWarningDescription,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)!.general_no,
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();

            await toggleTrackLikeState(
              context,
              audio,
              true,
              checkBeforeSaving: false,
            );
          },
          child: Text(
            AppLocalizations.of(context)!.general_yes,
          ),
        )
      ],
    );
  }
}

/// Меняет состояние "лайка" у передаваемого трека.
///
/// В отличии от метода [toggleTrackLikeState], данный метод не делает никаких проверок на существование трека, а так же никаких изменений в интерфейсе не происходит.
Future<void> toggleTrackLike(
  UserProvider user,
  ExtendedVKAudio audio,
  bool isFavorite,
) async {
  final AppLogger logger = getLogger("toggleTrackLike");

  if (isFavorite) {
    // Пользователь попытался лайкнуть трек.
    // Здесь мы должны проверить, пытается ли пользователь восстановить ранее удалённый трек или нет.
    final bool shouldRestore = user.favoritesPlaylist!.audios!.contains(audio);

    // Если пользователь пытается восстановить трек, то вызываем audio.restore,
    // в ином случае просто добавляем его методом audio.add.
    if (shouldRestore) {
      // Восстанавливаем трек.
      final APIAudioRestoreResponse response = await user.audioRestore(
        audio.id,
        ownerID: audio.ownerID,
      );
      raiseOnAPIError(response);
    } else {
      // Сохраняем трек как лайкнутый.
      final APIAudioAddResponse response = await user.audioAdd(
        audio.id,
        audio.ownerID,
      );
      raiseOnAPIError(response);

      audio.oldID = audio.id;
      audio.oldOwnerID = audio.ownerID;

      audio.id = response.response!;
      audio.ownerID = user.id!;
    }

    // Прекрасно, трек был добавлен либо восстановлён.
    // Теперь нам нужно запомнить то, что трек лайкнут.
    audio.isLiked = true;

    // Добавляем трек в список фаворитов.
    user.favoritesPlaylist!.count += 1;

    // Убеждаемся, что трек не существует в списке.
    if (!user.favoritesPlaylist!.audios!.contains(audio)) {
      user.favoritesPlaylist!.audios!.insert(0, audio);
    }
  } else {
    // Пользователь пытается удалить трек.

    // Удаляем трек из лайкнутых.
    final APIAudioDeleteResponse response = await user.audioDelete(
      audio.id,
      audio.ownerID,
    );
    raiseOnAPIError(response);

    // Всё ок, помечаем трек как не лайкнутый.
    user.favoritesPlaylist!.count -= 1;
    audio.isLiked = false;

    // Если это возможно, то удаляем трек из кэша.
    try {
      CachedStreamedAudio(
        cacheKey: audio.mediaKey,
      ).delete();
    } catch (e) {
      logger.w(
        "Не удалось удалить трек из кэша после удаления трека из лайкнутых: ",
        error: e,
      );
    }
  }
}

/// Меняет состояние "лайка" у передаваемого трека.
///
/// Учтите, что данный метод делает изменения в интерфейсе.
/// Если [checkBeforeSaving] равен true, то в случае дубликата трека появится диалог, подтверждающий создание дубликата.
Future<void> toggleTrackLikeState(
  BuildContext context,
  ExtendedVKAudio audio,
  bool isFavorite, {
  bool checkBeforeSaving = true,
}) async {
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("toggleTrackLikeState");

  // Если это разрешено, то проверяем, есть ли такой трек в лайкнутых.
  if (isFavorite && checkBeforeSaving) {
    bool isDuplicate = user.favoritesPlaylist!.audios!.any(
      (favAudio) =>
          favAudio.isLiked &&
          favAudio.title == audio.title &&
          favAudio.artist == audio.artist &&
          favAudio.album == audio.album,
    );

    // Если это дубликат, то показываем предупреждение об этом.
    if (isDuplicate) {
      showDialog(
        context: context,
        builder: (BuildContext context) => DuplicateWarningDialog(
          audio: audio,
          playlist: user.favoritesPlaylist!,
        ),
      );

      return;
    }
  }

  LoadingOverlay.of(context).show();

  try {
    // Делаем API запросы для удаления/добавления трека.
    await toggleTrackLike(
      user,
      audio,
      isFavorite,
    );

    // Посылаем обновления объекта пользователя.
    user.resetFavoriteMediaKeys();
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

/// Wrapper для [BottomMusicPlayer], который передаёт все нужные поля для [BottomMusicPlayer].
class BottomMusicPlayerWidget extends StatefulWidget {
  /// Указывает, что используется Mobile Layout плеера.
  final bool isMobileLayout;

  /// Указывает, что этот мини плеер может быть больших размеров.
  final bool allowBigAudioPlayer;

  const BottomMusicPlayerWidget({
    super.key,
    this.isMobileLayout = false,
    this.allowBigAudioPlayer = false,
  });

  @override
  State<BottomMusicPlayerWidget> createState() =>
      _BottomMusicPlayerWidgetState();
}

class _BottomMusicPlayerWidgetState extends State<BottomMusicPlayerWidget> {
  final AppLogger logger = getLogger("BottomMusicPlayerWidget");

  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();

    subscriptions = [
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

      // Изменения плейлиста и текущего трека.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),

      // Обработчик ошибок плеера.
      player.playerStateStream.listen(
        (event) {},
        onError: (Object error, StackTrace stackTrace) async {
          await player.stop();

          logger.e(
            "Ошибка воспроизведения плеера: ",
            error: error,
            stackTrace: stackTrace,
          );

          if (context.mounted) {
            showErrorDialog(
              context,
              title: "Ошибка воспроизведения",
              description: error.toString(),
            );
          }
        },
      )
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

    final PlayerSchemeProvider colorScheme =
        Provider.of<PlayerSchemeProvider>(context, listen: false);

    /// Запускаем задачу по получению цветовой схемы.
    player.getColorSchemeAsync().then(
      ((ColorScheme, ColorScheme)? schemes) {
        if (schemes == null) return;

        colorScheme.setScheme(
          schemes.$1,
          schemes.$2,
          player.currentAudio!.mediaKey,
        );
      },
    );

    return BottomMusicPlayer(
      audio: player.smartCurrentAudio,
      nextAudio: player.smartNextAudio,
      previousAudio: player.smartPreviousAudio,
      scheme: colorScheme.colorScheme(Theme.of(context).brightness) ??
          Theme.of(context).colorScheme,
      favoriteState:
          player.currentAudio != null ? player.currentAudio!.isLiked : false,
      playbackState: player.playing,
      progress: player.progress,
      volume: player.volume,
      position: player.position,
      duration: player.duration ?? Duration.zero,
      isBuffering: player.buffering,
      isShuffleEnabled: player.shuffleModeEnabled,
      isRepeatEnabled: player.loopMode == LoopMode.one,
      pauseOnMuteEnabled: user.settings.pauseOnMuteEnabled,
      useBigLayout: !widget.isMobileLayout && widget.allowBigAudioPlayer,
      onFavoriteStateToggle: (bool liked) => toggleTrackLikeState(
        context,
        player.currentAudio!,
        !player.currentAudio!.isLiked,
      ),
      onPlayStateToggle: (bool enabled) => player.playOrPause(enabled),
      onProgressChange: (double progress) => player.seekNormalized(progress),
      onVolumeChange: (double volume) => player.setVolume(volume),
      onDismiss: () => player.stop(),
      onFullscreen: (bool viaSwipeUp) => openFullscreenPlayer(
        context,
        fullscreenOnDesktop: !widget.isMobileLayout,
      ),
      onShuffleToggle: (bool enabled) async {
        await player.setShuffle(enabled);
        user.settings.shuffleEnabled = enabled;

        user.markUpdated();
      },
      onRepeatToggle: (bool enabled) => player.setLoop(
        enabled ? LoopMode.one : LoopMode.all,
      ),
      onNextTrack: () => player.next(),
      onPreviousTrack: () => player.previous(
        allowSeekToBeginning: true,
      ),
    );
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

  /// Текущий индекс страницы для [BottomNavigationBar].
  int navigationScreenIndex = 0;

  /// Страницы навигации для [BottomNavigationBar].
  late List<NavigationPage> navigationPages;

  /// Указывает, включён ли раздел с сообщениями.
  ///
  /// В данный момент он отключён за ненадобностью.
  final bool messagesPageEnabled = false;

  @override
  void initState() {
    super.initState();

    navigationPages = [
      if (messagesPageEnabled)
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

    // Если это разрешено, то проверяем на наличие обновлений.
    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    if (user.settings.updatePolicy != UpdatePolicy.disabled) {
      Updater.checkForUpdates(
        context,
        allowPre: user.settings.updateBranch == UpdateBranch.prereleases,
        useSnackbarOnUpdate: user.settings.updatePolicy == UpdatePolicy.popup,
      );
    }
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Блок для навигации (при Desktop Layout'е), а так же содержимое экрана.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Блок для навигации.
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

              // Содержимое экрана.
              Expanded(
                child: NavigatorPopHandler(
                  onPop: () => navigationPage.navigatorKey.currentState?.pop(),
                  child: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 400,
                    ),
                    layoutBuilder: (
                      Widget? currentChild,
                      List<Widget> previousChildren,
                    ) {
                      return currentChild ?? Container();
                    },
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: Navigator(
                      key: navigationPage.navigatorKey,
                      onGenerateRoute: (
                        RouteSettings settings,
                      ) {
                        return MaterialPageRoute(
                          builder: (BuildContext context) {
                            return navigationPage.route;
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Маленький плеер снизу.
          AnimatedAlign(
            duration: const Duration(
              milliseconds: 500,
            ),
            curve: Curves.ease,
            alignment: navigationPage.audioPlayerAlign,
            child: StreamBuilder<bool>(
              stream: player.loadedStateStream,
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                final bool playerLoaded = snapshot.data ?? false;

                return AnimatedOpacity(
                  opacity: playerLoaded ? 1.0 : 0.0,
                  curve: Curves.ease,
                  duration: const Duration(
                    milliseconds: 500,
                  ),
                  child: AnimatedSlide(
                    offset: Offset(
                      0,
                      playerLoaded ? 0.0 : 1.0,
                    ),
                    duration: const Duration(
                      milliseconds: 500,
                    ),
                    curve: Curves.ease,
                    child: AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 500,
                      ),
                      padding:
                          !isMobileLayout && navigationPage.allowBigAudioPlayer
                              ? null
                              : const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
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
                      child: BottomMusicPlayerWidget(
                        isMobileLayout: isMobileLayout,
                        allowBigAudioPlayer: navigationPage.allowBigAudioPlayer,
                      ),
                    ),
                  ),
                );
              },
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
