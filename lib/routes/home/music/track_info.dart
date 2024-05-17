import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:provider/provider.dart";

import "../../../api/vk/api.dart";
import "../../../api/vk/audio/edit.dart";
import "../../../api/vk/consts.dart";
import "../../../main.dart";
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
class TrackInfoEditDialog extends StatefulWidget {
  /// Трек, данные которого будут изменяться.
  final ExtendedAudio audio;

  const TrackInfoEditDialog({
    super.key,
    required this.audio,
  });

  @override
  State<TrackInfoEditDialog> createState() => _TrackInfoEditDialogState();
}

class _TrackInfoEditDialogState extends State<TrackInfoEditDialog> {
  static AppLogger logger = getLogger("TrackInfoEditDialog");

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
    final UserProvider user = Provider.of<UserProvider>(context);

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
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
              ),
              child: AudioTrackTile(
                audio: audio,
                selected: audio == player.currentAudio,
                currentlyPlaying: player.loaded && player.playing,
              ),
            ),

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
                  AppLocalizations.of(context)!.music_trackTitle,
                ),
              ),
            ),

            // Текстовое поле для изменения исполнителя.
            Padding(
              padding: const EdgeInsets.only(
                bottom: 28,
              ),
              child: TextField(
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
                    AppLocalizations.of(context)!.music_trackArtist,
                  ),
                ),
              ),
            ),

            // Выпадающее меню с жанром.
            Padding(
              padding: const EdgeInsets.only(
                bottom: 24,
              ),
              child: DropdownMenu(
                label: Text(
                  AppLocalizations.of(context)!.music_trackGenre,
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
            ),

            // Кнопка для сохранения.
            Align(
              alignment: Alignment.bottomRight,
              child: FilledButton.icon(
                onPressed: () async {
                  final LoadingOverlay overlay = LoadingOverlay.of(context);

                  Navigator.of(context).pop();
                  overlay.show();

                  try {
                    final APIAudioEditResponse response = await user.audioEdit(
                      widget.audio.ownerID,
                      widget.audio.id,
                      titleController.text,
                      artistController.text,
                      trackGenre,
                    );
                    raiseOnAPIError(response);

                    // Обновляем данные о треке у пользователя.
                    widget.audio.title = titleController.text;
                    widget.audio.artist = artistController.text;
                    widget.audio.genreID = trackGenre;

                    user.markUpdated(false);
                  } catch (e, stackTrace) {
                    logger.e(
                      "Ошибка при редактировании данных трека: ",
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
                icon: const Icon(Icons.edit),
                label: Text(
                  AppLocalizations.of(context)!.general_save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
