import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";

import "../../../../provider/auth.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/preferences.dart";
import "../../../../widgets/setting_widgets.dart";

/// Route для настроек, отображающий параметры настройки "Кроссфейд цветов плеера".
///
/// go_route: `/profile/setting_crossfade_audio_colors`.
class CrossfadeAudioColorsSettingPage extends HookConsumerWidget {
  const CrossfadeAudioColorsSettingPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);

    final recommendationsConnected = ref.watch(secondaryTokenProvider) != null;

    final smiToggle = useState<SMIBool?>(null);
    final isCrossfadeEnabled = preferences.crossfadeColors;

    return SettingPageWithAnimationWidget(
      title: l18n.crossfade_audio_colors,
      description: l18n.crossfade_audio_colors_desc,
      warning: !recommendationsConnected
          ? l18n.option_unavailable_without_recommendations
          : null,
      headerImage: RiveAnimationBlock(
        name: "crossfadeAudioColors",
        artboardName: "CrossfadeAudioColors",
        onStateMachineController: (StateMachineController controller) {
          final boolInput =
              controller.getBoolInput("CrossfadeAudioColorsEnabled");

          boolInput!.value = isCrossfadeEnabled;
          smiToggle.value = boolInput;
        },
      ),
      children: [
        SettingsCardWidget(
          child: SwitchListTile.adaptive(
            title: Text(
              l18n.enable_crossfade_audio_colors,
            ),
            value: isCrossfadeEnabled,
            onChanged: recommendationsConnected
                ? (bool? value) {
                    HapticFeedback.lightImpact();
                    if (value == null) return;

                    prefsNotifier.setCrossfadeColors(value);
                    smiToggle.value?.value = value;
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
