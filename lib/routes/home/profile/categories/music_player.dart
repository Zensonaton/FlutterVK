import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:share_plus/share_plus.dart";

import "../../../../enums.dart";
import "../../../../main.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/playlists.dart";
import "../../../../provider/preferences.dart";
import "../../../../provider/user.dart";
import "../../../../utils.dart";
import "../../../../widgets/dialogs.dart";
import "../../../../widgets/profile_category.dart";
import "../../profile.dart";

/// Диалог, помогающий пользователю поменять настройку "Поведение при закрытии".
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const CloseActionDialog()
/// );
/// ```
class CloseActionDialog extends ConsumerWidget {
  const CloseActionDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDesktop) {
      throw Exception("CloseActionDialog can only be called on desktop");
    }

    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);

    void onValueChanged(CloseBehavior? behavior) {
      HapticFeedback.lightImpact();
      if (behavior == null) return;

      prefsNotifier.setCloseBehavior(behavior);
    }

    return MaterialDialog(
      icon: Icons.close,
      title: l18n.close_action,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.close_action_close,
          ),
          value: CloseBehavior.close,
          groupValue: preferences.closeBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.close_action_minimize,
          ),
          value: CloseBehavior.minimize,
          groupValue: preferences.closeBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.close_action_minimize_if_playing,
          ),
          value: CloseBehavior.minimizeIfPlaying,
          groupValue: preferences.closeBehavior,
          onChanged: onValueChanged,
        ),
      ],
    );
  }
}

/// Диалог, помогающий пользователю поменять настройку "Перемотка при запуска предыдущего трека".
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const RewindOnPreviousDialog()
/// );
/// ```
class RewindOnPreviousDialog extends ConsumerWidget {
  const RewindOnPreviousDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);

    void onValueChanged(RewindBehavior? behavior) {
      HapticFeedback.lightImpact();
      if (behavior == null) return;

      prefsNotifier.setRewindOnPreviousBehavior(behavior);
    }

    return MaterialDialog(
      icon: Icons.replay,
      title: l18n.rewind_on_previous,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.rewind_on_previous_always,
          ),
          value: RewindBehavior.always,
          groupValue: preferences.rewindOnPreviousBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.rewind_on_previous_only_via_ui,
          ),
          value: RewindBehavior.onlyViaUI,
          groupValue: preferences.rewindOnPreviousBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.rewind_on_previous_only_via_notification,
          ),
          value: RewindBehavior.onlyViaNotification,
          groupValue: preferences.rewindOnPreviousBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.rewind_on_previous_only_via_disabled,
          ),
          value: RewindBehavior.disabled,
          groupValue: preferences.rewindOnPreviousBehavior,
          onChanged: onValueChanged,
        ),
      ],
    );
  }
}

/// Диалог, отображающий пользователю информацию об экспортированном списке треков.
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const ExportTracksListDialog()
/// );
/// ```
class ExportTracksListDialog extends ConsumerWidget {
  const ExportTracksListDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final playlist = ref.watch(favoritesPlaylistProvider);
    if (playlist?.audios == null) {
      throw Exception("Expected tracks list to be loaded");
    }

    final String exportContents = playlist!.audios!
        .map((ExtendedAudio audio) => "${audio.artist} • ${audio.title}")
        .join("\n\n");

    return MaterialDialog(
      icon: Icons.my_library_music,
      title: l18n.export_music_list,
      text: l18n.export_music_list_desc(
        count: playlist.count!,
      ),
      contents: [
        SelectableText(
          exportContents,
        ),
      ],
      actions: [
        // Закрыть.
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l18n.general_close,
          ),
        ),

        // Поделиться.
        FilledButton.icon(
          onPressed: () => Share.share(exportContents),
          icon: const Icon(
            Icons.share,
          ),
          label: Text(
            l18n.general_share,
          ),
        ),
      ],
    );
  }
}

/// Раздел настроек для страницы профиля ([HomeProfilePage]), отвечающий за настройки музыкального плеера.
class ProfileMusicPlayerSettingsCategory extends ConsumerWidget {
  const ProfileMusicPlayerSettingsCategory({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final mobileLayout = isMobileLayout(context);

    final preferences = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    void onAudiosListExportTap() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const ExportTracksListDialog();
        },
      );
    }

    return ProfileSettingCategory(
      icon: Icons.music_note,
      title: l18n.music_player,
      centerTitle: mobileLayout,
      padding: EdgeInsets.only(
        top: mobileLayout ? 0 : 8,
      ),
      children: [
        // Действие при закрытии (OS Windows).
        if (isDesktop)
          SettingWithDialog(
            icon: Icons.close,
            title: l18n.close_action,
            subtitle: l18n.close_action_desc,
            dialog: const CloseActionDialog(),
            settingText: {
              CloseBehavior.close: l18n.close_action_close,
              CloseBehavior.minimize: l18n.close_action_minimize,
              CloseBehavior.minimizeIfPlaying:
                  l18n.close_action_minimize_if_playing,
            }[preferences.closeBehavior]!,
          ),

        // Воспроизведение после закрытия приложения (OS Android).
        if (isMobile)
          SwitchListTile(
            secondary: const Icon(
              Icons.exit_to_app,
            ),
            title: Text(
              l18n.android_keep_playing_on_close,
            ),
            subtitle: Text(
              l18n.android_keep_playing_on_close_desc,
            ),
            value: preferences.androidKeepPlayingOnClose,
            onChanged: (bool? enabled) async {
              HapticFeedback.lightImpact();
              if (enabled == null) return;

              prefsNotifier.setAndroidKeepPlayingOnClose(enabled);
            },
          ),

        // Перемешка при воспроизведении.
        SwitchListTile(
          secondary: const Icon(
            Icons.shuffle,
          ),
          title: Text(
            l18n.shuffle_on_play,
          ),
          subtitle: Text(
            l18n.shuffle_on_play_desc,
          ),
          value: preferences.shuffleOnPlay,
          onChanged: (bool? enabled) async {
            HapticFeedback.lightImpact();
            if (enabled == null) return;

            prefsNotifier.setShuffleOnPlay(enabled);
          },
        ),

        // Пауза воспроизведения при минимальной громкости (OS Windows).
        if (isDesktop)
          SwitchListTile(
            secondary: const Icon(
              Icons.volume_off,
            ),
            title: Text(
              l18n.profile_pauseOnMuteTitle,
            ),
            subtitle: Text(
              l18n.profile_pauseOnMuteDescription,
            ),
            value: preferences.pauseOnMuteEnabled,
            onChanged: (bool? enabled) async {
              HapticFeedback.lightImpact();
              if (enabled == null) return;

              prefsNotifier.setPauseOnMuteEnabled(enabled);
              await player.setPauseOnMuteEnabled(enabled);
            },
          ),

        // Остановка плеера при неактивности.
        SwitchListTile(
          secondary: const Icon(
            Icons.timer,
          ),
          title: Text(
            l18n.stop_on_long_pause,
          ),
          subtitle: Text(
            l18n.stop_on_long_pause_desc,
          ),
          value: preferences.stopOnPauseEnabled,
          onChanged: (bool? enabled) async {
            HapticFeedback.lightImpact();
            if (enabled == null) return;

            prefsNotifier.setStopOnPauseEnabled(enabled);
            player.setStopOnPauseEnabled(enabled);
          },
        ),

        // Перемотка при нажатии на предыдущий трек.
        SettingWithDialog(
          icon: Icons.replay_outlined,
          title: l18n.rewind_on_previous,
          subtitle: l18n.rewind_on_previous_desc,
          dialog: const RewindOnPreviousDialog(),
          settingText: {
            RewindBehavior.always: l18n.rewind_on_previous_always,
            RewindBehavior.onlyViaUI: l18n.rewind_on_previous_only_via_ui,
            RewindBehavior.onlyViaNotification:
                l18n.rewind_on_previous_only_via_notification,
            RewindBehavior.disabled: l18n.rewind_on_previous_only_via_disabled,
          }[preferences.rewindOnPreviousBehavior]!,
        ),

        // Предупреждение создание дубликата при сохранении.
        SwitchListTile(
          secondary: const Icon(
            Icons.copy_all,
          ),
          title: Text(
            l18n.check_for_duplicates,
          ),
          subtitle: Text(
            l18n.check_for_duplicates_desc,
          ),
          value: preferences.checkBeforeFavorite,
          onChanged: (bool? enabled) async {
            HapticFeedback.lightImpact();
            if (enabled == null) return;

            prefsNotifier.setCheckBeforeFavorite(enabled);
          },
        ),

        // Discord Rich Presence.
        if (isDesktop)
          SwitchListTile(
            secondary: const Icon(
              Icons.discord,
            ),
            title: Text(
              l18n.discord_rpc,
            ),
            subtitle: Text(
              l18n.discord_rpc_desc,
            ),
            value: player.discordRPCEnabled,
            onChanged: (bool? enabled) async {
              HapticFeedback.lightImpact();
              if (enabled == null) return;

              prefsNotifier.setDiscordRPCEnabled(enabled);
              await player.setDiscordRPCEnabled(enabled);
            },
          ),

        // Экспорт списка треков.
        ListTile(
          leading: const Icon(
            Icons.my_library_music,
          ),
          title: Text(
            l18n.export_music_list,
          ),
          onTap: onAudiosListExportTap,
        ),

        // Debug-логирование плеера.
        if (isDesktop)
          SwitchListTile(
            secondary: const Icon(
              Icons.bug_report,
            ),
            title: Text(
              l18n.player_debug_logging,
            ),
            subtitle: Text(
              l18n.player_debug_logging_desc,
            ),
            value: preferences.debugPlayerLogging,
            onChanged: (bool? enabled) async {
              HapticFeedback.lightImpact();
              if (enabled == null) return;

              prefsNotifier.setDebugPlayerLogging(enabled);

              // Отображаем уведомление о необходимости в перезагрузки приложения.
              final messenger = ScaffoldMessenger.of(context);
              if (enabled) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      l18n.app_restart_required,
                    ),
                  ),
                );
              } else {
                messenger.hideCurrentSnackBar();
              }
            },
          ),
      ],
    );
  }
}
