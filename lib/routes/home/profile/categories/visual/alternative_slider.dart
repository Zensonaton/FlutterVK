import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";

import "../../../../../provider/l18n.dart";
import "../../../../../provider/preferences.dart";
import "../../../../../widgets/setting_widgets.dart";

/// Route для настроек, отображающий параметры настройки "Альтернативный слайдер".
///
/// go_route: `/profile/setting_alternative_slider`.
class AlternativeSliderSettingPage extends HookConsumerWidget {
  const AlternativeSliderSettingPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);

    final smiToggle = useState<SMIBool?>(null);
    final isAlternativeSlider = preferences.alternateDesktopMiniplayerSlider;

    return SettingPageWithAnimationWidget(
      title: l18n.profile_alternateSliderTitle,
      headerImage: RiveAnimationBlock(
        name: "alternativeSlider",
        artboardName: "AlternativeSlider",
        onStateMachineController: (StateMachineController controller) {
          final boolInput = controller.getBoolInput("AlternativeSliderEnabled");

          boolInput!.value = isAlternativeSlider;
          smiToggle.value = boolInput;
        },
      ),
      description: l18n.profile_alternateSliderDescription,
      children: [
        SettingsCardWidget(
          child: SwitchListTile.adaptive(
            title: Text(
              l18n.profile_alternateSliderEnable,
            ),
            value: isAlternativeSlider,
            onChanged: (bool? value) {
              HapticFeedback.lightImpact();
              if (value == null) return;

              prefsNotifier.setAlternateDesktopMiniplayerSlider(value);
              smiToggle.value?.value = value;
            },
          ),
        ),
      ],
    );
  }
}
