import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
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
import "../services/cache_manager.dart";
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
          onSelected: (bool value) {
            HapticFeedback.selectionClick();

            prefsNotifier.setMyMusicChipEnabled(value);
          },
          selected: preferences.myMusicChipEnabled,
          label: Text(
            l18n.my_music_chip,
          ),
        ),

      // "Ваши плейлисты".
      FilterChip(
        onSelected: (bool value) {
          HapticFeedback.selectionClick();

          prefsNotifier.setPlaylistsChipEnabled(value);
        },
        selected: preferences.playlistsChipEnabled,
        label: Text(
          l18n.my_playlists_chip,
        ),
      ),

      // "В реальном времени".
      if (hasRecommendations)
        FilterChip(
          onSelected: (bool value) {
            HapticFeedback.selectionClick();

            prefsNotifier.setRealtimePlaylistsChipEnabled(value);
          },
          selected: preferences.realtimePlaylistsChipEnabled,
          label: Text(
            l18n.realtime_playlists_chip,
          ),
        ),

      // "Плейлисты для Вас".
      if (hasRecommendations)
        FilterChip(
          onSelected: (bool value) {
            HapticFeedback.selectionClick();

            prefsNotifier.setRecommendedPlaylistsChipEnabled(value);
          },
          selected: preferences.recommendedPlaylistsChipEnabled,
          label: Text(
            l18n.recommended_playlists_chip,
          ),
        ),

      // "Совпадения по вкусам".
      if (hasRecommendations)
        FilterChip(
          onSelected: (bool value) {
            HapticFeedback.selectionClick();

            prefsNotifier.setSimilarMusicChipEnabled(value);
          },
          selected: preferences.similarMusicChipEnabled,
          label: Text(
            l18n.simillar_music_chip,
          ),
        ),

      // "Собрано редакцией".
      if (hasRecommendations)
        FilterChip(
          onSelected: (bool value) {
            HapticFeedback.selectionClick();

            prefsNotifier.setByVKChipEnabled(value);
          },
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
class MusicRoute extends HookConsumerWidget {
  const MusicRoute({
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
