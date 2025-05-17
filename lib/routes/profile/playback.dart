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
    final player = ref.read(playerProvider);

    void onValueChanged(RewindBehavior? behavior) {
      HapticFeedback.lightImpact();
      if (behavior == null) return;

      prefsNotifier.setRewindOnPreviousBehavior(behavior);
      player.setRewindBehavior(behavior);
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

/// Route для управления настройками воспроизведения.
/// Пользователь может попасть в этот раздел через [ProfileRoute], нажав на "Воспроизведение".
///
/// go_route: `/profile/settings/playback`
class SettingsPlaybackRoute extends ConsumerWidget {
  const SettingsPlaybackRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    ref.watch(playerIsLoadedProvider);

    final mobileLayout = isMobileLayout(context);

    final preferences = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l18n.playback,
        ),
      ),
      body: ListView(
        children: [
          // Название трека в заголовке окна (Desktop).
          if (isDesktop || kDebugMode)
            SwitchListTile(
              secondary: const Icon(
                Icons.web_asset,
              ),
              title: Text(
                l18n.track_title_in_window_bar,
              ),
              value: preferences.trackTitleInWindowBar,
              onChanged: (bool? enabled) async {
                HapticFeedback.lightImpact();
                if (enabled == null) return;

                prefsNotifier.setTrackTitleInWindowBar(enabled);
                player.setTrackTitleInWindowBarEnabled(enabled);
              },
            ),

          // Действие при закрытии (Desktop).
          if (isDesktop || kDebugMode)
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

          // Воспроизведение после закрытия приложения (Mobile).
          if (isMobile || kDebugMode)
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
                player.setKeepPlayingOnCloseEnabled(enabled);
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
          if (isDesktop || kDebugMode)
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
                player.setPauseOnMuteEnabled(enabled);
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
              player.setStopOnLongPauseEnabled(enabled);
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
              RewindBehavior.disabled:
                  l18n.rewind_on_previous_only_via_disabled,
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
              if (!demoModeDialog(ref, context)) return;

              HapticFeedback.lightImpact();
              if (enabled == null) return;

              prefsNotifier.setCheckBeforeFavorite(enabled);
            },
          ),

          // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
          if (player.isLoaded && mobileLayout)
            const Gap(MusicPlayerWidget.mobileHeightWithPadding),
        ],
      ),
    );
  }
}
