import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../../consts.dart";
import "../../../enums.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player.dart";
import "../../../provider/playlists.dart";
import "../../../provider/user.dart";
import "../../../provider/vk_api.dart";
import "../../../utils.dart";
import "../../../widgets/adaptive_dialog.dart";
import "../../../widgets/audio_track.dart";
import "../../../widgets/dialogs.dart";

/// Диалог, показывающий поле для глобального поиска через API ВКонтакте, а так же сами результаты поиска.
class SearchDisplayDialog extends HookConsumerWidget {
  /// Если true, то сразу после открытия данного диалога фокус будет на [SearchBar].
  final bool focusSearchBarOnOpen;

  const SearchDisplayDialog({
    super.key,
    this.focusSearchBarOnOpen = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(searchResultsPlaylistProvider);
    final l18n = ref.watch(l18nProvider);
    final user = ref.watch(userProvider);
    final api = ref.read(vkAPIProvider);
    ref.watch(playerIsPlayingProvider);
    ref.watch(playerAudioProvider);

    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final ValueNotifier<Future<ExtendedPlaylist>?> searchFuture =
        useState(null);
    final debouncedInput = useDebounced(
      controller.text,
      const Duration(milliseconds: 500),
    );
    useValueListenable(controller);

    void onSearch() {
      if (!context.mounted && !networkRequiredDialog(ref, context)) return;

      final l18n = ref.read(l18nProvider);
      final String query = controller.text.trim();

      Future<ExtendedPlaylist> search() async {
        final response = await api.audio.searchWithAlbums(query);

        // Создаём фейковый плейлист с треками.
        final List<ExtendedAudio> audios = response.items
            .map((item) => ExtendedAudio.fromAPIAudio(item))
            .toList();
        final ExtendedPlaylist playlist = ExtendedPlaylist(
          id: -1,
          ownerID: user.id,
          type: PlaylistType.searchResults,
          audios: audios,
          count: audios.length,
          title: l18n.general_search_playlist,
          isLiveData: true,
          areTracksLive: true,
        );

        // Запоминаем этот плейлист.
        await ref.read(playlistsProvider.notifier).updatePlaylist(playlist);

        return playlist;
      }

      // Если ничего не введено, то делаем пустой Future.
      if (query.isEmpty) {
        if (searchFuture.value != null) {
          searchFuture.value = null;
        }

        return;
      }

      // Делаем запрос по получению результатов поиска.
      searchFuture.value = search();
    }

    void onSearchClear() => controller.clear();

    useEffect(
      () {
        // Если у пользователя ПК, то тогда устанавливаем фокус на поле поиска.
        if (isDesktop && focusSearchBarOnOpen) focusNode.requestFocus();

        return null;
      },
      [],
    );
    useEffect(
      () {
        if (debouncedInput == null) return;
        onSearch();

        return null;
      },
      [debouncedInput],
    );

    final bool mobileLayout = isMobileLayout(context);

    return AdaptiveDialog(
      child: Container(
        padding: mobileLayout
            ? const EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
              )
            : const EdgeInsets.all(
                24,
              ),
        width: 650,
        child: Column(
          children: [
            // Верхний AppBar.
            Padding(
              padding: mobileLayout
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Кнопка "Назад".
                  if (mobileLayout)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 12,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.adaptive.arrow_back,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),

                  // Поиск.
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(
                          LogicalKeyboardKey.escape,
                        ): () => controller.clear(),
                      },
                      child: TextField(
                        focusNode: focusNode,
                        controller: controller,
                        onEditingComplete: onSearch,
                        decoration: InputDecoration(
                          hintText: l18n.search_music_global,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              globalBorderRadius,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                          ),
                          suffixIcon: controller.text.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 12,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                    ),
                                    onPressed: onSearchClear,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Содержимое поиска.
            Expanded(
              child: FutureBuilder(
                future: searchFuture.value,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<ExtendedPlaylist> snapshot,
                ) {
                  final List<ExtendedAudio>? audios = playlist?.audios;

                  // Пользователь ещё ничего не ввёл.
                  if (snapshot.connectionState == ConnectionState.none) {
                    return Text(
                      l18n.type_to_search,
                    );
                  }

                  // Информация по данному плейлисту ещё не была загружена.
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      snapshot.hasError) {
                    return ListView.separated(
                      itemCount: 50,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (BuildContext context, int index) {
                        return const Gap(trackTileSpacing);
                      },
                      itemBuilder: (BuildContext context, int index) {
                        return Skeletonizer(
                          child: AudioTrackTile(
                            audio: ExtendedAudio(
                              id: -1,
                              ownerID: -1,
                              title:
                                  fakeTrackNames[index % fakeTrackNames.length],
                              artist: fakeTrackNames[
                                  (index + 1) % fakeTrackNames.length],
                              duration: 60 * 3,
                              accessKey: "",
                              url: "",
                              date: 0,
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Ничего не найдено.
                  if (snapshot.hasData && audios!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      child: StyledText(
                        text: l18n.playlist_search_zero_results,
                        tags: {
                          "click": StyledTextActionTag(
                            (_, __) => onSearchClear(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        },
                      ),
                    );
                  }

                  // Отображаем данные.
                  return ListView.separated(
                    itemCount: audios!.length,
                    separatorBuilder: (BuildContext context, int index) {
                      return const Gap(trackTileSpacing);
                    },
                    itemBuilder: (BuildContext context, int index) {
                      return buildListTrackWidget(
                        ref,
                        context,
                        audios[index],
                        playlist!,
                        allowImageCache: false,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
