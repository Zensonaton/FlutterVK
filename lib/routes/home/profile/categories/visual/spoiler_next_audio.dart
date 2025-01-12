import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";

import "../../../../../provider/l18n.dart";
import "../../../../../provider/preferences.dart";
import "../../../../../widgets/setting_widgets.dart";

/// Route для настроек, отображающий параметры настройки "Спойлер следующего трека".
///
/// go_route: `/profile/setting_spoiler_next_audio`.
class SpoilerNextAudioSettingPage extends HookConsumerWidget {
  const SpoilerNextAudioSettingPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);

    final smiToggle = useState<SMIBool?>(null);
    final spoilerNextAudio = preferences.spoilerNextTrack;

    return SettingPageWithAnimationWidget(
      title: l18n.profile_spoilerNextAudioTitle,
      description: l18n.profile_spoilerNextAudioDescription,
      headerImage: RiveAnimationBlock(
        name: "spoilerNextAudio",
        artboardName: "SpoilerNextAudio",
        onStateMachineController: (StateMachineController controller) {
          final boolInput = controller.getBoolInput("SpoilerNextAudioEnabled");

          boolInput!.value = spoilerNextAudio;
          smiToggle.value = boolInput;
        },
      ),
      children: [
        SettingsCardWidget(
          child: SwitchListTile.adaptive(
            title: Text(
              l18n.profile_spoilerNextAudioEnable,
            ),
            value: spoilerNextAudio,
            onChanged: (bool? value) {
              HapticFeedback.lightImpact();
              if (value == null) return;

              prefsNotifier.setSpoilerNextTrackEnabled(value);
              smiToggle.value?.value = value;
            },
          ),
        ),
      ],
    );
  }
}
