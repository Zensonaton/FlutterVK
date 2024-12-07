import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../../enums.dart";
import "../../../../provider/auth.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/preferences.dart";
import "../../../../provider/user.dart";
import "../../../../services/image_to_color_scheme.dart";
import "../../../../utils.dart";
import "../../../../widgets/audio_track.dart";
import "../../../../widgets/dialogs.dart";
import "../../../../widgets/profile_category.dart";
import "../../profile.dart";

/// Диалог, помогающий пользователю поменять настройку "Тема".
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const ThemeActionDialog()
/// );
/// ```
class ThemeActionDialog extends ConsumerWidget {
  const ThemeActionDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);

    void onValueChanged(ThemeMode? mode) {
      HapticFeedback.lightImpact();
      if (mode == null) return;

      prefsNotifier.setTheme(mode);
    }

    return MaterialDialog(
      icon: Icons.dark_mode,
      title: l18n.profile_themeTitle,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_themeSystem,
          ),
          value: ThemeMode.system,
          groupValue: preferences.theme,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_themeLight,
          ),
          value: ThemeMode.light,
          groupValue: preferences.theme,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_themeDark,
          ),
          value: ThemeMode.dark,
          groupValue: preferences.theme,
          onChanged: onValueChanged,
        ),
      ],
    );
  }
}

/// Диалог, помогающий пользователю поменять настройку "Тип палитры цветов обложки".
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const ThemeActionDialog()
/// );
/// ```
class PlayerDynamicSchemeDialog extends ConsumerWidget {
  const PlayerDynamicSchemeDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);

    final List<List<dynamic>> tracks = [
      [
        "Bandito",
        "twenty one pilots",
        "https://e-cdn-images.dzcdn.net/images/cover/765dc8aba0e893fc6d55af08572fc902/50x50-000000-80-0-0.jpg",
        const Color(0xff171905),
      ],
      [
        "4AM",
        "KID BRUNSWICK",
        "https://e-cdn-images.dzcdn.net/images/cover/cda9a566de9202b6d4b7fad2c60d5f16/50x50-000000-80-0-0.jpg",
        const Color(0xff18a571),
      ],
      [
        "Routines In The Night",
        "twenty one pilots",
        "https://e-cdn-images.dzcdn.net/images/cover/4f2819429ed92d35a649d609e39b29b5/50x50-000000-80-0-0.jpg",
        const Color(0xffe33a38),
      ],
    ];

    List<Widget> buildTrackWidgets() {
      final List<Widget> widgets = [];

      for (final List<dynamic> track in tracks) {
        final String title = track[0];
        final String artist = track[1];
        final String url = track[2];
        final Color baseColor = track[3];
        final ColorScheme scheme = ImageSchemeExtractor.buildColorScheme(
          baseColor,
          Theme.of(context).brightness,
          {
            DynamicSchemeType.tonalSpot: DynamicSchemeVariant.tonalSpot,
            DynamicSchemeType.neutral: DynamicSchemeVariant.neutral,
            DynamicSchemeType.content: DynamicSchemeVariant.content,
            DynamicSchemeType.monochrome: DynamicSchemeVariant.monochrome,
          }[preferences.dynamicSchemeType]!,
        );

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Сам трек.
                SizedBox(
                  width: 220,
                  child: AudioTrackTile(
                    audio: ExtendedAudio(
                      title: title,
                      artist: artist,
                      id: 0,
                      ownerID: 0,
                      duration: 0,
                      accessKey: "",
                      date: 0,
                      deezerThumbs: ExtendedThumbnails(
                        photoBig: url,
                        photoMax: url,
                        photoMedium: url,
                        photoSmall: url,
                      ),
                    ),
                    showDuration: false,
                    allowImageCache: false,
                  ),
                ),

                // Цвет.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      color: scheme.primary,
                      width: 50,
                      height: 50,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return widgets;
    }

    void onValueChanged(DynamicSchemeType? dynamicScheme) {
      HapticFeedback.lightImpact();
      if (dynamicScheme == null) return;

      prefsNotifier.setDynamicSchemeType(dynamicScheme);
    }

    return MaterialDialog(
      icon: Icons.auto_fix_high,
      title: l18n.profile_playerDynamicColorSchemeTypeTitle,
      contents: [
        // Переключатели.
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
        const Gap(16),

        // Фейковые треки для отображения тем.
        ...buildTrackWidgets(),
      ],
    );
  }
}

/// Раздел настроек для страницы профиля ([HomeProfilePage]), отвечающий за визуальные настройки.
class ProfileVisualSettingsCategory extends ConsumerWidget {
  const ProfileVisualSettingsCategory({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final mobileLayout = isMobileLayout(context);

    final preferences = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    final recommendationsConnected = ref.watch(secondaryTokenProvider) != null;

    return ProfileSettingCategory(
      icon: Icons.color_lens,
      title: l18n.profile_visualTitle,
      centerTitle: mobileLayout,
      padding: EdgeInsets.only(
        top: mobileLayout ? 0 : 8,
      ),
      children: [
        // Тема приложения.
        SettingWithDialog(
          icon: Icons.dark_mode,
          title: l18n.profile_themeTitle,
          dialog: const ThemeActionDialog(),
          settingText: {
            ThemeMode.system: l18n.profile_themeSystem,
            ThemeMode.light: l18n.profile_themeLight,
            ThemeMode.dark: l18n.profile_themeDark,
          }[preferences.theme]!,
        ),

        // OLED тема.
        SwitchListTile(
          secondary: const Icon(
            Icons.mode_night,
          ),
          title: Text(
            l18n.profile_oledThemeTitle,
          ),
          subtitle: Text(
            l18n.profile_oledThemeDescription,
          ),
          value: preferences.oledTheme,
          onChanged: Theme.of(context).brightness == Brightness.dark
              ? (bool? enabled) async {
                  HapticFeedback.lightImpact();
                  if (enabled == null) return;

                  prefsNotifier.setOLEDThemeEnabled(enabled);
                }
              : null,
        ),

        // Использование цветов плеера по всему приложению.
        SwitchListTile(
          secondary: const Icon(
            Icons.color_lens,
          ),
          title: Text(
            l18n.profile_usePlayerColorsAppWideTitle,
          ),
          value: preferences.playerColorsAppWide,
          onChanged: recommendationsConnected
              ? (bool? enabled) async {
                  HapticFeedback.lightImpact();
                  if (enabled == null) return;

                  prefsNotifier.setPlayerColorsAppWide(enabled);
                }
              : null,
        ),

        // Тип палитры цветов обложки.
        SettingWithDialog(
          icon: Icons.auto_fix_high,
          title: l18n.profile_playerDynamicColorSchemeTypeTitle,
          subtitle: l18n.profile_playerDynamicColorSchemeTypeDescription,
          dialog: const PlayerDynamicSchemeDialog(),
          enabled: recommendationsConnected,
          settingText: {
            DynamicSchemeType.tonalSpot:
                l18n.profile_playerDynamicColorSchemeTonalSpot,
            DynamicSchemeType.neutral:
                l18n.profile_playerDynamicColorSchemeNeutral,
            DynamicSchemeType.content:
                l18n.profile_playerDynamicColorSchemeContent,
            DynamicSchemeType.monochrome:
                l18n.profile_playerDynamicColorSchemeMonochrome,
          }[preferences.dynamicSchemeType]!,
        ),

        // Альтернативный слайдер воспроизведения.
        if (!mobileLayout)
          SwitchListTile(
            secondary: const Icon(
              Icons.swap_horiz,
            ),
            title: Text(
              l18n.profile_alternateSliderTitle,
            ),
            value: preferences.alternateDesktopMiniplayerSlider,
            onChanged: recommendationsConnected
                ? (bool? enabled) async {
                    HapticFeedback.lightImpact();
                    if (enabled == null) return;

                    prefsNotifier.setAlternateDesktopMiniplayerSlider(
                      enabled,
                    );
                  }
                : null,
          ),

        // Использование изображения трека для фона в полноэкранном плеере.
        SwitchListTile(
          secondary: const Icon(
            Icons.photo_filter,
          ),
          title: Text(
            l18n.profile_useThumbnailAsBackgroundTitle,
          ),
          value: preferences.playerThumbAsBackground,
          onChanged: recommendationsConnected
              ? (bool? enabled) async {
                  HapticFeedback.lightImpact();
                  if (enabled == null) return;

                  prefsNotifier.setPlayerThumbAsBackground(enabled);
                }
              : null,
        ),

        // Спойлер следующего трека перед окончанием текущего.
        if (!mobileLayout)
          SwitchListTile(
            secondary: const Icon(
              Icons.queue_music,
            ),
            title: Text(
              l18n.profile_spoilerNextAudioTitle,
            ),
            subtitle: Text(
              l18n.profile_spoilerNextAudioDescription,
            ),
            value: preferences.spoilerNextTrack,
            onChanged: (bool? enabled) async {
              HapticFeedback.lightImpact();
              if (enabled == null) return;

              prefsNotifier.setSpoilerNextTrackEnabled(enabled);
            },
          ),

        // Кроссфейд цветов плеера.
        SwitchListTile(
          secondary: const Icon(
            Icons.colorize,
          ),
          title: Text(
            l18n.profile_crossfadeAudioColorsTitle,
          ),
          subtitle: Text(
            l18n.profile_crossfadeAudioColorsDescription,
          ),
          value: preferences.crossfadeColors,
          onChanged: (bool? enabled) async {
            HapticFeedback.lightImpact();
            if (enabled == null) return;

            prefsNotifier.setCrossfadeColors(enabled);
          },
        ),
      ],
    );
  }
}
