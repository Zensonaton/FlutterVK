import "dart:async";

import "package:audio_service/audio_service.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../enums.dart";
import "../intents.dart";
import "../main.dart";
import "../provider/l18n.dart";
import "../provider/preferences.dart";
import "../provider/user.dart";
import "../services/logger.dart";
import "../services/updater.dart";
import "../utils.dart";
import "../widgets/dialogs.dart";
import "../widgets/loading_overlay.dart";
import "fullscreen_player.dart";
import "home/music/categories/realtime_playlists.dart";

/// Диалог, предупреждающий о том, что трек уже сохранён.
class DuplicateWarningDialog extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.copy,
      title: l18n.checkBeforeFavoriteWarningTitle,
      text: l18n.checkBeforeFavoriteWarningDescription,
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            l18n.general_no,
          ),
        ),
        FilledButton(
          onPressed: () async {
            // Проверяем наличие интернета.
            if (!networkRequiredDialog(ref, context)) return;

            context.pop();

            await toggleTrackLikeState(
              context,
              audio,
              true,
              checkBeforeSaving: false,
            );
          },
          child: Text(
            l18n.general_yes,
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
  WidgetRef ref,
  ExtendedAudio audio,
  bool isFavorite,
) async {
  // ignore: unused_local_variable
  final AppLogger logger = getLogger("toggleTrackLike");

  return;

  // TODO

  // if (isFavorite) {
  //   // Пользователь попытался лайкнуть трек.
  //   // Здесь мы должны проверить, пытается ли пользователь восстановить ранее удалённый трек или нет.
  //   final bool shouldRestore = user.favoritesPlaylist!.audios!.contains(audio);

  //   audio.isLiked = true;

  //   // Если пользователь пытается восстановить трек, то вызываем audio.restore,
  //   // в ином случае просто добавляем его методом audio.add.
  //   if (shouldRestore) {
  //     // Восстанавливаем трек.
  //     final APIAudioRestoreResponse response = await user.audioRestore(
  //       audio.id,
  //       ownerID: audio.ownerID,
  //     );
  //     raiseOnAPIError(response);
  //   } else {
  //     // Сохраняем трек как лайкнутый.
  //     final APIAudioAddResponse response = await user.audioAdd(
  //       audio.id,
  //       audio.ownerID,
  //     );
  //     raiseOnAPIError(response);

  //     audio.oldID = audio.id;
  //     audio.oldOwnerID = audio.ownerID;

  //     audio.id = response.response!;
  //     audio.ownerID = user.id!;
  //   }

  //   // Прекрасно, трек был добавлен либо восстановлён.
  //   // Теперь нам нужно запомнить то, что трек лайкнут.
  //   audio.isLiked = true;

  //   // Добавляем трек в список фаворитов.
  //   user.favoritesPlaylist!.count += 1;

  //   // Убеждаемся, что трек не существует в списке, после чего добавляем его в самое начало.
  //   if (!user.favoritesPlaylist!.audios!.contains(audio)) {
  //     user.favoritesPlaylist!.audios!.insert(0, audio);
  //   }

  //   user.updatePlaylist(user.favoritesPlaylist!);
  //   user.markUpdated(false);
  // } else {
  //   // Пользователь пытается удалить трек.

  //   // Удаляем трек из лайкнутых.
  //   final APIAudioDeleteResponse response = await user.audioDelete(
  //     audio.id,
  //     audio.ownerID,
  //   );
  //   raiseOnAPIError(response);

  //   // Всё ок, помечаем трек как не лайкнутый.
  //   user.favoritesPlaylist!.count -= 1;
  //   audio.isLiked = false;

  //   // Если это возможно, то удаляем трек из кэша.
  //   try {
  //     CachedStreamedAudio(audio: audio).delete();

  //     audio.isCached = false;
  //   } catch (e) {
  //     logger.w(
  //       "Couldn't delete cached track after dislike: ",
  //       error: e,
  //     );
  //   }
  // }
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
  return;

  // TODO

  // final UserProvider user = Provider.of<UserProvider>(context, listen: false);
  // final AppLogger logger = getLogger("toggleTrackLikeState");

  // // Если это разрешено, то проверяем, есть ли такой трек в лайкнутых.
  // if (isFavorite && checkBeforeSaving) {
  //   bool isDuplicate = user.favoritesPlaylist!.audios!.any(
  //     (favAudio) =>
  //         favAudio.isLiked &&
  //         favAudio.title == audio.title &&
  //         favAudio.artist == audio.artist &&
  //         favAudio.album == audio.album,
  //   );

  //   // Если это дубликат, то показываем предупреждение об этом.
  //   if (isDuplicate) {
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) => DuplicateWarningDialog(
  //         audio: audio,
  //         playlist: user.favoritesPlaylist!,
  //       ),
  //     );

  //     return;
  //   }
  // }

  // LoadingOverlay.of(context).show();

  // try {
  //   // Делаем API запросы для удаления/добавления трека.
  //   await toggleTrackLike(
  //     user,
  //     audio,
  //     isFavorite,
  //   );
  // } catch (e, stackTrace) {
  //   showLogErrorDialog(
  //     "Ошибка при попытке сделать трек лайкнутым/дизлайкнутым (новое состояние: $isFavorite): ",
  //     e,
  //     stackTrace,
  //     logger,
  //     // ignore: use_build_context_synchronously
  //     context,
  //   );
  // } finally {
  //   if (context.mounted) LoadingOverlay.of(context).hide();
  // }

  // // Посылаем обновления объекта пользователя.
  // user.markUpdated(false);
}

/// Помечает передаваемый трек [audio] как дизлайкнутый.
Future<void> dislikeTrack(
  WidgetRef ref,
  ExtendedAudio audio,
) async {
  // TODO

  // final APIAudioAddDislikeResponse response =
  //     await user.audioAddDislike([audio.mediaKey]);
  // raiseOnAPIError(response);

  // assert(
  //   response.response,
  //   "Track is not disliked: ${response.response}",
  // );
}

/// Помечает передаваемый трек [audio] как дизлайкнутый. При вызове, начинается анимация загрузки ([LoadingOverlay]).
///
/// Возвращает то, был ли запрос успешен.
Future<bool> dislikeTrackState(
  BuildContext context,
  ExtendedAudio audio,
) async {
  // ignore: unused_local_variable
  final AppLogger logger = getLogger("addDislikeTrackState");

  return false;
  // TODO

  // LoadingOverlay.of(context).show();

  // try {
  //   await dislikeTrack(user, audio);

  //   return true;
  // } catch (e, stackTrace) {
  //   showLogErrorDialog(
  //     "Ошибка при дизлайке трека: ",
  //     e,
  //     stackTrace,
  //     logger,
  //     // ignore: use_build_context_synchronously
  //     context,
  //   );

  //   return false;
  // } finally {
  //   if (context.mounted) LoadingOverlay.of(context).hide();
  // }
}

/// Route, показываемый как "домашняя страница", где расположена навигация между разными частями приложения.
@Deprecated("Используется go_router вместо этого виджета.")
class HomeRoute extends ConsumerStatefulWidget {
  const HomeRoute({
    super.key,
  });

  @override
  ConsumerState<HomeRoute> createState() => _HomeRouteState();
}

class _HomeRouteState extends ConsumerState<HomeRoute> {
  static final AppLogger logger = getLogger("HomeRoute");

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
  void initState() {
    super.initState();

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

      // Загружаем информацию по треку, если есть соединение с интернетом.
      if (connectivityManager.hasConnection) {
        // TODO

        // CachedStreamedAudio.downloadTrackData(
        //   audio,
        //   player.currentPlaylist!,
        //   user,
        //   allowDeezer: user.settings.deezerThumbnails,
        //   allowSpotifyLyrics:
        //       user.settings.spotifyLyrics && user.spDCcookie != null,
        //   saveInDB: true,
        // ).then((updatedDB) async {
        //   // Делаем так, что бы плеер обновил обложку трека.
        //   await player.updateMusicSessionTrack();

        //   // Если мы уже получили цвета обложки, то ничего не делаем.
        //   if (gotColorscheme || !updatedDB) return;

        //   await getColorScheme();
        // });
      }

      // // Запускаем задачу по получению цветовой схемы.
      // gotColorscheme = await getColorScheme();
    });

    // Слушаем события изменения текущего трека, что бы в случае, если запущен рекомендательный плейлист, мы передавали информацию об этом ВКонтакте.
    player.currentIndexStream.listen((int? index) async {
      if (index == null) return;

      // Если это не рекомендуемый плейлист, то ничего не делаем.
      if (!(player.currentPlaylist?.isRecommendationTypePlaylist ?? false)) {
        return;
      }

      // Если нет доступа к интернету, то ничего не делаем.
      if (!connectivityManager.hasConnection) return;

      // Делаем API-запрос, передавая информацию серверам ВКонтакте.
      try {
        // final APIAudioSendStartEventResponse response =
        //     await user.audioSendStartEvent(player.currentAudio!.mediaKey);
        // raiseOnAPIError(response);

        // TODO
      } catch (e, stackTrace) {
        logger.w(
          "Couldn't notify VK about track listening state: ",
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
        // TODO
        // final APIAudioGetStreamMixAudiosResponse response =
        //     await user.audioGetStreamMixAudiosWithAlbums(count: tracksToAdd);
        // raiseOnAPIError(response);

        // final List<ExtendedAudio> newAudios = response.response!
        //     .map(
        //       (audio) => ExtendedAudio.fromAPIAudio(audio),
        //     )
        //     .toList();

        // // Добавляем треки в объект плейлиста.
        // player.currentPlaylist!.audios!.addAll(newAudios);
        // player.currentPlaylist!.count += response.response!.length;

        // // Добавляем треки в очередь воспроизведения плеера.
        // for (ExtendedAudio audio in newAudios) {
        //   await player.addToQueueEnd(audio);
        // }
      } catch (e, stackTrace) {
        logger.e(
          "Couldn't load audio mix tracks: ",
          error: e,
          stackTrace: stackTrace,
        );

        if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = isMobileLayout(context);
    final NavigationPage navigationPage =
        navigationPages.elementAt(navigationScreenIndex);

    return Actions(
      actions: {
        FullscreenPlayerIntent: CallbackAction(
          onInvoke: (intent) => openFullscreenPlayer(
            context,
            fullscreenOnDesktop: !isMobile,
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
                if (!isMobile)
                  NavigationRail(
                    selectedIndex: navigationScreenIndex,
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
                if (!isMobile) const VerticalDivider(),

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
          ],
        ),
        bottomNavigationBar: isMobile
            ? NavigationBar(
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
