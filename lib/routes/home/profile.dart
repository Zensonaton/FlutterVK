import "dart:async";
import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:share_plus/share_plus.dart";
import "package:url_launcher/url_launcher.dart";

import "../../consts.dart";
import "../../enums.dart";
import "../../main.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
import "../../services/logger.dart";
import "../../services/updater.dart";
import "../../utils.dart";
import "../../widgets/dialogs.dart";

import "../../widgets/page_route_builders.dart";
import "../login.dart";
import "../welcome.dart";

/// Диалог, подтверждающий у пользователя действие для выхода из аккаунта на экране [HomeProfilePage].
///
/// Пример использования:
/// ```dart
/// showDialog(
/// 	context: context,
/// 	builder: (context) => const ProfileLogoutExitDialog()
/// );
/// ```
class ProfileLogoutExitDialog extends StatelessWidget {
  const ProfileLogoutExitDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    return MaterialDialog(
      icon: Icons.logout_outlined,
      title: AppLocalizations.of(context)!.home_profilePageLogoutTitle,
      text: AppLocalizations.of(context)!.home_profilePageLogoutDescription(
        user.fullName!,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)!.general_no,
          ),
        ),
        TextButton(
          onPressed: () {
            user.logout();

            Navigator.pushAndRemoveUntil(
              context,
              Material3PageRoute(
                builder: (context) => const WelcomeRoute(),
              ),
              (route) => false,
            );
          },
          child: Text(
            AppLocalizations.of(context)!.general_yes,
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
class ConnectRecommendationsDialog extends StatelessWidget {
  const ConnectRecommendationsDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialDialog(
      icon: Icons.auto_fix_high,
      title: AppLocalizations.of(context)!.music_connectRecommendationsTitle,
      text:
          AppLocalizations.of(context)!.music_connectRecommendationsDescription,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)!.general_no,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);

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
            AppLocalizations.of(context)!.music_connectRecommendationsConnect,
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
class DisableUpdatesDialog extends StatelessWidget {
  const DisableUpdatesDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialDialog(
      icon: Icons.update_disabled,
      title: AppLocalizations.of(context)!.profile_disableUpdatesWarningTitle,
      text: AppLocalizations.of(context)!
          .profile_disableUpdatesWarningDescription,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            AppLocalizations.of(context)!.general_no,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            AppLocalizations.of(context)!.profile_disableUpdatesWarningDisable,
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
class CloseActionDialog extends StatelessWidget {
  const CloseActionDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    assert(isDesktop, "CloseActionDialog can only be called on desktop");

    void onValueChanged(AppCloseBehavior? behavior) {
      if (behavior == null) return;

      user.settings.closeBehavior = behavior;
      user.markUpdated();
    }

    return MaterialDialog(
      icon: Icons.close,
      title: AppLocalizations.of(context)!.profile_closeActionTitle,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            AppLocalizations.of(context)!.profile_closeActionClose,
          ),
          value: AppCloseBehavior.close,
          groupValue: user.settings.closeBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            AppLocalizations.of(context)!.profile_closeActionMinimize,
          ),
          value: AppCloseBehavior.minimize,
          groupValue: user.settings.closeBehavior,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            AppLocalizations.of(context)!.profile_closeActionMinimizeIfPlaying,
          ),
          value: AppCloseBehavior.minimizeIfPlaying,
          groupValue: user.settings.closeBehavior,
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
class ThemeActionDialog extends StatelessWidget {
  const ThemeActionDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    void onValueChanged(ThemeMode? mode) {
      if (mode == null) return;

      user.settings.theme = mode;
      user.markUpdated();
    }

    return MaterialDialog(
      icon: Icons.dark_mode,
      title: AppLocalizations.of(context)!.profile_themeTitle,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            AppLocalizations.of(context)!.profile_themeSystem,
          ),
          value: ThemeMode.system,
          groupValue: user.settings.theme,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            AppLocalizations.of(context)!.profile_themeLight,
          ),
          value: ThemeMode.light,
          groupValue: user.settings.theme,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            AppLocalizations.of(context)!.profile_themeDark,
          ),
          value: ThemeMode.dark,
          groupValue: user.settings.theme,
          onChanged: onValueChanged,
        ),
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
class UpdatesDialogTypeActionDialog extends StatelessWidget {
  const UpdatesDialogTypeActionDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

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
                AppLocalizations.of(context)!.profile_updatesDisabledText,
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

      user.settings.updatePolicy = policy;

      user.markUpdated();
    }

    return MaterialDialog(
      icon: Icons.update,
      title: AppLocalizations.of(context)!.profile_updatesPolicyTitle,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            AppLocalizations.of(context)!.profile_updatesPolicyDialog,
          ),
          value: UpdatePolicy.dialog,
          groupValue: user.settings.updatePolicy,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            AppLocalizations.of(context)!.profile_updatesPolicyPopup,
          ),
          value: UpdatePolicy.popup,
          groupValue: user.settings.updatePolicy,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            AppLocalizations.of(context)!.profile_updatesPolicyDisabled,
          ),
          value: UpdatePolicy.disabled,
          groupValue: user.settings.updatePolicy,
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
class UpdatesChannelDialog extends StatelessWidget {
  const UpdatesChannelDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    void onValueChanged(UpdateBranch? branch) {
      if (branch == null) return;

      user.settings.updateBranch = branch;

      user.markUpdated();
    }

    return MaterialDialog(
      icon: Icons.update,
      title: AppLocalizations.of(context)!.profile_updatesBranchTitle,
      contents: [
        RadioListTile.adaptive(
          title: Text(
            AppLocalizations.of(context)!.profile_updatesBranchReleases,
          ),
          value: UpdateBranch.releasesOnly,
          groupValue: user.settings.updateBranch,
          onChanged: onValueChanged,
        ),
        RadioListTile.adaptive(
          title: Text(
            AppLocalizations.of(context)!.profile_updatesBranchPrereleases,
          ),
          value: UpdateBranch.prereleases,
          groupValue: user.settings.updateBranch,
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
class ExportTracksListDialog extends StatelessWidget {
  const ExportTracksListDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    assert(
      user.favoritesPlaylist?.audios != null,
      "Expected tracks list to be loaded",
    );

    final String exportContents = user.favoritesPlaylist!.audios!
        .map((ExtendedAudio audio) => "${audio.artist} • ${audio.title}")
        .join("\n\n");

    return MaterialDialog(
      icon: Icons.my_library_music,
      title: AppLocalizations.of(context)!.profile_exportMusicListTitle,
      text: AppLocalizations.of(context)!.profile_exportMusicListDescription(
        user.favoritesPlaylist!.audios!.length,
      ),
      contents: [
        SelectableText(
          exportContents,
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)!.general_close,
          ),
        ),
        FilledButton.icon(
          onPressed: () => Share.share(exportContents),
          icon: const Icon(
            Icons.share,
          ),
          label: Text(
            AppLocalizations.of(context)!.profile_exportMusicListShareTitle,
          ),
        ),
      ],
    );
  }
}

/// Страница для [HomeRoute] для просмотра собственного профиля.
class HomeProfilePage extends StatefulWidget {
  const HomeProfilePage({
    super.key,
  });

  @override
  State<HomeProfilePage> createState() => _HomeProfilePageState();
}

class _HomeProfilePageState extends State<HomeProfilePage> {
  /// Подписки на изменения состояния воспроизведения трека.
  late final List<StreamSubscription> subscriptions;

  /// Future, отображающий информацию о том, существует ли файл с логом.
  late final Future<bool> logExistsFuture;

  /// Future, возвращающий информацию о том, существует ли файл с логом.
  Future<bool> _logFileExists() async {
    final File file = await logFilePath();

    return file.existsSync();
  }

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
      ),
    ];

    logExistsFuture = _logFileExists();
  }

  @override
  void dispose() {
    super.dispose();

    for (StreamSubscription subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    final bool isMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

    return Scaffold(
      appBar: isMobileLayout
          ? AppBar(
              title: StreamBuilder<bool>(
                stream: connectivityManager.connectionChange,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final bool isConnected = connectivityManager.hasConnection;

                  return Text(
                    isConnected
                        ? AppLocalizations.of(context)!.home_profilePageLabel
                        : AppLocalizations.of(context)!
                            .home_profilePageLabelOffline,
                  );
                },
              ),
              centerTitle: true,
            )
          : null,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView(
              children: [
                // Информация о текущем пользователе.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                  child: Column(
                    children: [
                      // Аватар пользователя, при наличии.
                      if (user.photoMaxUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: user.photoMaxUrl!,
                            cacheKey: "${user.id!}400",
                            placeholder: (BuildContext context, String url) {
                              return const SizedBox(
                                height: 80,
                                width: 80,
                              );
                            },
                            imageBuilder: (context, imageProvider) => Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.scaleDown,
                                ),
                              ),
                            ),
                            cacheManager: CachedNetworkImagesManager.instance,
                          ),
                        ),

                      // Имя пользователя.
                      Text(
                        user.fullName!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),

                      // ID ВКонтакте.
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16,
                        ),
                        child: SelectableText(
                          "ID ${user.id}",
                          style:
                              Theme.of(context).textTheme.titleSmall!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground
                                        .withOpacity(0.5),
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Выход из аккаунта.
                      FilledButton.tonalIcon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => const ProfileLogoutExitDialog(),
                        ),
                        icon: const Icon(
                          Icons.logout,
                        ),
                        label: Text(
                          AppLocalizations.of(context)!.home_profilePageLogout,
                        ),
                      ),
                    ],
                  ),
                ),

                // Подключение рекомендаций.
                if (user.recommendationsToken == null)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: ListTile(
                      title: Text(
                        AppLocalizations.of(context)!
                            .music_connectRecommendationsChipTitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!
                            .music_connectRecommendationsChipDescription,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      leading: Icon(
                        Icons.auto_fix_high,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) =>
                            const ConnectRecommendationsDialog(),
                      ),
                    ),
                  ),

                // Музыкальный плеер.
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 16,
                    left: !isMobileLayout ? 10 : 0,
                    right: !isMobileLayout ? 18 : 0,
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 6,
                              left: 17,
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 11,
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!
                                      .profile_musicPlayerTitle,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Discord Rich Presence.
                          if (isDesktop)
                            SwitchListTile(
                              secondary: const Icon(
                                Icons.discord,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!
                                    .profile_discordRPCTitle,
                              ),
                              subtitle: Text(
                                AppLocalizations.of(context)!
                                    .profile_discordRPCDescription,
                              ),
                              value: player.discordRPCEnabled,
                              onChanged: (bool? enabled) async {
                                if (enabled == null) return;

                                user.settings.discordRPCEnabled = enabled;
                                await player.setDiscordRPCEnabled(enabled);

                                user.markUpdated();
                              },
                            ),

                          // Действие при закрытии.
                          if (isDesktop)
                            ListTile(
                              leading: const Icon(
                                Icons.close,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!
                                    .profile_closeActionTitle,
                              ),
                              subtitle: Text(
                                AppLocalizations.of(context)!
                                    .profile_closeActionDescription,
                              ),
                              onTap: () => showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    const CloseActionDialog(),
                              ),
                              trailing: !isMobileLayout
                                  ? FilledButton(
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            const CloseActionDialog(),
                                      ),
                                      child: Text(
                                        {
                                          AppCloseBehavior.close:
                                              AppLocalizations.of(context)!
                                                  .profile_closeActionClose,
                                          AppCloseBehavior.minimize:
                                              AppLocalizations.of(context)!
                                                  .profile_closeActionMinimize,
                                          AppCloseBehavior
                                              .minimizeIfPlaying: AppLocalizations
                                                  .of(
                                            context,
                                          )!
                                              .profile_closeActionMinimizeIfPlaying,
                                        }[user.settings.closeBehavior]!,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : null,
                            ),

                          // Пауза воспроизведения при минимальной громкости.
                          if (isDesktop)
                            SwitchListTile(
                              secondary: const Icon(
                                Icons.volume_off,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!
                                    .profile_pauseOnMuteTitle,
                              ),
                              subtitle: Text(
                                AppLocalizations.of(context)!
                                    .profile_pauseOnMuteDescription,
                              ),
                              value: user.settings.pauseOnMuteEnabled,
                              onChanged: (bool? enabled) async {
                                if (enabled == null) return;

                                user.settings.pauseOnMuteEnabled = enabled;

                                user.markUpdated();
                              },
                            ),

                          // Остановка плеера при неактивности.
                          SwitchListTile(
                            secondary: const Icon(
                              Icons.timer,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!
                                  .profile_stopOnLongPauseTitle,
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!
                                  .profile_stopOnLongPauseDescription,
                            ),
                            value: user.settings.stopOnPauseEnabled,
                            onChanged: (bool? enabled) async {
                              if (enabled == null) return;

                              user.settings.stopOnPauseEnabled = enabled;
                              player.setStopOnPauseEnabled(enabled);

                              user.markUpdated();
                            },
                          ),

                          // Предупреждение создание дубликата при сохранении.
                          SwitchListTile(
                            secondary: const Icon(
                              Icons.copy,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!
                                  .profile_checkBeforeFavoriteTitle,
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!
                                  .profile_checkBeforeFavoriteDescription,
                            ),
                            value: user.settings.checkBeforeFavorite,
                            onChanged: (bool? enabled) async {
                              if (enabled == null) return;

                              user.settings.checkBeforeFavorite = enabled;

                              user.markUpdated();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Визуал.
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 16,
                    left: !isMobileLayout ? 10 : 0,
                    right: !isMobileLayout ? 18 : 0,
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 6,
                              left: 17,
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 11,
                                  ),
                                  child: Icon(
                                    Icons.color_lens,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!
                                      .profile_visualTitle,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Тема приложения.
                          ListTile(
                            leading: const Icon(
                              Icons.dark_mode,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!.profile_themeTitle,
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  const ThemeActionDialog(),
                            ),
                            trailing: !isMobileLayout
                                ? FilledButton(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          const ThemeActionDialog(),
                                    ),
                                    child: Text(
                                      {
                                        ThemeMode.system:
                                            AppLocalizations.of(context)!
                                                .profile_themeSystem,
                                        ThemeMode.light:
                                            AppLocalizations.of(context)!
                                                .profile_themeLight,
                                        ThemeMode.dark: AppLocalizations.of(
                                          context,
                                        )!
                                            .profile_themeDark,
                                      }[user.settings.theme]!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : null,
                          ),

                          // OLED тема.
                          SwitchListTile(
                            secondary: const Icon(
                              Icons.mode_night,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!
                                  .profile_oledThemeTitle,
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!
                                  .profile_oledThemeDescription,
                            ),
                            value: user.settings.oledTheme,
                            onChanged: (bool? enabled) async {
                              if (enabled == null) return;

                              user.settings.oledTheme = enabled;

                              user.markUpdated();
                            },
                          ),

                          // Использование изображения трека для фона в полноэкранном плеере.
                          SwitchListTile(
                            secondary: const Icon(
                              Icons.photo_filter,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!
                                  .profile_useThumbnailAsBackgroundTitle,
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!
                                  .profile_useThumbnailAsBackgroundDescription,
                            ),
                            value: user.settings.playerThumbAsBackground,
                            onChanged: (bool? enabled) async {
                              if (enabled == null) return;

                              user.settings.playerThumbAsBackground = enabled;

                              user.markUpdated();
                            },
                          ),

                          // Использование цветов плеера по всему приложению.
                          SwitchListTile(
                            secondary: const Icon(
                              Icons.color_lens,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!
                                  .profile_usePlayerColorsAppWideTitle,
                            ),
                            value: user.settings.playerColorsAppWide,
                            onChanged: (bool? enabled) async {
                              if (enabled == null) return;

                              user.settings.playerColorsAppWide = enabled;

                              user.markUpdated();
                            },
                          ),

                          // Точный алгоритм цветов плеера.
                          SwitchListTile(
                            secondary: const Icon(
                              Icons.auto_fix_high,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!
                                  .profile_playerSchemeAlgorithmTitle,
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!
                                  .profile_playerSchemeAlgorithmDescription,
                            ),
                            value: user.settings.playerSchemeAlgorithm,
                            onChanged: (bool? enabled) async {
                              if (enabled == null) return;

                              user.settings.playerSchemeAlgorithm = enabled;

                              user.markUpdated();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Экспериментальные функции.
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 16,
                    left: !isMobileLayout ? 10 : 0,
                    right: !isMobileLayout ? 18 : 0,
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 6,
                              left: 17,
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 11,
                                  ),
                                  child: Icon(
                                    Icons.bug_report,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!
                                      .profile_experimentalTitle,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Загрузка отсутсвующих обложек из Deezer.
                          SwitchListTile(
                            secondary: const Icon(
                              Icons.image_search,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!
                                  .profile_deezerThumbnailsTitle,
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!
                                  .profile_deezerThumbnailsDescription,
                            ),
                            value: user.settings.deezerThumbnails,
                            onChanged: (bool? enabled) async {
                              if (enabled == null) return;

                              user.settings.deezerThumbnails = enabled;

                              user.markUpdated();
                            },
                          ),

                          // Экспорт списка треков.
                          ListTile(
                            leading: const Icon(
                              Icons.my_library_music,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!
                                  .profile_exportMusicListTitle,
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  const ExportTracksListDialog(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // О приложении.
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 16,
                    left: !isMobileLayout ? 10 : 0,
                    right: !isMobileLayout ? 18 : 0,
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 6,
                              left: 17,
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 11,
                                  ),
                                  child: Icon(
                                    Icons.info,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!
                                      .profile_aboutTitle,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Поделиться логами.
                          FutureBuilder<bool>(
                            future: logExistsFuture,
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<bool> snapshot,
                            ) {
                              final bool exists = snapshot.data ?? false;

                              return ListTile(
                                leading: const Icon(
                                  Icons.bug_report,
                                ),
                                title: Text(
                                  AppLocalizations.of(context)!
                                      .profile_shareLogsTitle,
                                ),
                                enabled: exists,
                                subtitle: Text(
                                  exists
                                      ? AppLocalizations.of(context)!
                                          .profile_shareLogsDescription
                                      : AppLocalizations.of(context)!
                                          .profile_shareLogsNoLogsDescription,
                                ),
                                onTap: () async => Share.shareXFiles(
                                  [
                                    XFile((await logFilePath()).path),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Github.
                          ListTile(
                            leading: const Icon(
                              Icons.source,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!.profile_githubTitle,
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!
                                  .profile_githubDescription,
                            ),
                            onTap: () => launchUrl(
                              Uri.parse(
                                repoURL,
                              ),
                            ),
                          ),

                          // Политика для обновлений.
                          ListTile(
                            leading: const Icon(
                              Icons.update,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!
                                  .profile_updatesPolicyTitle,
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!
                                  .profile_updatesPolicyDescription,
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  const UpdatesDialogTypeActionDialog(),
                            ),
                            trailing: !isMobileLayout
                                ? FilledButton(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          const UpdatesDialogTypeActionDialog(),
                                    ),
                                    child: Text(
                                      {
                                        UpdatePolicy.dialog:
                                            AppLocalizations.of(context)!
                                                .profile_updatesPolicyDialog,
                                        UpdatePolicy.popup:
                                            AppLocalizations.of(context)!
                                                .profile_updatesPolicyPopup,
                                        UpdatePolicy.disabled:
                                            AppLocalizations.of(
                                          context,
                                        )!
                                                .profile_updatesPolicyDisabled,
                                      }[user.settings.updatePolicy]!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : null,
                          ),

                          // Канал для автообновлений.
                          ListTile(
                            enabled: user.settings.updatePolicy !=
                                UpdatePolicy.disabled,
                            leading: const Icon(
                              Icons.route,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!
                                  .profile_updatesBranchTitle,
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!
                                  .profile_updatesBranchDescription,
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  const UpdatesChannelDialog(),
                            ),
                            trailing: !isMobileLayout
                                ? FilledButton(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          const UpdatesChannelDialog(),
                                    ),
                                    child: Text(
                                      {
                                        UpdateBranch.releasesOnly:
                                            AppLocalizations.of(context)!
                                                .profile_updatesBranchReleases,
                                        UpdateBranch
                                            .prereleases: AppLocalizations.of(
                                          context,
                                        )!
                                            .profile_updatesBranchPrereleases,
                                      }[user.settings.updateBranch]!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : null,
                          ),

                          // Версия приложения (и проверка текущей версии).
                          ListTile(
                            leading: const Icon(
                              Icons.info,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!
                                  .profile_appVersionTitle,
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!
                                  .profile_appVersionDescription(
                                "v$appVersion",
                              ),
                            ),
                            onTap: () {
                              if (!networkRequiredDialog(context)) return;

                              Updater.checkForUpdates(
                                context,
                                allowPre: user.settings.updateBranch ==
                                    UpdateBranch.prereleases,
                                showLoadingOverlay: true,
                                showMessageOnNoUpdates: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Debug-опции.
                if (kDebugMode)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 10,
                      left: !isMobileLayout ? 10 : 0,
                      right: !isMobileLayout ? 18 : 0,
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(
                          4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 6,
                                left: 17,
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      right: 11,
                                    ),
                                    child: Icon(
                                      Icons.logo_dev,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    "Debug",
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Кнопка для копирования Kate Mobile токена.
                            ListTile(
                              leading: const Icon(
                                Icons.key,
                              ),
                              title: const Text(
                                "Скопировать Kate Mobile токен",
                              ),
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: user.mainToken!,
                                  ),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("OK."),
                                  ),
                                );
                              },
                            ),

                            // Кнопка для копирования рекомендационного токена (VK Admin).
                            ListTile(
                              leading: const Icon(
                                Icons.key,
                              ),
                              title: const Text(
                                "Скопировать VK Admin токен",
                              ),
                              enabled: user.recommendationsToken != null,
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: user.recommendationsToken!,
                                  ),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("OK."),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Данный SizedBox нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
                if (player.loaded && isMobileLayout)
                  const SizedBox(
                    height: 70,
                  ),
              ],
            ),
          ),

          // Данный SizedBox нужен, что бы плеер снизу при Desktop Layout'е не закрывал ничего важного.
          // Мы его располагаем после ListView, что бы ScrollBar не был закрыт плеером.
          if (player.loaded && !isMobileLayout)
            const SizedBox(
              height: 88,
            ),
        ],
      ),
    );
  }
}
