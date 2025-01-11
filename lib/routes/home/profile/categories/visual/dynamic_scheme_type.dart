import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";

import "../../../../../enums.dart";
import "../../../../../main.dart";
import "../../../../../provider/l18n.dart";
import "../../../../../provider/preferences.dart";
import "../../../../../widgets/setting_widgets.dart";

/// Route для настроек, отображающий параметры настройки "Тип палитры цветов обложки".
///
/// go_route: `/profile/setting_dynamic_scheme_type`.
class DynamicSchemeTypeSettingPage extends HookConsumerWidget {
  const DynamicSchemeTypeSettingPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);

    final smiNumber = useState<SMINumber?>(null);
    final smiTrigger = useState<SMITrigger?>(null);
    final dynamicSchemeType = preferences.dynamicSchemeType;

    void onValueChanged(DynamicSchemeType? dynamicScheme) {
      HapticFeedback.lightImpact();
      if (dynamicScheme == null) return;

      prefsNotifier.setDynamicSchemeType(dynamicScheme);
      smiNumber.value?.value = dynamicScheme.index.toDouble();
      smiTrigger.value?.fire();
    }

    return SettingPageWithAnimationWidget(
      title: l18n.profile_playerDynamicColorSchemeTypeTitle,
      headerImage: RiveAnimationBlock(
        name: "dynamicSchemeType",
        artboardName: "DynamicSchemeType",
        onStateMachineController: (StateMachineController controller) {
          final numberInput = controller.getNumberInput("Type");
          final trigger = controller.getTriggerInput("OnToggle");

          numberInput!.value = dynamicSchemeType.index.toDouble();
          smiNumber.value = numberInput;
          smiTrigger.value = trigger;
        },
      ),
      description: l18n.profile_playerDynamicColorSchemeTypeDescription,
      warning:
          !player.loaded ? l18n.general_optionNotAvailableWithoutAudio : null,
      children: [
        SettingsCardWidget(
          isSwitchListTile: false,
          child: Column(
            children: [
              RadioListTile.adaptive(
                title: Text(
                  l18n.profile_playerDynamicColorSchemeTonalSpot,
                ),
                value: DynamicSchemeType.tonalSpot,
                groupValue: preferences.dynamicSchemeType,
                onChanged: onValueChanged,
              ),
              RadioListTile.adaptive(
                title: Text(
                  l18n.profile_playerDynamicColorSchemeNeutral,
                ),
                value: DynamicSchemeType.neutral,
                groupValue: preferences.dynamicSchemeType,
                onChanged: onValueChanged,
              ),
              RadioListTile.adaptive(
                title: Text(
                  l18n.profile_playerDynamicColorSchemeContent,
                ),
                value: DynamicSchemeType.content,
                groupValue: preferences.dynamicSchemeType,
                onChanged: onValueChanged,
              ),
              RadioListTile.adaptive(
                title: Text(
                  l18n.profile_playerDynamicColorSchemeMonochrome,
                ),
                value: DynamicSchemeType.monochrome,
                groupValue: preferences.dynamicSchemeType,
                onChanged: onValueChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
