import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../enums.dart";
import "../../../provider/auth.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player.dart";
import "../../../provider/preferences.dart";
import "../../../utils.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/profile_category.dart";
import "../../profile.dart";

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

/// Раздел настроек для страницы профиля ([ProfileRoute]), отвечающий за экспериментальные настройки.
class ProfileExperimentalSettingsCategory extends ConsumerWidget {
  const ProfileExperimentalSettingsCategory({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);

    final mobileLayout = isMobileLayout(context);

    final preferences = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    final recommendationsConnected = ref.watch(secondaryTokenProvider) != null;

    return ProfileSettingCategory(
      icon: Icons.science,
      title: l18n.experimental_options,
      centerTitle: mobileLayout,
      padding: EdgeInsets.only(
        top: mobileLayout ? 0 : 8,
      ),
      children: [
        // Загрузка отсутсвующих обложек из Deezer.
        SwitchListTile(
          secondary: const Icon(
            Icons.image_search,
          ),
          title: Text(
            l18n.deezer_thumbnails,
          ),
          subtitle: Text(
            l18n.deezer_thumbnails_desc,
          ),
          value: preferences.deezerThumbnails,
          onChanged: recommendationsConnected
              ? (bool? enabled) async {
                  if (!demoModeDialog(ref, context)) return;

                  HapticFeedback.lightImpact();
                  if (enabled == null) return;

                  prefsNotifier.setDeezerThumbnails(enabled);
                }
              : null,
        ),

        // Тексты песен через LRCLIB.
        SwitchListTile(
          secondary: const Icon(
            Icons.lyrics_outlined,
          ),
          title: Text(
            l18n.lrclib_lyrics,
          ),
          subtitle: Text(
            l18n.lrclib_lyrics_desc,
          ),
          value: preferences.lrcLibEnabled,
          onChanged: (bool? enabled) async {
            if (!demoModeDialog(ref, context)) return;

            HapticFeedback.lightImpact();
            if (enabled == null) return;

            prefsNotifier.setLRCLIBEnabled(enabled);
          },
        ),

        // Анимированные обложки Apple Music.
        SwitchListTile(
          secondary: const Icon(
            Icons.slow_motion_video,
          ),
          title: Text(
            l18n.apple_music_animated_covers,
          ),
          subtitle: Text(
            l18n.apple_music_animated_covers_desc,
          ),
          value: preferences.appleMusicAnimatedCovers,
          onChanged: recommendationsConnected
              ? (bool? enabled) async {
                  if (!demoModeDialog(ref, context)) return;

                  HapticFeedback.lightImpact();
                  if (enabled == null) return;

                  prefsNotifier.setAppleMusicAnimatedCovers(enabled);
                }
              : null,
        ),

        // Временно выключенные функции: нормализация, устранение тишины.
        //
        // Они выключены, поскольку media_kit использует урезанные бинарники ffmpeg/libmpv.
        // Ввиду этого, ни одна из этих фич не работает: запуск воспроизведения вызывает ошибки плеера.
        // Не желая терять написанный код, я решил на время вырубить эти две функции пока не будет исправлено:
        // https://github.com/media-kit/media-kit/issues/1126
        //
        // ignore: dead_code
        if (false) ...[
          // Нормализация громкости.
          if (!isWeb)
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
          if (!isWeb)
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
      ],
    );
  }
}
