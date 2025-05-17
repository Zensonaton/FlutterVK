import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../enums.dart";
import "../../provider/l18n.dart";
import "../../provider/player.dart";
import "../../provider/preferences.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/dialogs.dart";
import "../profile.dart";

/// Диалог, помогающий пользователю поменять настройку "Нормализация громкости".
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const VolumeNormalizationDialog()
/// );
/// ```
class VolumeNormalizationDialog extends ConsumerWidget {
  const VolumeNormalizationDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isWeb) {
      throw UnsupportedError(
        "This dialog is not supported on the web platform.",
      );
    }

    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final player = ref.read(playerProvider);
    final l18n = ref.watch(l18nProvider);

    void onValueChanged(VolumeNormalization? normalization) {
      HapticFeedback.lightImpact();
      if (normalization == null) return;

      prefsNotifier.setVolumeNormalization(normalization);
      player.setVolumeNormalization(normalization);
    }

    return MaterialDialog(
      icon: Icons.graphic_eq,
      title: l18n.volume_normalization,
      text: l18n.volume_normalization_dialog_desc,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.volume_normalization_disabled,
          ),
          value: VolumeNormalization.disabled,
          groupValue: preferences.volumeNormalization,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.volume_normalization_quiet,
          ),
          value: VolumeNormalization.quiet,
          groupValue: preferences.volumeNormalization,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.volume_normalization_normal,
          ),
          value: VolumeNormalization.normal,
          groupValue: preferences.volumeNormalization,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.volume_normalization_loud,
          ),
          value: VolumeNormalization.loud,
          groupValue: preferences.volumeNormalization,
          onChanged: onValueChanged,
        ),
      ],
    );
  }
}

/// Route для управления экспериментальными настройками приложения.
/// Пользователь может попасть в этот раздел через [ProfileRoute], нажав на "Экспериментальные функции".
///
/// go_route: `/profile/settings/experimental`
class SettingsExperimentalRoute extends ConsumerWidget {
  const SettingsExperimentalRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);

    final preferences = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    final mobileLayout = isMobileLayout(context);

    // TODO: Предупреждение перед возможностью увидеть экспериментальные функции.

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.experimental_options,
        ),
      ),
      body: ListView(
        children: [
          Text(
            l18n.experimental_no_options_available,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorScheme.of(context).primary,
            ),
          ),

          // Временно выключенные функции: нормализация, устранение тишины.
          //
          // Они выключены, поскольку media_kit использует урезанные бинарники ffmpeg/libmpv.
          // Ввиду этого, ни одна из этих фич не работает: запуск воспроизведения вызывает ошибки плеера.
          // Не желая терять написанный код, я решил на время вырубить эти две функции пока не будет исправлено:
          // https://github.com/media-kit/media-kit/issues/1126
          //
          // ignore: dead_code
          if (false || kDebugMode) ...[
            // Нормализация громкости.
            if (!isWeb || kDebugMode)
              SettingWithDialog(
                icon: Icons.graphic_eq,
                title: l18n.volume_normalization,
                subtitle: l18n.volume_normalization_desc,
                dialog: const VolumeNormalizationDialog(),
                settingText: {
                  VolumeNormalization.disabled:
                      l18n.volume_normalization_disabled,
                  VolumeNormalization.quiet: l18n.volume_normalization_quiet,
                  VolumeNormalization.normal: l18n.volume_normalization_normal,
                  VolumeNormalization.loud: l18n.volume_normalization_loud,
                }[preferences.volumeNormalization]!,
              ),

            // Устранение тишины.
            if (!isWeb || kDebugMode)
              SwitchListTile(
                secondary: const Icon(
                  Icons.cut,
                ),
                title: Text(
                  l18n.silence_removal,
                ),
                subtitle: Text(
                  l18n.silence_removal_desc,
                ),
                value: preferences.silenceRemoval,
                onChanged: (bool? enabled) async {
                  HapticFeedback.lightImpact();
                  if (enabled == null) return;

                  prefsNotifier.setSilenceRemoval(enabled);
                  player.setSilenceRemovalEnabled(enabled);
                },
              ),
          ],

          // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
          if (player.isLoaded && mobileLayout)
            const Gap(MusicPlayerWidget.mobileHeightWithPadding),
        ],
      ),
    );
  }
}
