import "dart:async";

import "package:audio_service/audio_service.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";

import "../api/vk/api.dart";
import "../api/vk/audio/add.dart";
import "../api/vk/audio/add_dislike.dart";
import "../api/vk/audio/delete.dart";
import "../api/vk/audio/get_stream_mix_audios.dart";
import "../api/vk/audio/restore.dart";
import "../api/vk/audio/send_start_event.dart";
import "../enums.dart";
import "../intents.dart";
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
import "home/music/categories/realtime_playlists.dart";
import "home/profile.dart";

/// Диалог, предупреждающий о том, что трек уже сохранён.
class DuplicateWarningDialog extends StatelessWidget {
  /// Аудио, которое пользователь попытался лайкнуть.
  final ExtendedAudio audio;

  /// Плейлист с лайкнутыми треками.
  final ExtendedPlaylist playlist;

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
        FilledButton(
          onPressed: () async {
            // Проверяем наличие интернета.
            if (!networkRequiredDialog(context)) return;

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
        ),
      ],
    );
  }
}

/// Меняет состояние "лайка" у передаваемого трека.
///
/// В отличии от метода [toggleTrackLikeState], данный метод не делает никаких проверок на существование трека, а так же никаких изменений в интерфейсе не происходит.
Future<void> toggleTrackLike(
  UserProvider user,
  ExtendedAudio audio,
  bool isFavorite,
) async {
  final AppLogger logger = getLogger("toggleTrackLike");

  if (isFavorite) {
    // Пользователь попытался лайкнуть трек.
    // Здесь мы должны проверить, пытается ли пользователь восстановить ранее удалённый трек или нет.
    final bool shouldRestore = user.favoritesPlaylist!.audios!.contains(audio);

    audio.isLiked = true;

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

    // Убеждаемся, что трек не существует в списке, после чего добавляем его в самое начало.
    if (!user.favoritesPlaylist!.audios!.contains(audio)) {
      user.favoritesPlaylist!.audios!.insert(0, audio);
    }

    user.updatePlaylist(user.favoritesPlaylist!);
    user.markUpdated(false);
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
      CachedStreamedAudio(audio: audio).delete();

      audio.isCached = false;
    } catch (e) {
      logger.w(
        "Не удалось удалить трек из кэша после удаления трека из лайкнутых: ",
        error: e,
      );
    }
  }
}

/// Меняет состояние "лайка" у передаваемого трека [audio]. При вызове, начинается анимация загрузки ([LoadingOverlay]).
///
/// Если [checkBeforeSaving] равен true, то в случае дубликата трека появится диалог, подтверждающий создание дубликата.
Future<void> toggleTrackLikeState(
  BuildContext context,
  ExtendedAudio audio,
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

  // Посылаем обновления объекта пользователя.
  user.markUpdated(false);
}

/// /// Помечает передаваемый трек [audio] как дизлайкнутый.
///
/// Возвращает то, был ли запрос успешен.
Future<void> dislikeTrack(
  UserProvider user,
  ExtendedAudio audio,
) async {
  final APIAudioAddDislikeResponse response =
      await user.audioAddDislike([audio.mediaKey]);
  raiseOnAPIError(response);

  assert(response.response, "Track is not disliked: ${response.response}");
}

/// Помечает передаваемый трек [audio] как дизлайкнутый. При вызове, начинается анимация загрузки ([LoadingOverlay]).
///
/// Возвращает то, был ли запрос успешен.
Future<bool> dislikeTrackState(
  BuildContext context,
  ExtendedAudio audio,
) async {
  final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  final AppLogger logger = getLogger("addDislikeTrackState");

  LoadingOverlay.of(context).show();

  try {
    await dislikeTrack(user, audio);

    return true;
  } catch (e, stackTrace) {
    // ignore: use_build_context_synchronously
    showLogErrorDialog(
      "Ошибка при дизлайке трека: ",
      e,
      stackTrace,
      logger,
      context,
    );

    return false;
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

  /// Ключ для [Navigator].
  final GlobalKey<NavigatorState> navigatorKey;

  const BottomMusicPlayerWidget({
    super.key,
    this.isMobileLayout = false,
    this.allowBigAudioPlayer = false,
    required this.navigatorKey,
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

      // Пауза/воспроизведение.
      player.playingStream.listen(
        (bool playing) => setState(() {}),
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

    final PlayerSchemeProvider colorScheme =
        Provider.of<PlayerSchemeProvider>(context, listen: false);

    final bool isMixPlaylistPlaying =
        player.currentPlaylist?.isAudioMixPlaylist ?? false;

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
      onFavoriteStateToggle: (bool liked) {
        if (!networkRequiredDialog(context)) return;

        toggleTrackLikeState(
          context,
          player.currentAudio!,
          !player.currentAudio!.isLiked,
        );
      },
      onDislike: (player.currentPlaylist?.isRecommendationTypePlaylist ?? false)
          ? () async {
              if (!networkRequiredDialog(context)) return;

              // Делаем трек дизлайкнутым.
              final bool result =
                  await dislikeTrackState(context, player.currentAudio!);
              if (!result) return;

              // Запускаем следующий трек в плейлисте.
              await player.next();
            }
          : null,
      onPlayStateToggle: (bool enabled) => player.playOrPause(enabled),
      onProgressChange: (double progress) => player.seekNormalized(progress),
      onVolumeChange: (double volume) => player.setVolume(volume),
      onDismiss: () => player.stop(),
      onFullscreen: (bool viaSwipeUp) => openFullscreenPlayer(
        context,
        fullscreenOnDesktop: !widget.isMobileLayout &&
            !RawKeyboard.instance.keysPressed
                .contains(LogicalKeyboardKey.shiftLeft),
      ),
      onMiniplayer: () => openMiniPlayer(context),
      onShuffleToggle: !isMixPlaylistPlaying
          ? (bool enabled) async {
              await player.setShuffle(enabled);
              user.settings.shuffleEnabled = enabled;

              user.markUpdated();
            }
          : null,
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

  /// Проверяет на наличие обновлений, и дальше предлагает пользователю обновиться, если есть новое обновление.
  void checkForUpdates() {
    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    // Проверяем, есть ли разрешение на обновления, а так же работу интернета.
    if (user.settings.updatePolicy == UpdatePolicy.disabled ||
        !connectivityManager.hasConnection) return;

    // Проверяем на наличие обновлений.
    Updater.checkForUpdates(
      context,
      allowPre: user.settings.updateBranch == UpdateBranch.prereleases,
      useSnackbarOnUpdate: user.settings.updatePolicy == UpdatePolicy.popup,
    );
  }

  @override
  void initState() {
    super.initState();

    final UserProvider user = Provider.of<UserProvider>(context, listen: false);
    final PlayerSchemeProvider colorScheme =
        Provider.of<PlayerSchemeProvider>(context, listen: false);

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

    // Проверяем на наличие обновлений, если мы не запущены в debug-режме.
    if (!kDebugMode) {
      checkForUpdates();
    }

    // Слушаем события подключения к интернету.
    connectivityManager.connectionChange.listen((bool isConnected) {
      logger.d("Network connectivity state: $isConnected");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(
            seconds: isConnected ? 2 : 6,
          ),
          content: Text(
            isConnected
                ? AppLocalizations.of(context)!
                    .internetConnectionRestoredDescription
                : AppLocalizations.of(context)!.noInternetConnectionDescription,
          ),
        ),
      );

      // Проверяем на наличие обновлений, если мы не запущены в debug-режме.
      if (!kDebugMode) {
        checkForUpdates();
      }
    });

    // Слушаем события нажатия на медиа-уведомление.
    AudioService.notificationClicked.listen((tapped) {
      logger.d("Handling player notification clicked event");

      // AudioService иногда создаёт это событие при запуске плеера. Такой случай мы игнорируем.
      if (!tapped) return;

      // Если плеер не загружен, то ничего не делаем.
      if (!player.loaded) return;

      openFullscreenPlayer(context);
    });

    // Слушаем события изменения текущего трека в плеере, что бы загружать обложку, текст песни, а так же создание цветовой схемы.
    player.currentIndexStream.listen((int? index) async {
      if (index == null || !player.loaded) return;

      final ExtendedAudio audio = player.currentAudio!;

      /// Указывает, были ли получены цвета для этого трека или нет.
      bool gotColorscheme = false;

      /// Внутренний метод, который создаёт [ColorScheme], после чего сохраняет его внутрь [PlayerSchemeProvider].
      Future<bool> getColorScheme() async {
        final (ColorScheme, ColorScheme)? schemes =
            await player.getColorSchemeAsync(
          useBetterAlgorithm: user.settings.playerSchemeAlgorithm,
        );

        if (schemes == null) return false;

        colorScheme.setScheme(
          schemes.$1,
          schemes.$2,
          audio.mediaKey,
        );

        return true;
      }

      // Загружаем информацию по треку, если есть соединение с интернетом.
      if (connectivityManager.hasConnection) {
        CachedStreamedAudio.downloadTrackData(
          audio,
          player.currentPlaylist!,
          user,
          allowDeezer: user.settings.deezerThumbnails,
          allowSpotifyLyrics:
              user.settings.spotifyLyrics && user.spDCcookie != null,
          saveInDB: true,
        ).then((updatedDB) async {
          // Делаем так, что бы плеер обновил обложку трека.
          await player.updateMusicSessionTrack();

          // Если мы уже получили цвета обложки, то ничего не делаем.
          if (gotColorscheme || !updatedDB) return;

          await getColorScheme();
        });
      }

      // Запускаем задачу по получению цветовой схемы.
      gotColorscheme = await getColorScheme();
    });

    // Слушаем события изменения текущего трека, что бы в случае, если запущен рекомендательный плейлист, мы передавали информацию об этом ВКонтакте.
    player.currentIndexStream.listen((int? index) async {
      if (index == null) return;

      // Если это не рекомендуемый плейлист, то ничего не делаем.
      if (!(player.currentPlaylist?.isRecommendationTypePlaylist ?? false)) {
        return;
      }

      // Если мы слушаем рекомендуемый плейлист, однако разрешение на отправку инфы не дано, то ничего не делаем, кроме предупреждения.
      if (!user.settings.recommendationsStatsWarning) {
        logger.w(
          "Playing recommendation playlist (${player.currentPlaylist}), but not broadcasting recommendations info, because no permission was given.",
        );

        return;
      }

      // Если нет доступа к интернету, то ничего не делаем.
      if (!connectivityManager.hasConnection) return;

      // Делаем API-запрос, передавая информацию серверам ВКонтакте.
      try {
        final APIAudioSendStartEventResponse response =
            await user.audioSendStartEvent(player.currentAudio!.mediaKey);

        raiseOnAPIError(response);
      } catch (e, stackTrace) {
        logger.w(
          "Не удалось оповестить сервера ВКонтакте о текущем рекомендуемом треке: ",
          error: e,
          stackTrace: stackTrace,
        );
      }
    });

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
        final APIAudioGetStreamMixAudiosResponse response =
            await user.audioGetStreamMixAudiosWithAlbums(count: tracksToAdd);
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
          "Ошибка при загрузке дополнительных треков для аудио микса: ",
          error: e,
          stackTrace: stackTrace,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!
                    .musicMixAudiosAddError(e.toString()),
              ),
            ),
          );
        }

        return;
      }

      logger.d(
        "Successfully added $tracksToAdd tracks to mix queue (current: ${player.currentPlaylist!.count})",
      );
    });
  }

  /// Изменяет выбранную страницу для [BottomNavigationBar] по передаваемому индексу страницы.
  void setNavigationPage(int pageIndex) {
    assert(
      pageIndex >= 0 && pageIndex < navigationPages.length,
      "Expected pageIndex to be in range of 0 to ${navigationPages.length}, but got $pageIndex instead",
    );

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

    return Actions(
      actions: {
        FullscreenPlayerIntent: CallbackAction(
          onInvoke: (intent) => openFullscreenPlayer(
            context,
            fullscreenOnDesktop: !isMobileLayout,
          ),
        ),
      },
      child: Scaffold(
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
                        ),
                    ],
                  ),
                if (!isMobileLayout) const VerticalDivider(),

                // Содержимое экрана.
                Expanded(
                  child: NavigatorPopHandler(
                    onPop: () =>
                        navigationPage.navigatorKey.currentState?.pop(),
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
                        padding: !isMobileLayout &&
                                navigationPage.allowBigAudioPlayer
                            ? null
                            : const EdgeInsets.all(
                                8,
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
                          allowBigAudioPlayer:
                              navigationPage.allowBigAudioPlayer,
                          navigatorKey: navigationPage.navigatorKey,
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
                    ),
                ],
              )
            : null,
      ),
    );
  }
}
