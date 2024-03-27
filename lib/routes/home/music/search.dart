import "dart:async";

import "package:debounce_throttle/debounce_throttle.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:just_audio/just_audio.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:skeletonizer/skeletonizer.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../../api/vk/audio/search.dart";
import "../../../consts.dart";
import "../../../main.dart";
import "../../../provider/user.dart";
import "../../../utils.dart";
import "../../../widgets/adaptive_dialog.dart";
import "../../../widgets/dialogs.dart";
import "../music.dart";
import "playlist.dart";

/// Диалог, показывающий поле для глобального поиска через API ВКонтакте, а так же сами результаты поиска.
class SearchDisplayDialog extends StatefulWidget {
  /// Если true, то сразу после открытия данного диалога фокус будет на [SearchBar].
  final bool focusSearchBarOnOpen;

  const SearchDisplayDialog({
    super.key,
    this.focusSearchBarOnOpen = true,
  });

  @override
  State<SearchDisplayDialog> createState() => _SearchDisplayDialogState();
}

class _SearchDisplayDialogState extends State<SearchDisplayDialog> {
  /// Контроллер, используемый для управления введённым в поле поиска текстом.
  final TextEditingController controller = TextEditingController();

  /// FocusNode для фокуса поля поиска сразу после открытия данного диалога.
  final FocusNode focusNode = FocusNode();

  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  /// Debouncer для поиска.
  final debouncer = Debouncer<String>(
    const Duration(
      seconds: 1,
    ),
    initialValue: "",
  );

  /// Текущий Future по поиску через API ВКонтакте. Может отсутствовать, если ничего не было введено в поиск.
  Future<APIAudioSearchResponse>? searchFuture;

  /// Метод, который вызывается при печати в поле поиска.
  ///
  /// Данный метод вызывается с учётом debouncing'а.
  void onDebounce(String query) {
    // Если мы вышли из текущего Route, то ничего не делаем.
    if (!mounted) return;

    // Проверяем наличие интернета.
    if (!networkRequiredDialog(context)) return;

    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    // Если ничего не введено, то делаем пустой Future.
    if (query.isEmpty) {
      if (searchFuture != null) {
        setState(
          () => searchFuture = null,
        );
      }

      return;
    }

    searchFuture = user.audioSearchWithAlbums(query);
    setState(() {});
  }

  /// Метод, который вызывается при нажатии на клавишу клавиатуры.
  void keyboardListener(
    RawKeyEvent key,
  ) {
    // Нажатие кнопки ESC.
    if (key.isKeyPressed(LogicalKeyboardKey.escape)) {
      // Если в поле поиска есть текст, и это поле находится в фокусе, то ничего не делаем.
      // "Стирание" текста находится в TextField'е.
      if (controller.text.isNotEmpty && focusNode.hasFocus || !mounted) return;

      Navigator.of(context).pop();

      return;
    }

    // Нажатие комбинации CTRL+F.
    if (key.isControlPressed && key.isKeyPressed(LogicalKeyboardKey.keyF)) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
      focusNode.requestFocus();

      return;
    }
  }

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения состояния воспроизведения.
      player.playerStateStream.listen(
        (PlayerState state) => setState(() {}),
      ),

      // Изменения плейлиста.
      player.sequenceStateStream.listen(
        (SequenceState? state) => setState(() {}),
      ),
    ];

    // Обработчик печати.
    controller.addListener(
      () => debouncer.value = controller.text,
    );

    // Обработчик событий поиска, испускаемых Debouncer'ом, если пользователь остановил печать.
    debouncer.values.listen(onDebounce);

    // Если у пользователя ПК, то тогда устанавливаем фокус на поле поиска.
    if (isDesktop && widget.focusSearchBarOnOpen) focusNode.requestFocus();

    // Обработчик нажатия кнопок клавиатуры.
    RawKeyboard.instance.addListener(keyboardListener);
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }

    RawKeyboard.instance.removeListener(keyboardListener);
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    final bool isMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

    return AdaptiveDialog(
      child: Container(
        padding: isMobileLayout
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
            Padding(
              padding: isMobileLayout
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Кнопка "Назад".
                  if (isMobileLayout)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.adaptive.arrow_back,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
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
                        onChanged: (String query) => setState(() {}),
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.music_searchText,
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
                                    onPressed: () => setState(
                                      () => controller.clear(),
                                    ),
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
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: FutureBuilder(
                future: searchFuture,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<APIAudioSearchResponse> snapshot,
                ) {
                  final List<ExtendedAudio>? audios =
                      snapshot.data?.response?.items
                          .map(
                            (audio) => ExtendedAudio.fromAPIAudio(audio),
                          )
                          .toList();

                  // Пользователь ещё ничего не ввёл.
                  if (snapshot.connectionState == ConnectionState.none) {
                    return Text(
                      AppLocalizations.of(context)!.music_typeToSearchText,
                    );
                  }

                  // Информация по данному плейлисту ещё не была загружена.
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      snapshot.hasError ||
                      !(snapshot.hasData && snapshot.data!.error == null)) {
                    return ListView.builder(
                      itemCount: 50,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (BuildContext context, int index) {
                        return Skeletonizer(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8,
                            ),
                            child: AudioTrackTile(
                              audio: ExtendedAudio(
                                id: -1,
                                ownerID: -1,
                                title: fakeTrackNames[
                                    index % fakeTrackNames.length],
                                artist: fakeTrackNames[
                                    (index + 1) % fakeTrackNames.length],
                                duration: 60 * 3,
                                accessKey: "",
                                url: "",
                                date: 0,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Ничего не найдено.
                  if (snapshot.hasData &&
                      snapshot.data!.response!.items.isEmpty) {
                    return StyledText(
                      text:
                          AppLocalizations.of(context)!.music_zeroSearchResults,
                      tags: {
                        "click": StyledTextActionTag(
                          (String? text, Map<String?, String?> attrs) =>
                              setState(
                            () => controller.clear(),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      },
                    );
                  }

                  // Отображаем данные.
                  return ListView.builder(
                    itemCount: audios!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return buildListTrackWidget(
                        context,
                        audios.elementAt(index),
                        ExtendedPlaylist(
                          id: -1,
                          ownerID: user.id!,
                          audios: audios,
                          count: audios.length,
                          title: AppLocalizations.of(context)!
                              .music_searchPlaylistTitle,
                          isLiveData: true,
                          areTracksLive: true,
                        ),
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
