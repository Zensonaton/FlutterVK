import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../consts.dart";
import "../../main.dart";
import "../../provider/auth.dart";
import "../../provider/download_manager.dart";
import "../../provider/l18n.dart";
import "../../provider/player_events.dart";
import "../../provider/playlists.dart";
import "../../provider/preferences.dart";
import "../../provider/user.dart";
import "../../provider/vk_api.dart";
import "../../services/cache_manager.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/fallback_audio_photo.dart";
import "music/categories/by_vk_playlists.dart";
import "music/categories/my_music.dart";
import "music/categories/my_playlists.dart";
import "music/categories/realtime_playlists.dart";
import "music/categories/recommended_playlists.dart";
import "music/categories/simillar_music.dart";
import "music/search.dart";
import "profile/dialogs.dart";

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
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FilledButton(
          child: Text(
            l18n.general_yes,
          ),
          onPressed: () => Navigator.of(context).pop(true),
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
  Ref ref,
  ExtendedAudio audio,
  bool isLiked, {
  ExtendedPlaylist? sourcePlaylist,
}) async {
  final logger = getLogger("toggleTrackLike");
  final playlistsNotifier = ref.read(playlistsProvider.notifier);
  final favsPlaylist = ref.read(favoritesPlaylistProvider);
  final user = ref.read(userProvider);
  final api = ref.read(vkAPIProvider);
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
      favsPlaylist!.basicCopyWith(
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
      assert(
        savedPlaylist != null,
        "Attempted to delete track with non-existing parent playlist",
      );

      playlistsModified.add(
        savedPlaylist!.basicCopyWith(
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

  assert(
    response,
    "Track is not disliked: $response",
  );
}

/// Виджет, отображающий плейлист, как обычный так и рекомендательный.
class AudioPlaylistWidget extends HookConsumerWidget {
  /// URL на изображение заднего фона.
  final String? backgroundUrl;

  /// Поле, спользуемое как ключ для кэширования [backgroundUrl].
  final String? cacheKey;

  /// Название данного плейлиста.
  final String name;

  /// Указывает, что надписи данного плейлиста должны располагаться поверх изображения плейлиста.
  ///
  /// Используется у плейлистов по типу "Плейлист дня 1".
  final bool useTextOnImageLayout;

  /// Описание плейлиста.
  final String? description;

  /// Указывает, что музыка играет из этого плейлиста.
  final bool selected;

  /// Указывает, что плеер сейчас воспроизводит музыку.
  final bool currentlyPlaying;

  /// Вызывается при открытии плейлиста во весь экран.
  ///
  /// Вызывается при нажатии не по центру плейлиста. При нажатии по центру плейлиста запускается воспроизведение музыки, либо же она ставится на паузу, если музыка играет из этого плейлиста.
  final VoidCallback? onOpen;

  /// Действие, вызываемое при переключения паузы/возобновления при нажатии по центру плейлиста.
  ///
  /// Если не указывать, то возможность нажать на центр плейлиста будет выключена.
  final Function(bool)? onPlayToggle;

  const AudioPlaylistWidget({
    super.key,
    this.backgroundUrl,
    this.cacheKey,
    required this.name,
    this.useTextOnImageLayout = false,
    this.description,
    this.selected = false,
    this.currentlyPlaying = false,
    this.onOpen,
    this.onPlayToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);

    final bool selectedAndPlaying = selected && currentlyPlaying;

    return Tooltip(
      message: description ?? "",
      waitDuration: const Duration(
        seconds: 1,
      ),
      child: InkWell(
        onTap: onOpen,
        onSecondaryTap: onOpen,
        onHover: (bool value) => isHovered.value = value,
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 500,
                ),
                curve: Curves.ease,
                height: 200,
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
                child: Stack(
                  children: [
                    // Изображение плейлиста.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        globalBorderRadius,
                      ),
                      child: backgroundUrl != null
                          ? CachedNetworkImage(
                              imageUrl: backgroundUrl!,
                              cacheKey: cacheKey,
                              memCacheHeight:
                                  (200 * MediaQuery.devicePixelRatioOf(context))
                                      .round(),
                              memCacheWidth:
                                  (200 * MediaQuery.devicePixelRatioOf(context))
                                      .round(),
                              placeholder: (BuildContext context, String url) =>
                                  const FallbackAudioPlaylistAvatar(),
                              cacheManager: CachedNetworkImagesManager.instance,
                            )
                          : const FallbackAudioPlaylistAvatar(),
                    ),

                    // Затемнение у тех плейлистов, текст которых расположен поверх плейлистов.
                    if (useTextOnImageLayout)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.black38,
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(
                            globalBorderRadius,
                          ),
                        ),
                      ),

                    // Если это у нас рекомендательный плейлист, то текст должен находиться внутри изображения плейлиста.
                    if (useTextOnImageLayout)
                      Padding(
                        padding: const EdgeInsets.all(
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Название плейлиста.
                            Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                            ),

                            // Описание плейлиста.
                            if (description != null)
                              Text(
                                description!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                          ],
                        ),
                      ),

                    // Затемнение, а так же иконка поверх плейлиста.
                    if (isHovered.value || selected)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(
                            globalBorderRadius,
                          ),
                        ),
                        child: !isHovered.value && selectedAndPlaying
                            ? Center(
                                child: RepaintBoundary(
                                  child: Image.asset(
                                    "assets/images/audioEqualizer.gif",
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              )
                            : SizedBox(
                                width: 50,
                                height: 50,
                                child: Center(
                                  child: InkWell(
                                    onTap: isDesktop && onPlayToggle != null
                                        ? () => onPlayToggle?.call(
                                              !selectedAndPlaying,
                                            )
                                        : null,
                                    child: Icon(
                                      selectedAndPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 56,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
              ),

              // Если это обычный плейлист, то нам нужно показать его содержимое под изображением.
              if (!useTextOnImageLayout)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Название плейлиста.
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        ),

                        // Описание плейлиста, при наличии.
                        if (description != null)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 2,
                              ),
                              child: Text(
                                description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: selected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : null,
                                    ),
                              ),
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

/// Виджет, показывающий кучку переключателей-фильтров класса [FilterChip] для включения различных разделов "музыки".
class ChipFilters extends ConsumerWidget {
  /// Указывает, что над этим блоком будет надпись "Активные разделы".
  final bool showLabel;

  const ChipFilters({
    super.key,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final secondaryToken = ref.read(secondaryTokenProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerLoadedStateProvider);

    final bool hasRecommendations = secondaryToken != null;
    final bool mobileLayout = isMobileLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Активные разделы".
        if (showLabel) ...[
          Text(
            l18n.music_filterChipsLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(14),
        ],

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Подключение рекомендаций.
            if (!hasRecommendations)
              ActionChip(
                avatar: const Icon(
                  Icons.auto_fix_high,
                ),
                label: Text(
                  l18n.music_connectRecommendationsChipTitle,
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const ConnectRecommendationsDialog(),
                ),
              ),

            // "Моя музыка".
            if (!mobileLayout)
              FilterChip(
                onSelected: (bool value) =>
                    prefsNotifier.setMyMusicChipEnabled(value),
                selected: preferences.myMusicChipEnabled,
                label: Text(
                  l18n.music_myMusicChip,
                ),
              ),

            // "Ваши плейлисты".
            FilterChip(
              onSelected: (bool value) =>
                  prefsNotifier.setPlaylistsChipEnabled(value),
              selected: preferences.playlistsChipEnabled,
              label: Text(
                l18n.music_myPlaylistsChip,
              ),
            ),

            // "В реальном времени".
            if (hasRecommendations)
              FilterChip(
                onSelected: (bool value) =>
                    prefsNotifier.setRealtimePlaylistsChipEnabled(value),
                selected: preferences.realtimePlaylistsChipEnabled,
                label: Text(
                  l18n.music_realtimePlaylistsChip,
                ),
              ),

            // "Плейлисты для Вас".
            if (hasRecommendations)
              FilterChip(
                onSelected: (bool value) =>
                    prefsNotifier.setRecommendedPlaylistsChipEnabled(value),
                selected: preferences.recommendedPlaylistsChipEnabled,
                label: Text(
                  l18n.music_recommendedPlaylistsChip,
                ),
              ),

            // "Совпадения по вкусам".
            if (hasRecommendations)
              FilterChip(
                onSelected: (bool value) =>
                    prefsNotifier.setSimilarMusicChipEnabled(value),
                selected: preferences.similarMusicChipEnabled,
                label: Text(
                  l18n.music_similarMusicChip,
                ),
              ),

            // "Собрано редакцией".
            if (hasRecommendations)
              FilterChip(
                onSelected: (bool value) =>
                    prefsNotifier.setByVKChipEnabled(value),
                selected: preferences.byVKChipEnabled,
                label: Text(
                  l18n.music_byVKChip,
                ),
              ),
          ],
        ),
      ],
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
          l18n.music_allBlocksDisabledTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        const Gap(8),

        // "Соскучились по музыке? ..."
        Text(
          l18n.music_allBlocksDisabledDescription,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Страница для управления музыкой.
class HomeMusicPage extends HookConsumerWidget {
  const HomeMusicPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final user = ref.watch(userProvider);
    final preferences = ref.watch(preferencesProvider);
    final downloadManager = ref.watch(downloadManagerProvider);
    ref.watch(playerLoadedStateProvider);

    final bool mobileLayout = isMobileLayout(context);

    /// Указывает, что у пользователя подключены рекомендации музыки от ВКонтакте.
    final bool hasRecommendations = ref.read(secondaryTokenProvider) != null;

    final bool myMusic = preferences.myMusicChipEnabled;
    final bool playlists = preferences.playlistsChipEnabled;
    final bool realtimePlaylists =
        hasRecommendations && preferences.realtimePlaylistsChipEnabled;
    final bool recommendedPlaylists =
        hasRecommendations && preferences.recommendedPlaylistsChipEnabled;
    final bool similarMusic =
        hasRecommendations && preferences.similarMusicChipEnabled;
    final bool byVK = hasRecommendations && preferences.byVKChipEnabled;

    bool everythingIsDisabled;

    // Если рекомендации включены, то мы должны учитывать и другие разделы.
    if (hasRecommendations) {
      everythingIsDisabled = (!(myMusic ||
          playlists ||
          realtimePlaylists ||
          recommendedPlaylists ||
          similarMusic ||
          byVK));
    } else {
      everythingIsDisabled = (!(myMusic || playlists));
    }

    /// [List], содержащий в себе список из виджетов/разделов на главном экране, которые доожны быть разделены [Divider]'ом.
    final List<Widget> activeBlocks = useMemoized(
      () => [
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

        // Нижняя часть интерфейса с переключателями при Mobile Layout'е.
        if (mobileLayout) const ChipFilters(),

        // Случай, если пользователь отключил все возможные разделы музыки.
        if (everythingIsDisabled) const EverythingIsDisabledBlock(),
      ],
      [
        myMusic,
        playlists,
        realtimePlaylists,
        recommendedPlaylists,
        similarMusic,
        byVK,
        everythingIsDisabled,
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
                    isConnected ? l18n.music_label : l18n.music_labelOffline,
                  );
                },
              ),
              centerTitle: true,
              actions: [
                // Кнопка для менеджера загрузок.
                if (downloadManager.downloadStarted)
                  IconButton(
                    onPressed: () => context.go("/profile/downloadManager"),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    left: mobileLayout ? 16 : 24,
                    right: mobileLayout ? 16 : 24,
                    top: mobileLayout ? 4 : 30,
                    bottom: mobileLayout ? 20 : 30,
                  ),
                  children: [
                    // Часть интерфейса "Добро пожаловать", а так же кнопка поиска.
                    if (!mobileLayout)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 36,
                        ),
                        child: Row(
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
                                      CachedNetworkImage(
                                        imageUrl: user.photoMaxUrl!,
                                        cacheKey: "${user.id}400",
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
                                      const Gap(18),
                                    ],

                                    // Текст "Добро пожаловать".
                                    Text(
                                      l18n.music_welcomeTitle(
                                        user.firstName,
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
                      ),

                    // Верхняя часть интерфейса с переключателями при Desktop Layout'е.
                    if (!mobileLayout)
                      const ChipFilters(
                        showLabel: false,
                      ),
                    if (!mobileLayout)
                      const Padding(
                        padding: EdgeInsets.only(
                          top: 8,
                          bottom: 2,
                        ),
                        child: Divider(),
                      ),

                    // Проходимся по всем активным разделам, создавая виджеты [Divider] и [SizedBox].
                    for (int i = 0; i < activeBlocks.length; i++) ...[
                      // Содержимое блока.
                      activeBlocks[i],

                      // Divider в случае, если это не последний элемент.
                      if (i < activeBlocks.length - 1) ...[
                        const Gap(8),
                        const Divider(),
                        const Gap(4),
                      ],
                    ],

                    // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
                    if (player.loaded && mobileLayout)
                      const Gap(mobileMiniPlayerHeight),
                  ],
                ),
              ),

              // Данный Gap нужен, что бы плеер снизу при Desktop Layout'е не закрывал ничего важного.
              // Мы его располагаем после ListView, что бы ScrollBar не был закрыт плеером.
              if (player.loaded && !mobileLayout)
                const Gap(desktopMiniPlayerHeight),
            ],
          ),
        ),
      ),
    );
  }
}
