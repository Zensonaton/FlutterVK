import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";

import "../../../../../provider/l18n.dart";
import "../../../../../provider/preferences.dart";
import "../../../../../utils.dart";
import "../../../../../widgets/setting_widgets.dart";

/// Route для настроек, отображающий параметры настройки "Тема".
///
/// go_route: `/profile/setting_theme_mode`.
class ThemeSettingPage extends HookConsumerWidget {
  const ThemeSettingPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);

    final smiToggle = useState<SMIBool?>(null);
    final darkTheme = isDarkTheme(context);

    void onValueChanged(ThemeMode? mode) {
      HapticFeedback.lightImpact();
      if (mode == null) return;

      prefsNotifier.setTheme(mode);
    }

    useEffect(
      () {
        smiToggle.value?.value = darkTheme;

        return null;
      },
      [darkTheme],
    );

    return SettingPageWithAnimationWidget(
      title: l18n.profile_themeTitle,
      headerImage: RiveAnimationBlock(
        name: "theme",
        artboardName: "Theme",
        onStateMachineController: (StateMachineController controller) {
          final boolInput = controller.getBoolInput("DarkTheme");

          boolInput!.value = darkTheme;
          smiToggle.value = boolInput;
        },
      ),
      description: l18n.profile_themeDescription,
      children: [
        SettingsCardWidget(
          isSwitchListTile: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              GroupSettingCardSelectorWidget(
                icon: Icons.brightness_5,
                title: l18n.profile_themeLight,
                groupValue: preferences.theme,
                value: ThemeMode.light,
                onChanged: onValueChanged,
              ),
              GroupSettingCardSelectorWidget(
                icon: Icons.brightness_auto,
                title: l18n.profile_themeSystem,
                groupValue: preferences.theme,
                value: ThemeMode.system,
                onChanged: onValueChanged,
              ),
              GroupSettingCardSelectorWidget(
                icon: Icons.brightness_2,
                title: l18n.profile_themeDark,
                groupValue: preferences.theme,
                value: ThemeMode.dark,
                onChanged: onValueChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
