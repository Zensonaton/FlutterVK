import "dart:async";

import "package:audio_service/audio_service.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../api/vk/api.dart";
import "../api/vk/audio/add.dart";
import "../api/vk/audio/add_dislike.dart";
import "../api/vk/audio/delete.dart";
import "../api/vk/audio/restore.dart";
import "../enums.dart";
import "../intents.dart";
import "../main.dart";
import "../provider/l18n.dart";
import "../provider/playlists.dart";
import "../provider/preferences.dart";
import "../provider/user.dart";
import "../services/audio_player.dart";
import "../services/logger.dart";
import "../services/updater.dart";
import "../utils.dart";
import "../widgets/dialogs.dart";
import "fullscreen_player.dart";
import "home/music/categories/realtime_playlists.dart";

/// Диалог, предупреждающий о том, что трек уже сохранён.
class DuplicateWarningDialog extends ConsumerWidget {
  const DuplicateWarningDialog({
    super.key,
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
          child: Text(
            l18n.general_no,
          ),
          onPressed: () => context.pop(false),
        ),
        FilledButton(
          child: Text(
            l18n.general_yes,
          ),
          onPressed: () => context.pop(true),
        ),
      ],
    );
  }
}

/// Проверяет то, существует ли похожий трек в [playlist], и если да, то показывает диалог, спрашивающий у пользователя то, хочет он сохранить трек или нет.
///
/// Возвращает true, если пользователь разрешил сохранение дубликата либо дубликата и вовсе не было, либо false, если пользователь не разрешил.
Future<bool> checkForDuplicates(
  WidgetRef ref,
  BuildContext context,
  ExtendedAudio audio,
) async {
  final favorites = ref.read(favoritesPlaylistProvider)!;

  final bool isDuplicate = favorites.audios!.any(
    (favAudio) =>
        favAudio.isLiked &&
        favAudio.title == audio.title &&
        favAudio.artist == audio.artist &&
        favAudio.album == audio.album,
  );

  if (!isDuplicate) return true;

  final bool? duplicateDialogResult = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return const DuplicateWarningDialog();
    },
  );

  return duplicateDialogResult ?? false;
}

/// Меняет состояние "лайка" у передаваемого трека.
///
/// Если [isLiked] = true, то трек будет восстановлен (если он был удалён ранее), либо же лайкнут. В ином же случае, трек будет удалён из лайкнутых.
Future<void> toggleTrackLike(
  WidgetRef ref,
  ExtendedAudio audio,
  bool isLiked, {
  ExtendedPlaylist? sourcePlaylist,
}) async {
  final AppLogger logger = getLogger("toggleTrackLike");

  final favsPlaylist = ref.read(favoritesPlaylistProvider);
  final userNotifier = ref.read(userProvider.notifier);
  final playlistsNotifier = ref.read(playlistsProvider.notifier);
  final user = ref.read(userProvider);
  assert(
    favsPlaylist != null,
    "Favorites playlist is null",
  );

  // Новый объект ExtendedAudio, хранящий в себе новую версию трека после лайка/дизлайка.
  ExtendedAudio newAudio = audio.copyWith();

  // Список из плейлистов, которые должны быть сохранены.
  List<ExtendedPlaylist> playlistsModified = [];

  if (isLiked) {
    // Пользователь попытался лайкнуть трек.

    // Здесь мы должны проверить, пытается ли пользователь восстановить ранее удалённый трек или нет.
    final bool shouldRestore = favsPlaylist!.audios!.contains(newAudio);

    // Если пользователь пытается восстановить трек, то вызываем audio.restore,
    // в ином случае просто добавляем его методом audio.add.
    int newTrackID;
    if (shouldRestore) {
      newTrackID = newAudio.id;

      // Восстанавливаем трек.
      final APIAudioRestoreResponse response = await userNotifier.audioRestore(
        newTrackID,
        ownerID: newAudio.ownerID,
      );
      raiseOnAPIError(response);

      // TODO: Обработчик ошибки #15: cannot restore too late
    } else {
      // Сохраняем трек как лайкнутый.
      final APIAudioAddResponse response = await userNotifier.audioAdd(
        newAudio.id,
        newAudio.ownerID,
      );
      raiseOnAPIError(response);

      newTrackID = response.response!;

      newAudio = newAudio.copyWith(
        savedFromPlaylist: true,
        relativeID: newTrackID,
        relativeOwnerID: user.id,
        savedPlaylistID: sourcePlaylist?.id,
        savedPlaylistOwnerID: sourcePlaylist?.ownerID,
      );
    }

    // Прекрасно, трек был добавлен либо восстановлён.
    // Запоминаем новую версию плейлиста с лайкнутыми треками.
    playlistsModified.add(
      favsPlaylist
          .copyWithNewAudio(
            newAudio.copyWith(isLiked: true),
          )
          .copyWith(
            count: favsPlaylist.count + 1,
          ),
    );

    // Меняем второй плейлист, откуда этот трек был взят.
    // Здесь мы не трогаем playlistsModified, поскольку сохранять в БД такое изменение не нужно.
    if (sourcePlaylist != null) {
      await playlistsNotifier.updatePlaylist(
        sourcePlaylist.copyWithNewAudio(
          audio.copyWith(
            isLiked: true,
            relativeID: newTrackID,
            relativeOwnerID: user.id,
          ),
        ),
      );
    }
  } else {
    // Пользователь пытается удалить трек.

    // Удаляем трек из лайкнутых.
    final APIAudioDeleteResponse response = await userNotifier.audioDelete(
      audio.savedFromPlaylist ? audio.relativeID! : audio.id,
      audio.savedFromPlaylist ? audio.relativeOwnerID! : audio.ownerID,
    );
    raiseOnAPIError(response);

    // Если это возможно, то удаляем трек из кэша.
    try {
      CachedStreamedAudio(audio: audio).delete();

      newAudio = audio.copyWith(isCached: false);
    } catch (error, stackTrace) {
      logger.w(
        "Couldn't delete cached track after dislike: ",
        error: error,
        stackTrace: stackTrace,
      );
    }

    // Запоминаем новую версию плейлиста с удалённым треком.
    playlistsModified.add(
      favsPlaylist!
          .copyWithNewAudio(
            newAudio.copyWith(
              isLiked: false,
              savedFromPlaylist: false,
            ),
          )
          .copyWith(
            count: favsPlaylist.count - 1,
          ),
    );

    // Удаляем лайкнутый трек из сохранённого ранее плейлиста.
    if (newAudio.savedFromPlaylist) {
      final ExtendedPlaylist? savedPlaylist = playlistsNotifier.getPlaylist(
        newAudio.savedPlaylistOwnerID!,
        newAudio.savedPlaylistID!,
      );
      assert(
        savedPlaylist != null,
        "Attempted to delete track with non-existing parent playlist",
      );

      playlistsModified.add(
        savedPlaylist!.copyWithNewAudio(
          newAudio.copyWith(
            isLiked: false,
            savedFromPlaylist: false,
          ),
        ),
      );
    }
  }

  await playlistsNotifier.updatePlaylists(playlistsModified, saveInDB: true);
}

/// Помечает передаваемый трек [audio] как дизлайкнутый.
Future<void> dislikeTrack(
  WidgetRef ref,
  ExtendedAudio audio,
) async {
  final user = ref.read(userProvider.notifier);

  final APIAudioAddDislikeResponse response =
      await user.audioAddDislike([audio.mediaKey]);
  raiseOnAPIError(response);

  assert(
    response.response,
    "Track is not disliked: ${response.response}",
  );
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
    final bool mobileLayout = isMobileLayout(context);
    final NavigationPage navigationPage =
        navigationPages.elementAt(navigationScreenIndex);

    return Actions(
      actions: {
        FullscreenPlayerIntent: CallbackAction(
          onInvoke: (intent) => openFullscreenPlayer(
            context,
            fullscreenOnDesktop: !mobileLayout,
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
                if (!mobileLayout)
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
                if (!mobileLayout) const VerticalDivider(),

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
        bottomNavigationBar: mobileLayout
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
