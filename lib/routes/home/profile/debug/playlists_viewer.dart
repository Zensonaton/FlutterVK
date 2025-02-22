import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:share_plus/share_plus.dart";

import "../../../../provider/db.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/user.dart";
import "../../../../widgets/dialogs.dart";
import "../../../../widgets/playlist.dart";

/// Route для debug-меню, отображающее техническую информацию о всех плейлистах, которые хранятся в памяти.
///
/// go_route: `/profile/playlists_viewer_debug`.
class PlaylistsViewerDebugMenu extends ConsumerWidget {
  const PlaylistsViewerDebugMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final appStorage = ref.read(appStorageProvider);

    if (!playlists.hasValue) {
      return const Text(
        "Loading...",
      );
    }

    final playlistsInfo = playlists.value!;

    Future<String> getJSONString() async =>
        const JsonEncoder.withIndent("\t").convert(
          await appStorage.exportAsJSON(),
        );

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
            "Total playlists count: ${playlistsInfo.playlists.length}, user owned: ${playlistsInfo.playlistsCount}",
          ),
          const Gap(20),

          Row(
            // spacing: 8,
            children: [
              // Кнопка для копирования плейлистов как JSON.
              Expanded(
                child: FilledButton.icon(
                  label: const Text(
                    "Copy playlists dump",
                  ),
                  icon: const Icon(
                    Icons.copy,
                  ),
                  onPressed: () async => Clipboard.setData(
                    ClipboardData(
                      text: await getJSONString(),
                    ),
                  ),
                ),
              ),
              const Gap(8),

              // Кнопка для того, что бы поделиться плейлистами как JSON.
              Expanded(
                child: FilledButton.icon(
                  label: const Text(
                    "Share playlists dump",
                  ),
                  icon: const Icon(
                    Icons.share,
                  ),
                  onPressed: () async {
                    final String jsonString = await getJSONString();

                    await Share.share(
                      jsonString,
                      subject: "Playlists JSON.json",
                    );
                  },
                ),
              ),
            ],
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
                  await appStorage.getPlaylists();

              ref.read(playlistsProvider.notifier).setPlaylists(
                    playlists,
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
                PlaylistWidget(
                  name: playlist.title ?? "<no name>",
                  backgroundUrl: playlist.photo?.photo600,
                  cacheKey: "${playlist.mediaKey}600",
                  description:
                      "live: ${playlist.isLiveData}, tracksLive: ${playlist.areTracksLive}, cache: ${playlist.cacheTracks ?? false}",
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
