import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../provider/auth.dart";
import "../../../provider/l18n.dart";
import "../../../provider/preferences.dart";
import "../../../utils.dart";
import "../../../widgets/profile_category.dart";
import "../../profile.dart";

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
      title: l18n.visual_settings,
      centerTitle: mobileLayout,
      padding: EdgeInsets.only(
        top: mobileLayout ? 0 : 8,
      ),
      children: [
        // Тема.
        ListTile(
          leading: const Icon(
            Icons.color_lens,
          ),
          title: Text(
            l18n.app_theme,
          ),
          onTap: () => context.push(
            "/profile/setting_theme_mode",
          ),
        ),

        // OLED-тема.
        ListTile(
          leading: const Icon(
            Icons.mode_night,
          ),
          title: Text(
            l18n.oled_theme,
          ),
          onTap: () => context.push(
            "/profile/setting_oled",
          ),
        ),

        // Использование цветов плеера по всему приложению.
        ListTile(
          leading: const Icon(
            Icons.color_lens,
          ),
          title: Text(
            l18n.use_player_colors_appwide,
          ),
          onTap: () => context.push(
            "/profile/setting_app_wide_colors",
          ),
        ),

        // Тип палитры цветов обложки.
        ListTile(
          leading: const Icon(
            Icons.auto_fix_high,
          ),
          title: Text(
            l18n.player_dynamic_color_scheme_type,
          ),
          onTap: () => context.push(
            "/profile/setting_dynamic_scheme_type",
          ),
        ),

        // Альтернативный слайдер воспроизведения.
        if (!mobileLayout)
          ListTile(
            leading: const Icon(
              Icons.swap_horiz,
            ),
            title: Text(
              l18n.alternate_slider,
            ),
            onTap: () => context.push(
              "/profile/setting_alternative_slider",
            ),
          ),

        // Использование изображения трека для фона в полноэкранном плеере.
        SwitchListTile(
          secondary: const Icon(
            Icons.photo_filter,
          ),
          title: Text(
            l18n.use_track_thumb_as_player_background,
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
          ListTile(
            leading: const Icon(
              Icons.queue_music,
            ),
            title: Text(
              l18n.spoiler_next_audio,
            ),
            onTap: () => context.push(
              "/profile/setting_spoiler_next_audio",
            ),
          ),

        // Кроссфейд цветов плеера.
        ListTile(
          leading: const Icon(
            Icons.colorize,
          ),
          title: Text(
            l18n.crossfade_audio_colors,
          ),
          onTap: () => context.push(
            "/profile/setting_crossfade_audio_colors",
          ),
        ),

        // Отображение обложек.
        ListTile(
          leading: const Icon(
            Icons.image,
          ),
          title: Text(
            l18n.show_audio_thumbs,
          ),
          onTap: () => context.push(
            "/profile/setting_show_audio_thumbs",
          ),
        ),
      ],
    );
  }
}
