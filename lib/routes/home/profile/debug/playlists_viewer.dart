import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../../main.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/user.dart";
import "../../../../widgets/dialogs.dart";
import "../../music.dart";

/// Debug-меню, отображаемое в [HomeProfilePage] если включён debug-режим ([kDebugMode]), отображающее техническую информацию о всех плейлистах, которые хранятся в памяти.
class PlaylistsViewerDebugMenu extends ConsumerWidget {
  const PlaylistsViewerDebugMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);

    if (!playlists.hasValue) {
      return const Text(
        "Loading...",
      );
    }

    final playlistsInfo = playlists.value!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Debug playlists viewer",
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        children: [
          // Информация по загруженным плейлистам.
          Text(
            "Total playlists count: ${playlistsInfo.playlists.length}, user owned: ${playlistsInfo.playlistsCount}, from API: ${playlistsInfo.fromAPI}",
          ),
          const Gap(20),

          // Кнопка для копирования плейлистов как JSON.
          FilledButton.icon(
            label: const Text(
              "Dump playlists as JSON",
            ),
            icon: const Icon(
              Icons.javascript_outlined,
            ),
            onPressed: () async {
              final List<Map<String, dynamic>> json =
                  await appStorage.exportAsJSON();
              final String jsonString = jsonEncode(json);

              await Clipboard.setData(
                ClipboardData(text: jsonString),
              );
            },
          ),
          const Gap(8),

          // Кнопка для импортирования содержимого буфера обмена как JSON.
          FilledButton.tonalIcon(
            label: const Text(
              "Import clipboard contents as playlists (removes existing)",
            ),
            icon: const Icon(
              Icons.import_export,
            ),
            onPressed: () async {
              final String jsonString =
                  (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? "";
              try {
                var jsonDecoded = jsonDecode(jsonString) as List<dynamic>;

                await appStorage.importFromJSON(jsonDecoded.cast());
              } on FormatException catch (e) {
                if (context.mounted) {
                  showErrorDialog(
                    context,
                    title: "Malformed JSON",
                    description: e.toString(),
                  );
                }

                return;
              }

              final List<ExtendedPlaylist> playlists =
                  (await appStorage.getPlaylists())
                      .map((item) => item!.asExtendedPlaylist)
                      .toList();

              ref.read(playlistsProvider.notifier).setPlaylists(
                    playlists,
                    fromAPI: true,
                    invalidateDBProvider: true,
                  );
            },
          ),
          const Gap(20),

          // Список плейлистов.
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (ExtendedPlaylist playlist in playlistsInfo.playlists)
                AudioPlaylistWidget(
                  name: playlist.title ?? "<no name>",
                  backgroundUrl: playlist.photo?.photo270,
                  cacheKey: "${playlist.mediaKey}270",
                  description:
                      "isLiveData: ${playlist.isLiveData}\nareTracksLive: ${playlist.areTracksLive}",
                  useTextOnImageLayout: true,
                  onOpen: () => context.push(
                    "/music/playlist/${playlist.ownerID}/${playlist.id}",
                  ),
                ),
            ],
          ),

          const Gap(100),
        ],
      ),
    );
  }
}
