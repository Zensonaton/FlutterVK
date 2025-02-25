import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../main.dart";
import "../provider/auth.dart";
import "../provider/download_manager.dart";
import "../provider/l18n.dart";
import "../provider/player.dart";
import "../provider/playlists.dart";
import "../provider/preferences.dart";
import "../provider/user.dart";
import "../provider/vk_api.dart";
import "../services/cache_manager.dart";
import "../services/logger.dart";
import "../utils.dart";
import "../widgets/audio_player.dart";
import "../widgets/dialogs.dart";
import "../widgets/page_route_builders.dart";
import "login.dart";
import "music/categories/by_vk_playlists.dart";
import "music/categories/my_music.dart";
import "music/categories/my_playlists.dart";
import "music/categories/realtime_playlists.dart";
import "music/categories/recommended_playlists.dart";
import "music/categories/simillar_music.dart";
import "music/search.dart";

/// Проверяет то, существует ли похожий трек в [playlist], и если да, то показывает диалог, спрашивающий у пользователя то, хочет он сохранить трек или нет.
///
/// Возвращает true, если пользователь разрешил сохранение дубликата либо дубликата и вовсе не было, либо false, если пользователь не разрешил.
Future<bool> checkForDuplicates(
  WidgetRef ref,
  BuildContext context,
  ExtendedAudio audio,
) async {
  final l18n = ref.watch(l18nProvider);
  final favorites = ref.read(favoritesPlaylistProvider)!;

  final bool isDuplicate = favorites.audios!.any(
    (favAudio) =>
        favAudio.isLiked &&
        favAudio.title == audio.title &&
        favAudio.artist == audio.artist &&
        favAudio.album == audio.album,
  );

  if (!isDuplicate) return true;

  return await showYesNoDialog(
        context,
        icon: Icons.copy,
        title: l18n.track_duplicate_found_title,
        description: l18n.track_duplicate_found_desc,
      ) ??
      false;
}

/// Меняет состояние "лайка" у передаваемого трека.
///
/// Если [isLiked] = true, то трек будет восстановлен (если он был удалён ранее), либо же лайкнут. В ином же случае, трек будет удалён из лайкнутых.
Future<void> toggleTrackLike(
  Ref ref,
  ExtendedAudio audio, {
  ExtendedPlaylist? sourcePlaylist,
}) async {
  final logger = getLogger("toggleTrackLike");
  final playlistsNotifier = ref.read(playlistsProvider.notifier);
  final favsPlaylist = ref.read(favoritesPlaylistProvider);
  final user = ref.read(userProvider);
  final api = ref.read(vkAPIProvider);
  if (favsPlaylist == null) {
    throw Exception("Favorites playlist is null");
  }

  final newLikeState = !audio.isLiked;

  // Новый объект ExtendedAudio, хранящий в себе новую версию трека после лайка/дизлайка.
  ExtendedAudio newAudio = audio.copyWith();

  // Список из плейлистов, которые должны быть сохранены.
  List<ExtendedPlaylist> playlistsModified = [];

  if (newLikeState) {
    // Пользователь попытался лайкнуть трек.

    // Здесь мы должны проверить, пытается ли пользователь восстановить ранее удалённый трек или нет.
    final bool shouldRestore = favsPlaylist.audios!.contains(newAudio);

    // Если пользователь пытается восстановить трек, то вызываем audio.restore,
    // в ином случае просто добавляем его методом audio.add.
    int newTrackID;
    if (shouldRestore) {
      final int ownerID = newAudio.relativeOwnerID ?? newAudio.ownerID;
      newTrackID = newAudio.relativeID ?? newAudio.id;

      logger.d("Restore ${ownerID}_$newTrackID");

      // Восстанавливаем трек.
      await api.audio.restore(
        newTrackID,
        ownerID,
      );

      newAudio = newAudio.copyWith(
        isLiked: true,
      );
    } else {
      final int ownerID = newAudio.relativeOwnerID ?? newAudio.ownerID;
      newTrackID = newAudio.id;

      // Сохраняем трек как лайкнутый.
      newTrackID = await api.audio.add(
        newTrackID,
        ownerID,
      );

      logger.d("Add ${ownerID}_${newAudio.id}, got ${user.id}_$newTrackID");

      newAudio = newAudio.copyWith(
        isLiked: true,
        relativeID: newTrackID,
        relativeOwnerID: user.id,
        savedFromPlaylist: sourcePlaylist != null,
        savedPlaylistID: sourcePlaylist?.id,
        savedPlaylistOwnerID: sourcePlaylist?.ownerID,
      );
    }

    // Прекрасно, трек был добавлен либо восстановлён.
    // Запоминаем новую версию плейлиста с лайкнутыми треками.
    playlistsModified.add(
      favsPlaylist.basicCopyWith(
        audiosToUpdate: [newAudio],
        count: favsPlaylist.count! + 1,
      ),
    );

    // Меняем второй плейлист, откуда этот трек был взят.
    // Здесь мы не трогаем playlistsModified, поскольку сохранять в БД такое изменение не нужно.
    if (sourcePlaylist != null) {
      await playlistsNotifier.updatePlaylist(
        sourcePlaylist.basicCopyWith(
          audiosToUpdate: [
            audio.basicCopyWith(
              isLiked: true,
              relativeID: newTrackID,
              relativeOwnerID: user.id,
            ),
          ],
        ),
      );
    }
  } else {
    // Пользователь пытается удалить трек.

    final int ownerID = newAudio.relativeOwnerID ?? newAudio.ownerID;
    final int newTrackID = newAudio.relativeID ?? newAudio.id;
    logger.d("Delete ${ownerID}_$newTrackID");

    // Удаляем трек из лайкнутых.
    await api.audio.delete(
      newTrackID,
      ownerID,
    );

    // Запоминаем новую версию плейлиста "любимые треки" с удалённым треком.
    playlistsModified.add(
      favsPlaylist.basicCopyWith(
        audiosToUpdate: [
          newAudio.basicCopyWith(
            isLiked: false,
            savedFromPlaylist: false,
          ),
        ],
        audios: favsPlaylist.audios!,
        count: favsPlaylist.count! - 1,
      ),
    );

    // Если мы не трогали плейлист "любимые" треки, то модифицируем его.
    if (sourcePlaylist != null &&
        !(sourcePlaylist.id == favsPlaylist.id &&
            sourcePlaylist.ownerID == favsPlaylist.ownerID)) {
      playlistsModified.add(
        sourcePlaylist.basicCopyWith(
          audiosToUpdate: [
            newAudio.basicCopyWith(
              isLiked: false,
              savedFromPlaylist: false,
            ),
          ],
        ),
      );
    }

    // Удаляем лайкнутый трек из сохранённого ранее плейлиста.
    if (newAudio.savedFromPlaylist) {
      final ExtendedPlaylist? savedPlaylist = playlistsNotifier.getPlaylist(
        newAudio.savedPlaylistOwnerID!,
        newAudio.savedPlaylistID!,
      );
      if (savedPlaylist == null) {
        throw Exception(
          "Attempted to delete track with non-existing parent playlist",
        );
      }

      playlistsModified.add(
        savedPlaylist.basicCopyWith(
          audiosToUpdate: [
            newAudio.basicCopyWith(
              isLiked: false,
              savedFromPlaylist: false,
            ),
          ],
        ),
      );
    }
  }

  await playlistsNotifier.updatePlaylists(
    playlistsModified,
    saveInDB: true,
  );
}

/// Помечает передаваемый трек [audio] как дизлайкнутый.
Future<void> dislikeTrack(Ref ref, ExtendedAudio audio) async {
  final api = ref.read(vkAPIProvider);

  final bool response = await api.audio.addDislike([audio.mediaKey]);

  if (!response) {
    throw Exception("Track is not disliked: $response");
  }
}

/// Виджет, показывающий кучку переключателей-фильтров класса [FilterChip] для включения различных разделов "музыки".
class ChipFilters extends ConsumerWidget {
  /// Указывает, что будет использоваться [Wrap] вместо [SingleChildScrollView].
  final bool useWrap;

  const ChipFilters({
    super.key,
    this.useWrap = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final secondaryToken = ref.read(secondaryTokenProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerIsLoadedProvider);

    final bool hasRecommendations = secondaryToken != null;
    final bool mobileLayout = isMobileLayout(context);

    final List<Widget> children = [
      // Подключение рекомендаций.
      if (!hasRecommendations)
        ActionChip(
          avatar: const Icon(
            Icons.auto_fix_high,
          ),
          label: Text(
            l18n.connect_recommendations_chip,
          ),
          onPressed: () async {
            final result = await showYesNoDialog(
              context,
              icon: Icons.auto_fix_high,
              title: l18n.connect_recommendations_title,
              description: l18n.connect_recommendations_desc,
            );
            if (result != true || !context.mounted) return;

            Navigator.push(
              context,
              Material3PageRoute(
                builder: (context) => const LoginRoute(
                  useAlternateAuth: true,
                ),
              ),
            );
          },
        ),

      // "Моя музыка".
      if (!mobileLayout)
        FilterChip(
          onSelected: (bool value) =>
              prefsNotifier.setMyMusicChipEnabled(value),
          selected: preferences.myMusicChipEnabled,
          label: Text(
            l18n.my_music_chip,
          ),
        ),

      // "Ваши плейлисты".
      FilterChip(
        onSelected: (bool value) =>
            prefsNotifier.setPlaylistsChipEnabled(value),
        selected: preferences.playlistsChipEnabled,
        label: Text(
          l18n.my_playlists_chip,
        ),
      ),

      // "В реальном времени".
      if (hasRecommendations)
        FilterChip(
          onSelected: (bool value) =>
              prefsNotifier.setRealtimePlaylistsChipEnabled(value),
          selected: preferences.realtimePlaylistsChipEnabled,
          label: Text(
            l18n.realtime_playlists_chip,
          ),
        ),

      // "Плейлисты для Вас".
      if (hasRecommendations)
        FilterChip(
          onSelected: (bool value) =>
              prefsNotifier.setRecommendedPlaylistsChipEnabled(value),
          selected: preferences.recommendedPlaylistsChipEnabled,
          label: Text(
            l18n.recommended_playlists_chip,
          ),
        ),

      // "Совпадения по вкусам".
      if (hasRecommendations)
        FilterChip(
          onSelected: (bool value) =>
              prefsNotifier.setSimilarMusicChipEnabled(value),
          selected: preferences.similarMusicChipEnabled,
          label: Text(
            l18n.simillar_music_chip,
          ),
        ),

      // "Собрано редакцией".
      if (hasRecommendations)
        FilterChip(
          onSelected: (bool value) => prefsNotifier.setByVKChipEnabled(value),
          selected: preferences.byVKChipEnabled,
          label: Text(
            l18n.by_vk_chip,
          ),
        ),
    ];

    if (useWrap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: children,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Wrap(
        spacing: 8,
        children: children,
      ),
    );
  }
}

/// Виджет, показывающий надпись в случае, если пользователь отключил все разделы музыки.
class EverythingIsDisabledBlock extends ConsumerWidget {
  const EverythingIsDisabledBlock({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return Column(
      children: [
        // "Как пусто..."
        Text(
          l18n.all_blocks_disabled,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        const Gap(8),

        // "Соскучились по музыке? ..."
        Text(
          l18n.all_blocks_disabled_desc,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Route, отображающий главную страницу с треками пользователя, различными плейлистами и прочей информацией.
///
/// go_route: `/music`.
class HomeMusicPage extends HookConsumerWidget {
  const HomeMusicPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    final user = ref.watch(userProvider);
    final preferences = ref.watch(preferencesProvider);
    final downloadManager = ref.watch(downloadManagerProvider);
    ref.watch(playerIsLoadedProvider);

    final bool mobileLayout = isMobileLayout(context);

    /// Указывает, что у пользователя подключены рекомендации музыки от ВКонтакте.
    final bool hasRecommendations = ref.read(secondaryTokenProvider) != null;

    final bool myMusic = !mobileLayout && preferences.myMusicChipEnabled;
    final bool playlists = preferences.playlistsChipEnabled;
    final bool realtimePlaylists =
        hasRecommendations && preferences.realtimePlaylistsChipEnabled;
    final bool recommendedPlaylists =
        hasRecommendations && preferences.recommendedPlaylistsChipEnabled;
    final bool similarMusic =
        hasRecommendations && preferences.similarMusicChipEnabled;
    final bool byVK = hasRecommendations && preferences.byVKChipEnabled;

    /// [List], содержащий в себе список из виджетов/разделов на главном экране, которые доожны быть разделены [Divider]'ом.
    final List<Widget> activeBlocks = useMemoized(
      () {
        bool everythingIsDisabled = () {
          if (hasRecommendations) {
            return !myMusic &&
                !playlists &&
                !realtimePlaylists &&
                !recommendedPlaylists &&
                !similarMusic &&
                !byVK;
          }

          return !myMusic && !playlists;
        }();

        return [
          // Раздел "Моя музыка".
          if (myMusic && !mobileLayout) const MyMusicBlock(),

          // Раздел "Ваши плейлисты".
          if (playlists) const MyPlaylistsBlock(),

          // Раздел "В реальном времени".
          if (realtimePlaylists) const RealtimePlaylistsBlock(),

          // Раздел "Плейлисты для Вас".
          if (recommendedPlaylists) const RecommendedPlaylistsBlock(),

          // Раздел "Совпадения по вкусам".
          if (similarMusic) const SimillarMusicBlock(),

          // Раздел "Собрано редакцией".
          if (byVK) const ByVKPlaylistsBlock(),

          // Случай, если пользователь отключил все возможные разделы музыки.
          if (everythingIsDisabled) const EverythingIsDisabledBlock(),
        ];
      },
      [
        myMusic,
        playlists,
        realtimePlaylists,
        recommendedPlaylists,
        similarMusic,
        byVK,
        mobileLayout,
      ],
    );

    return Scaffold(
      appBar: mobileLayout
          ? AppBar(
              title: StreamBuilder<bool>(
                stream: connectivityManager.connectionChange,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final bool isConnected = connectivityManager.hasConnection;

                  return Text(
                    isConnected ? l18n.music_label : l18n.music_label_offline,
                  );
                },
              ),
              centerTitle: true,
              actions: [
                // Кнопка для менеджера загрузок.
                if (downloadManager.downloadStarted)
                  IconButton(
                    onPressed: () => context.go("/profile/download_manager"),
                    icon: const Icon(
                      Icons.download,
                    ),
                  ),

                // Кнопка для поиска.
                IconButton(
                  onPressed: () {
                    if (!networkRequiredDialog(ref, context)) return;

                    showDialog(
                      context: context,
                      builder: (context) => const SearchDisplayDialog(),
                    );
                  },
                  icon: const Icon(
                    Icons.search,
                  ),
                ),
                const Gap(16),
              ],
            )
          : null,
      body: ScrollConfiguration(
        behavior: AlwaysScrollableScrollBehavior(),
        child: RefreshIndicator.adaptive(
          onRefresh: () => ref.refresh(playlistsProvider.future),
          child: ListView(
            padding: getPadding(
              context,
              useLeft: mobileLayout,
              useRight: mobileLayout,
              useTop: !mobileLayout,
              useBottom: !mobileLayout,
              custom: EdgeInsets.symmetric(
                horizontal: mobileLayout ? 4 : 12,
              ),
            ).add(
              const EdgeInsets.all(12),
            ),
            children: [
              // Часть интерфейса "Добро пожаловать", а так же кнопка поиска.
              if (!mobileLayout) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Аватарка пользователя.
                            if (user.photoMaxUrl != null) ...[
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CachedNetworkImage(
                                  imageUrl: user.photoMaxUrl!,
                                  cacheKey: "${user.id}400",
                                  width: 40,
                                  height: 40,
                                  imageBuilder: (
                                    BuildContext context,
                                    ImageProvider imageProvider,
                                  ) {
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                  cacheManager:
                                      CachedNetworkImagesManager.instance,
                                ),
                              ),
                              const Gap(18),
                            ],

                            // Текст "Добро пожаловать".
                            Text(
                              l18n.music_welcome_title(
                                name: user.firstName,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(18),

                    // Поиск.
                    IconButton.filledTonal(
                      onPressed: () {
                        if (!networkRequiredDialog(ref, context)) {
                          return;
                        }

                        showDialog(
                          context: context,
                          builder: (context) {
                            return const SearchDisplayDialog();
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.search,
                      ),
                    ),
                  ],
                ),
                const Gap(36),
              ],

              // Верхняя часть интерфейса с переключателями при Desktop Layout'е, использующие Wrap.
              ChipFilters(
                useWrap: !mobileLayout,
              ),
              const Gap(8),
              if (!mobileLayout) ...[
                const Divider(),
                const Gap(4),
              ],

              // Проходимся по всем активным разделам, создавая виджеты [Divider] и [SizedBox].
              for (int i = 0; i < activeBlocks.length; i++) ...[
                // Содержимое блока.
                activeBlocks[i],

                // Divider в случае, если это не последний элемент.
                if (i < activeBlocks.length - 1)
                  if (mobileLayout)
                    const Gap(20)
                  else ...[
                    const Gap(8),
                    const Divider(),
                    const Gap(4),
                  ],
              ],

              // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
              if (player.isLoaded && mobileLayout)
                const Gap(MusicPlayerWidget.mobileHeightWithPadding),
            ],
          ),
        ),
      ),
    );
  }
}
