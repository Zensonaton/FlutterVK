import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";

import "../../../../provider/l18n.dart";
import "../../../../provider/preferences.dart";
import "../../../../utils.dart";
import "../../../../widgets/setting_widgets.dart";

/// Route для настроек, отображающий параметры настройки "OLED-тема".
///
/// go_route: `/profile/setting_oled`.
class OLEDSettingPage extends HookConsumerWidget {
  const OLEDSettingPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);

    final smiToggle = useState<SMIBool?>(null);
    final darkTheme = isDarkTheme(context);
    final isOLEDTheme = preferences.oledTheme;

    return SettingPageWithAnimationWidget(
      title: l18n.oled_theme,
      description: l18n.oled_theme_desc,
      warning: !darkTheme ? l18n.option_unavailable_with_light_theme : null,
      headerImage: RiveAnimationBlock(
        name: "oled",
        artboardName: "OLED",
        onStateMachineController: (StateMachineController controller) {
          final boolInput = controller.getBoolInput("OLEDEnabled");

          boolInput!.value = isOLEDTheme;
          smiToggle.value = boolInput;
        },
      ),
      children: [
        SettingsCardWidget(
          child: SwitchListTile.adaptive(
            title: Text(
              l18n.enable_oled_theme,
            ),
            value: isOLEDTheme && darkTheme,
            onChanged: darkTheme
                ? (bool? value) {
                    HapticFeedback.lightImpact();
                    if (value == null) return;

                    prefsNotifier.setOLEDThemeEnabled(value);
                    smiToggle.value?.value = value;
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
