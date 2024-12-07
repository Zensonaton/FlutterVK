import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../../enums.dart";
import "../../../../main.dart";
import "../../../../provider/l18n.dart";
import "../../../../provider/preferences.dart";
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
      title: l18n.profile_closeActionTitle,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_closeActionClose,
          ),
          value: CloseBehavior.close,
          groupValue: preferences.closeBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_closeActionMinimize,
          ),
          value: CloseBehavior.minimize,
          groupValue: preferences.closeBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_closeActionMinimizeIfPlaying,
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
      title: l18n.profile_rewindOnPreviousTitle,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_rewindOnPreviousAlways,
          ),
          value: RewindBehavior.always,
          groupValue: preferences.rewindOnPreviousBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_rewindOnPreviousOnlyViaUI,
          ),
          value: RewindBehavior.onlyViaUI,
          groupValue: preferences.rewindOnPreviousBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_rewindOnPreviousOnlyViaNotification,
          ),
          value: RewindBehavior.onlyViaNotification,
          groupValue: preferences.rewindOnPreviousBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_rewindOnPreviousDisabled,
          ),
          value: RewindBehavior.disabled,
          groupValue: preferences.rewindOnPreviousBehavior,
          onChanged: onValueChanged,
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

    return ProfileSettingCategory(
      icon: Icons.music_note,
      title: l18n.profile_musicPlayerTitle,
      centerTitle: mobileLayout,
      padding: EdgeInsets.only(
        top: mobileLayout ? 0 : 8,
      ),
      children: [
        // Действие при закрытии (OS Windows).
        if (isDesktop)
          SettingWithDialog(
            icon: Icons.close,
            title: l18n.profile_closeActionTitle,
            subtitle: l18n.profile_closeActionDescription,
            dialog: const CloseActionDialog(),
            settingText: {
              CloseBehavior.close: l18n.profile_closeActionClose,
              CloseBehavior.minimize: l18n.profile_closeActionMinimize,
              CloseBehavior.minimizeIfPlaying:
                  l18n.profile_closeActionMinimizeIfPlaying,
            }[preferences.closeBehavior]!,
          ),

        // Воспроизведение после закрытия приложения (OS Android).
        if (isMobile)
          SwitchListTile(
            secondary: const Icon(
              Icons.exit_to_app,
            ),
            title: Text(
              l18n.profile_androidKeepPlayingOnCloseTitle,
            ),
            subtitle: Text(
              l18n.profile_androidKeepPlayingOnCloseDescription,
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
            l18n.profile_shuffleOnPlayTitle,
          ),
          subtitle: Text(
            l18n.profile_shuffleOnPlayDescription,
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
            l18n.profile_stopOnLongPauseTitle,
          ),
          subtitle: Text(
            l18n.profile_stopOnLongPauseDescription,
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
          title: l18n.profile_rewindOnPreviousTitle,
          subtitle: l18n.profile_rewindOnPreviousDescription,
          dialog: const RewindOnPreviousDialog(),
          settingText: {
            RewindBehavior.always: l18n.profile_rewindOnPreviousAlways,
            RewindBehavior.onlyViaUI: l18n.profile_rewindOnPreviousOnlyViaUI,
            RewindBehavior.onlyViaNotification:
                l18n.profile_rewindOnPreviousOnlyViaNotification,
            RewindBehavior.disabled: l18n.profile_rewindOnPreviousDisabled,
          }[preferences.rewindOnPreviousBehavior]!,
        ),

        // Предупреждение создание дубликата при сохранении.
        SwitchListTile(
          secondary: const Icon(
            Icons.copy_all,
          ),
          title: Text(
            l18n.profile_checkBeforeFavoriteTitle,
          ),
          subtitle: Text(
            l18n.profile_checkBeforeFavoriteDescription,
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
              l18n.profile_discordRPCTitle,
            ),
            subtitle: Text(
              l18n.profile_discordRPCDescription,
            ),
            value: player.discordRPCEnabled,
            onChanged: (bool? enabled) async {
              HapticFeedback.lightImpact();
              if (enabled == null) return;

              prefsNotifier.setDiscordRPCEnabled(enabled);
              await player.setDiscordRPCEnabled(enabled);
            },
          ),

        // Debug-логирование плеера.
        if (isDesktop)
          SwitchListTile(
            secondary: const Icon(
              Icons.bug_report,
            ),
            title: Text(
              l18n.profile_playerDebugLoggingTitle,
            ),
            subtitle: Text(
              l18n.profile_playerDebugLoggingDescription,
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
                      l18n.general_restartApp,
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
