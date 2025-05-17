import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";

import "../../../provider/auth.dart";
import "../../../provider/l18n.dart";
import "../../../provider/preferences.dart";
import "../../../widgets/setting_widgets.dart";

/// Route для настроек, отображающий параметры настройки "Отображение обложек треков".
///
/// go_route: `/profile/setting_show_audio_thumbs`.
class ShowAudioThumbsSettingPage extends HookConsumerWidget {
  const ShowAudioThumbsSettingPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);

    final recommendationsConnected = ref.watch(secondaryTokenProvider) != null;

    final smiToggle = useState<SMIBool?>(null);
    final isShowingAudioThumbs = preferences.showTrackThumbnails;

    return SettingPageWithAnimationWidget(
      title: l18n.show_audio_thumbs,
      description: l18n.show_audio_thumbs_desc,
      warning: !recommendationsConnected
          ? l18n.thumbnails_unavailable_without_recommendations
          : null,
      headerImage: RiveAnimationBlock(
        name: "showAudioThumbs",
        artboardName: "ShowAudioThumbs",
        onStateMachineController: (StateMachineController controller) {
          final boolInput = controller.getBoolInput("ShowAudioThumbsEnabled");

          boolInput!.value = isShowingAudioThumbs;
          smiToggle.value = boolInput;
        },
      ),
      children: [
        SettingsCardWidget(
          child: SwitchListTile.adaptive(
            title: Text(
              l18n.enable_show_audio_thumbs,
            ),
            value: isShowingAudioThumbs,
            onChanged: (bool? value) {
              HapticFeedback.lightImpact();
              if (value == null) return;

              prefsNotifier.setShowTrackThumbnails(value);
              smiToggle.value?.value = value;
            },
          ),
        ),
      ],
    );
  }
}
