import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../enums.dart";
import "../../../provider/auth.dart";
import "../../../provider/l18n.dart";
import "../../../provider/preferences.dart";
import "../../../provider/user.dart";
import "../../../services/image_to_color_scheme.dart";
import "../../../utils.dart";
import "../../../widgets/audio_track.dart";
import "../../../widgets/dialogs.dart";
import "../../../widgets/page_route_builders.dart";
import "../../login.dart";
import "../music.dart";
import "spotify_auth.dart";

/// Диалог, подтверждающий у пользователя действие для выхода из аккаунта на экране [HomeProfilePage].
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const ProfileLogoutExitDialog()
/// );
/// ```
class ProfileLogoutExitDialog extends ConsumerWidget {
  const ProfileLogoutExitDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onLogoutPressed() =>
        ref.read(currentAuthStateProvider.notifier).logout();

    final user = ref.watch(userProvider);
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.logout_outlined,
      title: l18n.home_profilePageLogoutTitle,
      text: l18n.home_profilePageLogoutDescription(
        user.fullName,
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            l18n.general_no,
          ),
        ),
        FilledButton(
          onPressed: onLogoutPressed,
          child: Text(
            l18n.general_yes,
          ),
        ),
      ],
    );
  }
}

/// Диалог, подтверждающий у пользователя действие подключения рекомендаций ВКонтакте на экране [HomeMusicPage].
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const ConnectRecommendationsDialog()
/// );
/// ```
class ConnectRecommendationsDialog extends ConsumerWidget {
  const ConnectRecommendationsDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.auto_fix_high,
      title: l18n.music_connectRecommendationsTitle,
      text: l18n.music_connectRecommendationsDescription,
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            l18n.general_no,
          ),
        ),
        FilledButton(
          onPressed: () {
            context.pop();

            Navigator.push(
              context,
              Material3PageRoute(
                builder: (context) => const LoginRoute(
                  useAlternateAuth: true,
                ),
              ),
            );
          },
          child: Text(
            l18n.music_connectRecommendationsConnect,
          ),
        ),
      ],
    );
  }
}

/// Диалог, подтверждающий у пользователя действие отключения обновлений на экране [HomeMusicPage].
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const ConnectRecommendationsDialog()
/// );
/// ```
class DisableUpdatesDialog extends ConsumerWidget {
  const DisableUpdatesDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.update_disabled,
      title: l18n.profile_disableUpdatesWarningTitle,
      text: l18n.profile_disableUpdatesWarningDescription,
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text(
            l18n.general_no,
          ),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          child: Text(
            l18n.profile_disableUpdatesWarningDisable,
          ),
        ),
      ],
    );
  }
}

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
    assert(
      isDesktop,
      "CloseActionDialog can only be called on desktop",
    );

    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);

    void onValueChanged(CloseBehavior? behavior) {
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

      for (final (int index, List<dynamic> track) in tracks.indexed) {
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
                  width: 210,
                  child: AudioTrackTile(
                    audio: ExtendedAudio(
                      title: title,
                      artist: artist,
                      deezerThumbs: ExtendedThumbnails(
                        photoBig: url,
                        photoMax: url,
                        photoMedium: url,
                        photoSmall: url,
                      ),
                      id: 0 - index,
                      ownerID: 0 - index,
                      duration: 0,
                      accessKey: "",
                      date: 0,
                    ),
                    showDuration: false,
                    forceAvailable: true,
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

/// Диалог, помогающий пользователю поменять настройку "Отображение новых обновлений".
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const UpdatesDialogTypeActionDialog()
/// );
/// ```
class UpdatesDialogTypeActionDialog extends ConsumerWidget {
  const UpdatesDialogTypeActionDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);

    void onValueChanged(UpdatePolicy? policy) async {
      if (policy == null) return;

      // Делаем небольшое предупреждение, если пользователь пытается отключить обновления.
      if (policy == UpdatePolicy.disabled) {
        final bool response = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return const DisableUpdatesDialog();
              },
            ) ??
            false;

        // Пользователь нажал на "Отключить", тогда мы должны выключить обновления.
        if (response && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l18n.profile_updatesDisabledText,
              ),
              duration: const Duration(
                seconds: 8,
              ),
            ),
          );
        }

        // Пользователь отказался отключать уведомления, тогда ничего не меняем.
        if (!response) return;
      }

      prefsNotifier.setUpdatePolicy(policy);
    }

    return MaterialDialog(
      icon: Icons.update,
      title: l18n.profile_updatesPolicyTitle,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_updatesPolicyDialog,
          ),
          value: UpdatePolicy.dialog,
          groupValue: preferences.updatePolicy,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_updatesPolicyPopup,
          ),
          value: UpdatePolicy.popup,
          groupValue: preferences.updatePolicy,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_updatesPolicyDisabled,
          ),
          value: UpdatePolicy.disabled,
          groupValue: preferences.updatePolicy,
          onChanged: onValueChanged,
        ),
      ],
    );
  }
}

/// Диалог, помогающий пользователю поменять настройку "Канал обновлений".
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const UpdatesChannelDialog()
/// );
/// ```
class UpdatesChannelDialog extends ConsumerWidget {
  const UpdatesChannelDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);

    void onValueChanged(UpdateBranch? branch) {
      if (branch == null) return;

      prefsNotifier.setUpdateBranch(branch);
    }

    return MaterialDialog(
      icon: Icons.update,
      title: l18n.profile_updatesBranchTitle,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_updatesBranchReleases,
          ),
          value: UpdateBranch.releasesOnly,
          groupValue: preferences.updateBranch,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            l18n.profile_updatesBranchPrereleases,
          ),
          value: UpdateBranch.prereleases,
          groupValue: preferences.updateBranch,
          onChanged: onValueChanged,
        ),
      ],
    );
  }
}

/// Диалог, предупреждающий пользователя перед подключением функции "Тексты песен из Spotify".
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const SpotifyLyricsDialog()
/// );
/// ```
class SpotifyLyricsDialog extends ConsumerWidget {
  const SpotifyLyricsDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.lyrics,
      title: l18n.profile_spotifyLyricsAuthorizeTitle,
      text: l18n.profile_spotifyLyricsAuthorizeDescription,
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            l18n.general_close,
          ),
        ),
        FilledButton(
          onPressed: () {
            context.pop();

            Navigator.of(context).push(
              Material3PageRoute(
                builder: (BuildContext context) => const SpotifyLoginRoute(),
              ),
            );
          },
          child: Text(
            l18n.profile_spotifyLyricsAuthorizeButton,
          ),
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
class ExportTracksListDialog extends StatelessWidget {
  const ExportTracksListDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();

    // final UserProvider user = Provider.of<UserProvider>(context);

    // assert(
    //   user.favoritesPlaylist?.audios != null,
    //   "Expected tracks list to be loaded",
    // );

    // final String exportContents = user.favoritesPlaylist!.audios!
    //     .map((ExtendedAudio audio) => "${audio.artist} • ${audio.title}")
    //     .join("\n\n");

    // return MaterialDialog(
    //   icon: Icons.my_library_music,
    //   title: l18n.profile_exportMusicListTitle,
    //   text: l18n.profile_exportMusicListDescription(
    //     user.favoritesPlaylist!.audios!.length,
    //   ),
    //   contents: [
    //     SelectableText(
    //       exportContents,
    //     ),
    //   ],
    //   actions: [
    //     TextButton(
    //       onPressed: () => context.pop(),
    //       child: Text(
    //         l18n.general_close,
    //       ),
    //     ),
    //     FilledButton.icon(
    //       onPressed: () => Share.share(exportContents),
    //       icon: const Icon(
    //         Icons.share,
    //       ),
    //       label: Text(
    //         l18n.profile_exportMusicListShareTitle,
    //       ),
    //     ),
    //   ],
    // );
  }
}

/// Диалог, подтверждающий у пользователя то, что он хочет сбросить локальную базу данных приложения.
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const ResetDBDialog()
/// );
/// ```
class ResetDBDialog extends ConsumerWidget {
  const ResetDBDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return MaterialDialog(
      icon: Icons.delete,
      title: l18n.profile_resetDBDialogTitle,
      text: l18n.profile_resetDBDialogDescription,
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text(
            l18n.general_no,
          ),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          child: Text(
            l18n.profile_resetDBDialogReset,
          ),
        ),
      ],
    );
  }
}
