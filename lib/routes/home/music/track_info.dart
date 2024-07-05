import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../api/vk/consts.dart";
import "../../../main.dart";
import "../../../provider/l18n.dart";
import "../../../provider/user.dart";
import "../../../services/logger.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/loading_overlay.dart";
import "../music.dart";

/// Диалог, который позволяет пользователю отредактировать данные о треке.
///
/// Пример использования:
/// ```dart
/// openDialog(
///   context: context,
///   builder: (BuildContext context) => const TrackInfoEditDialog(...),
/// ),
/// ```
class TrackInfoEditDialog extends ConsumerStatefulWidget {
  /// Трек, данные которого будут изменяться.
  final ExtendedAudio audio;

  const TrackInfoEditDialog({
    super.key,
    required this.audio,
  });

  @override
  ConsumerState<TrackInfoEditDialog> createState() =>
      _TrackInfoEditDialogState();
}

class _TrackInfoEditDialogState extends ConsumerState<TrackInfoEditDialog> {
  static final AppLogger logger = getLogger("TrackInfoEditDialog");

  /// [TextEditingController] для поля ввода названия трека.
  final TextEditingController titleController = TextEditingController();

  /// [TextEditingController] для поля ввода артиста трека.
  final TextEditingController artistController = TextEditingController();

  /// Выбранный жанр у трека.
  late int trackGenre;

  @override
  void initState() {
    super.initState();

    titleController.text = widget.audio.title;
    artistController.text = widget.audio.artist;
    trackGenre = widget.audio.genreID ?? 18; // Жанр "Other".
  }

  @override
  Widget build(BuildContext context) {
    final l18n = ref.watch(l18nProvider);

    // Создаём копию трека, засовывая в неё новые значения с новым именем трека и прочим.
    final ExtendedAudio audio = ExtendedAudio(
      title: titleController.text,
      artist: artistController.text,
      id: widget.audio.id,
      ownerID: widget.audio.ownerID,
      duration: widget.audio.duration,
      accessKey: widget.audio.accessKey,
      url: widget.audio.url,
      date: widget.audio.date,
      album: widget.audio.album,
      isLiked: widget.audio.isLiked,
    );

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
              audio: audio,
              selected: audio == player.currentAudio,
              currentlyPlaying: player.loaded && player.playing,
            ),
            const Gap(8),

            // Разделитель.
            const Divider(),

            // Текстовое поле для изменения названия.
            TextField(
              controller: titleController,
              onChanged: (String _) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: 12,
                  ),
                  child: Icon(
                    Icons.music_note,
                  ),
                ),
                label: Text(
                  l18n.music_trackTitle,
                ),
              ),
            ),

            // Текстовое поле для изменения исполнителя.
            TextField(
              controller: artistController,
              onChanged: (String _) => setState(() {}),
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
              onSelected: (int? genreID) {
                if (genreID == null) return;

                setState(() => trackGenre = genreID);
              },
              initialSelection: widget.audio.genreID ?? 18, // Жанр "Other".
              dropdownMenuEntries: [
                for (MapEntry<int, String> genre in musicGenres.entries)
                  DropdownMenuEntry(
                    value: genre.key,
                    label: genre.value,
                  ),
              ],
            ),
            const Gap(24),

            // Кнопка для сохранения.
            Align(
              alignment: Alignment.bottomRight,
              child: FilledButton.icon(
                icon: const Icon(
                  Icons.edit,
                ),
                label: Text(
                  l18n.general_save,
                ),
                onPressed: () async {
                  final LoadingOverlay overlay = LoadingOverlay.of(context);

                  context.pop();
                  overlay.show();

                  try {
                    // final APIAudioEditResponse response = await user.audioEdit(
                    //   widget.audio.ownerID,
                    //   widget.audio.id,
                    //   titleController.text,
                    //   artistController.text,
                    //   trackGenre,
                    // );
                    // raiseOnAPIError(response);

                    // Обновляем данные о треке у пользователя.
                    widget.audio.title = titleController.text;
                    widget.audio.artist = artistController.text;
                    widget.audio.genreID = trackGenre;

                    // user.markUpdated(false);
                  } catch (e, stackTrace) {
                    logger.e(
                      "Error while modifying track info: ",
                      error: e,
                      stackTrace: stackTrace,
                    );

                    if (context.mounted) {
                      showErrorDialog(
                        context,
                        description: e.toString(),
                      );
                    }
                  } finally {
                    overlay.hide();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
