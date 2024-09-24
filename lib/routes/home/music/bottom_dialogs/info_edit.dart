import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../../api/vk/consts.dart";
import "../../../../api/vk/shared.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/user.dart";
import "../../../../provider/vk_api.dart";
import "../../../../services/logger.dart";
import "../../../../widgets/audio_track.dart";
import "../../../../widgets/dialogs.dart";
import "../../../../widgets/loading_button.dart";

/// Диалог, который позволяет пользователю отредактировать данные о треке.
///
/// Пример использования:
/// ```dart
/// openDialog(
///   context: context,
///   builder: (BuildContext context) => const TrackInfoEditDialog(...),
/// ),
/// ```
class TrackInfoEditDialog extends HookConsumerWidget {
  static final AppLogger logger = getLogger("TrackInfoEditDialog");

  /// Плейлист, в котором находится этот трек.
  final ExtendedPlaylist playlist;

  /// Трек, данные которого будут изменяться.
  final ExtendedAudio audio;

  const TrackInfoEditDialog({
    super.key,
    required this.audio,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final titleController = useTextEditingController(text: audio.title);
    final artistController = useTextEditingController(text: audio.artist);
    final trackGenre = useState(audio.genreID);
    useValueListenable(titleController);
    useValueListenable(artistController);

    final ExtendedAudio newAudio = audio.copyWith(
      title: titleController.text,
      artist: artistController.text,
    );
    final bool isChanged = audio.title != titleController.text ||
        audio.artist != artistController.text ||
        audio.genreID != trackGenre.value;

    Future<void> onSave() async {
      final api = ref.read(vkAPIProvider);
      final playlists = ref.read(playlistsProvider.notifier);

      try {
        await api.audio.edit(
          audio.id,
          audio.ownerID,
          titleController.text,
          artistController.text,
          trackGenre.value ?? 18,
        );

        if (!context.mounted) return;
        Navigator.of(context).pop();

        // Обновляем локальную информацию о треке.
        await playlists.updatePlaylist(
          playlist.basicCopyWith(
            audiosToUpdate: [
              audio.basicCopyWith(
                title: titleController.text,
                artist: artistController.text,
                genreID: trackGenre.value,
              ),
            ],
          ),
          saveInDB: true,
        );
      } on VKAPIException catch (e) {
        if (!context.mounted) return;

        if (e.errorCode == 15) {
          showErrorDialog(
            context,
            description: l18n.music_editErrorRestricted,
          );

          return;
        }

        showErrorDialog(
          context,
          description: l18n.music_editError(
            e.toString(),
          ),
        );
      } catch (e, stackTrace) {
        showLogErrorDialog(
          "Error while modifying track:",
          e,
          stackTrace,
          logger,
          // ignore: use_build_context_synchronously
          context,
        );
      }
    }

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Открытый трек.
            AudioTrackTile(
              audio: newAudio,
            ),
            const Gap(8),

            // Разделитель.
            const Divider(),

            // Текстовое поле для изменения названия.
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                label: Text(
                  l18n.music_trackTitle,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: 12,
                  ),
                  child: Icon(
                    Icons.music_note,
                  ),
                ),
              ),
            ),
            const Gap(8),

            // Текстовое поле для изменения исполнителя.
            TextField(
              controller: artistController,
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: 12,
                  ),
                  child: Icon(
                    Icons.album,
                  ),
                ),
                label: Text(
                  l18n.music_trackArtist,
                ),
              ),
            ),
            const Gap(28),

            // Выпадающее меню с жанром.
            DropdownMenu(
              label: Text(
                l18n.music_trackGenre,
              ),
              initialSelection: trackGenre.value,
              dropdownMenuEntries: [
                for (MapEntry<int, String> genre in musicGenres.entries)
                  DropdownMenuEntry(
                    value: genre.key,
                    label: genre.value,
                  ),
              ],
              onSelected: (int? genreID) {
                if (genreID == null) return;

                trackGenre.value = genreID;
              },
            ),
            const Gap(24),

            // Кнопка для сохранения.
            Align(
              alignment: Alignment.bottomRight,
              child: LoadingIconButton.icon(
                icon: const Icon(
                  Icons.edit,
                ),
                label: Text(
                  l18n.general_save,
                ),
                onPressed: isChanged ? onSave : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
