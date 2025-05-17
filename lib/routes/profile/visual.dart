import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../provider/l18n.dart";
import "../../provider/player.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";

/// Route для управления визуальными настройками приложения.
/// Пользователь может попасть в этот раздел через [ProfileRoute], нажав на "Стиль, внешний вид".
///
/// go_route: `/profile/settings/visual`
class SettingsVisualRoute extends ConsumerWidget {
  const SettingsVisualRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);

    final mobileLayout = isMobileLayout(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.visual_settings,
        ),
      ),
      body: ListView(
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

          // Цвета трека по всему приложению.
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
          if (!mobileLayout || kDebugMode)
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

          // Спойлер следующего трека.
          if (!mobileLayout || kDebugMode)
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

          // Настройки полнооконного плеера.
          ListTile(
            leading: const Icon(
              Icons.fullscreen,
            ),
            title: Text(
              l18n.fullscreen_player,
            ),
            subtitle: Text(
              l18n.fullscreen_player_desc,
            ),
            onTap: () => context.push(
              "/profile/settings/visual/player",
            ),
          ),

          // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
          if (player.isLoaded && mobileLayout)
            const Gap(MusicPlayerWidget.mobileHeightWithPadding),
        ],
      ),
    );
  }
}
