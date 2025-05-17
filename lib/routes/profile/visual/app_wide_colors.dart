import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";

import "../../../provider/auth.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player.dart";
import "../../../provider/preferences.dart";
import "../../../widgets/setting_widgets.dart";

/// Route для настроек, отображающий параметры настройки "Цвета трека по всему приложению".
///
/// go_route: `/profile/setting_app_wide_colors`.
class AppWideColorsSettingPage extends HookConsumerWidget {
  const AppWideColorsSettingPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);

    final recommendationsConnected = ref.watch(secondaryTokenProvider) != null;

    final smiToggle = useState<SMIBool?>(null);
    final smiTrigger = useState<SMITrigger?>(null);
    final isAppWideColors = preferences.playerColorsAppWide;

    return SettingPageWithAnimationWidget(
      title: l18n.use_player_colors_appwide,
      description: l18n.use_player_colors_appwide_desc,
      warning: () {
        if (!recommendationsConnected) {
          return l18n.option_unavailable_without_recommendations;
        }

        if (!player.isLoaded) {
          return l18n.option_unavailable_without_audio_playing;
        }
      }(),
      headerImage: RiveAnimationBlock(
        name: "appWideColors",
        artboardName: "AppWideColors",
        onStateMachineController: (StateMachineController controller) {
          final boolInput = controller.getBoolInput("AppWideColorsEnabled");
          final trigger = controller.getTriggerInput("OnToggle");

          boolInput!.value = isAppWideColors;
          smiToggle.value = boolInput;
          smiTrigger.value = trigger;
        },
      ),
      children: [
        SettingsCardWidget(
          child: SwitchListTile.adaptive(
            title: Text(
              l18n.enable_player_colors_appwide,
            ),
            value: isAppWideColors,
            onChanged: recommendationsConnected
                ? (bool? value) {
                    HapticFeedback.lightImpact();
                    if (value == null) return;

                    prefsNotifier.setPlayerColorsAppWide(value);
                    smiToggle.value?.value = value;
                    smiTrigger.value?.fire();
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
