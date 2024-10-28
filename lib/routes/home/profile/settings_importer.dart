import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/tags/styled_text_tag_icon.dart";
import "package:styled_text/widgets/styled_text.dart";

import "../../../main.dart";
import "../../../provider/l18n.dart";
import "../../../utils.dart";
import "../../../widgets/audio_player.dart";
import "../../../widgets/tip_widget.dart";

/// Route для импорта изменений, вызванных функцией "экспорт локальных изменений" в профиле.
///
/// go_route: `/profile/settings_importer`.
class SettingsImporterRoute extends ConsumerWidget {
  const SettingsImporterRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final mobileLayout = isMobileLayout(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.profile_settingsImporterTitle,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Содержимое.
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(
                    mobileLayout ? 16 : 24,
                  ),
                  children: [
                    // Подсказка.
                    TipWidget(
                      iconOnTop: true,
                      title: l18n.profile_settingsImporterTipTitle,
                      descriptionWidget: StyledText(
                        text: l18n.profile_settingsImporterTipDescription,
                        tags: {
                          "exportSettingsIcon": StyledTextIconTag(
                            Icons.file_upload_outlined,
                            size: 20,
                          ),
                          "exportSettings": StyledTextActionTag(
                            (String? text, Map<String?, String?> attrs) {
                              context.push("/profile/settings_exporter");
                            },
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        },
                      ),
                    ),
                    Gap(mobileLayout ? 16 : 24),

                    // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
                    if (player.loaded && mobileLayout)
                      const Gap(MusicPlayerWidget.mobileHeightWithPadding),
                  ],
                ),
              ),

              // Данный Gap нужен, что бы плеер снизу при Desktop Layout'е не закрывал ничего важного.
              // Мы его располагаем после ListView, что бы ScrollBar не был закрыт плеером.
              if (player.loaded && !mobileLayout)
                const Gap(MusicPlayerWidget.desktopMiniPlayerHeight),
            ],
          ),
        ],
      ),
    );
  }
}
