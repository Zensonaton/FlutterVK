import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:skeletonizer/skeletonizer.dart";

import "../../consts.dart";
import "../../provider/auth.dart";
import "../../provider/l18n.dart";
import "../../provider/preferences.dart";
import "../../provider/vk_api.dart";
import "../../utils.dart";
import "../../widgets/shortcuts_propagator.dart";

/// Виджет для [SearchRoute], отображающий популярные запросы поиска.
class _SearchSuggestions extends HookConsumerWidget {
  /// Метод, вызываемый при выборе популярного запроса.
  final void Function(String) onSelect;

  const _SearchSuggestions({
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = useState<List<String>?>(null);
    useEffect(
      () {
        ref.read(vkAPIProvider).catalog.getAudioSearch().then(
          (value) {
            suggestions.value = value.suggestions
                .map(
                  (e) => e.title,
                )
                .toList();
          },
        );

        return null;
      },
      [],
    );
    final suggestionsLoaded = suggestions.value != null;
    final suggestionsOrFake = suggestions.value ?? fakeTrackNames;

    final scheme = ColorScheme.of(context);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            for (var i = 0; i < suggestionsOrFake.length; i++)
              ActionChip(
                avatar: i == 0
                    ? Icon(
                        Icons.auto_awesome,
                        color: scheme.primary,
                      )
                    : null,
                label: Skeletonizer(
                  enabled: !suggestionsLoaded,
                  child: Text(suggestionsOrFake[i]),
                ),
                onPressed: suggestionsLoaded
                    ? () => onSelect.call(suggestionsOrFake[i])
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

/// Виджет для [SearchRoute], отображающий историю поиска, и [SizedBox.shrink], если история пуста.
class _SearchHistory extends ConsumerWidget {
  /// Метод, вызываемый при выборе элемента истории.
  final void Function(String) onSelect;

  /// Метод, вызываемый при очистке истории.
  final void Function() onClear;

  const _SearchHistory({
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final history = ref.watch(
      preferencesProvider.select((prefs) => prefs.searchHistory),
    );

    final scheme = ColorScheme.of(context);

    final mobileLayout = isMobileLayout(context);

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ).copyWith(right: 0),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: scheme.primary,
                ),
                const Gap(8),
                Text(
                  l18n.search_history,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  label: Text(
                    l18n.general_clear,
                    style: TextStyle(
                      color: scheme.secondary,
                    ),
                  ),
                  icon: Icon(
                    Icons.delete,
                    color: scheme.secondary,
                  ),
                  onPressed: onClear,
                ),
              ],
            ),
          ),
          for (String item in history)
            ListTile(
              title: Text(
                item,
              ),
              dense: mobileLayout,
              onTap: () => onSelect(item),
            ),
        ],
      ),
    );
  }
}

/// Route, отображающий страницу с поиском треков: как локальный (т.е., только тех, которые находятся в библиотеке пользователя), так и глобальный.
///
/// go_route: `/search`.
class SearchRoute extends ConsumerWidget {
  const SearchRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final bool recommendationsConnected =
        ref.watch(secondaryTokenProvider) != null;
    final preferencesNotifier = ref.read(preferencesProvider.notifier);

    final mobileLayout = isMobileLayout(context);

    void onSearchType(String query) {}

    void onSuggestionItemSelected(String query) {
      final preferences = ref.read(preferencesProvider);

      final newHistory = [...preferences.searchHistory]
        ..remove(query)
        ..insert(0, query)
        ..take(5);

      preferencesNotifier.setSearchHistory(newHistory);
    }

    void onSearchHistoryClear() {
      preferencesNotifier.setSearchHistory([]);
    }

    return Scaffold(
      body: Padding(
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
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ShortcutsPropagator(
                child: SearchBar(
                  leading: const Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: 12,
                    ),
                    child: Icon(
                      Icons.search,
                    ),
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  hintText: l18n.global_search_query,
                  onChanged: onSearchType,
                  onSubmitted: (query) {
                    final preferences = ref.read(preferencesProvider);

                    final newHistory = [...preferences.searchHistory]
                      ..remove(query)
                      ..insert(0, query)
                      ..take(5);

                    preferencesNotifier.setSearchHistory(newHistory);
                  },
                ),
              ),
            ),
            const Gap(12),
            if (recommendationsConnected) ...[
              _SearchSuggestions(
                onSelect: onSuggestionItemSelected,
              ),
              const Gap(20),
            ],
            Expanded(
              child: ListView(
                clipBehavior: Clip.none,
                children: [
                  _SearchHistory(
                    onSelect: onSuggestionItemSelected,
                    onClear: onSearchHistoryClear,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
