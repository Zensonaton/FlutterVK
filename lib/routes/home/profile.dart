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
              title: Text(
                AppLocalizations.of(context)!.home_profilePageLabel,
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
                      if (user.photoMaxUrl != null)
                        CachedNetworkImage(
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
                      if (user.photoMaxUrl != null)
                        const SizedBox(
                          height: 12,
                        ),
                      Text(
                        user.fullName!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      SelectableText(
                        "ID ${user.id}",
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.5),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Подключение рекомендаций.
                if (user.recommendationsToken == null)
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!
                          .music_connectRecommendationsChipTitle,
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!
                          .music_connectRecommendationsChipDescription,
                    ),
                    leading: const Icon(
                      Icons.auto_fix_high,
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) =>
                          const ConnectRecommendationsDialog(),
                    ),
                  ),

                // Discord Rich Presence.
                if (isDesktop)
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.discord,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.profile_discordRPCTitle,
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
                      AppLocalizations.of(context)!.profile_closeActionTitle,
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!
                          .profile_closeActionDescription,
                    ),
                    trailing: DropdownButton(
                      onChanged: (AppCloseBehavior? behavior) {
                        if (behavior == null) return;

                        user.settings.closeBehavior = behavior;

                        user.markUpdated();
                      },
                      value: user.settings.closeBehavior,
                      items: [
                        DropdownMenuItem(
                          value: AppCloseBehavior.close,
                          child: Text(
                            AppLocalizations.of(context)!
                                .profile_closeActionClose,
                          ),
                        ),
                        DropdownMenuItem(
                          value: AppCloseBehavior.minimize,
                          child: Text(
                            AppLocalizations.of(context)!
                                .profile_closeActionMinimize,
                          ),
                        ),
                        DropdownMenuItem(
                          value: AppCloseBehavior.minimizeIfPlaying,
                          child: Text(
                            AppLocalizations.of(context)!
                                .profile_closeActionMinimizeIfPlaying,
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
                  trailing: DropdownButton(
                    onChanged: (ThemeMode? mode) {
                      if (mode == null) return;

                      user.settings.theme = mode;

                      user.markUpdated();
                    },
                    value: user.settings.theme,
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(
                          AppLocalizations.of(context)!.profile_themeSystem,
                        ),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(
                          AppLocalizations.of(context)!.profile_themeLight,
                        ),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(
                          AppLocalizations.of(context)!.profile_themeDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // OLED тема.
                SwitchListTile(
                  secondary: const Icon(
                    Icons.mode_night,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.profile_oledThemeTitle,
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

                // Пауза воспроизведения при минимальной громкости.
                if (isDesktop)
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.timer,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.profile_pauseOnMuteTitle,
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

                // Экспорт списка треков.
                ListTile(
                  leading: const Icon(
                    Icons.my_library_music,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.profile_exportMusicListTitle,
                  ),
                  onTap: () => showWipDialog(context),
                ),

                // Поделиться логами.
                FutureBuilder<bool>(
                  future: logExistsFuture,
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    final bool exists = snapshot.data ?? false;

                    return ListTile(
                      leading: const Icon(
                        Icons.bug_report,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.profile_shareLogsTitle,
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
                    AppLocalizations.of(context)!.profile_githubDescription,
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
                    AppLocalizations.of(context)!.profile_updatesPolicyTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!
                        .profile_updatesPolicyDescription,
                  ),
                  trailing: DropdownButton(
                    onChanged: (UpdatePolicy? policy) async {
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
                        if (response && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!
                                    .profile_updatesDisabledText,
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
                    },
                    value: user.settings.updatePolicy,
                    items: [
                      DropdownMenuItem(
                        value: UpdatePolicy.dialog,
                        child: Text(
                          AppLocalizations.of(context)!
                              .profile_updatesPolicyDialog,
                        ),
                      ),
                      DropdownMenuItem(
                        value: UpdatePolicy.popup,
                        child: Text(
                          AppLocalizations.of(context)!
                              .profile_updatesPolicyPopup,
                        ),
                      ),
                      DropdownMenuItem(
                        value: UpdatePolicy.disabled,
                        child: Text(
                          AppLocalizations.of(context)!
                              .profile_updatesPolicyDisabled,
                        ),
                      ),
                    ],
                  ),
                ),

                // Канал для автообновлений.
                ListTile(
                  enabled: user.settings.updatePolicy != UpdatePolicy.disabled,
                  leading: const Icon(
                    Icons.route,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.profile_updatesBranchTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!
                        .profile_updatesBranchDescription,
                  ),
                  trailing: DropdownButton(
                    onChanged:
                        user.settings.updatePolicy != UpdatePolicy.disabled
                            ? (UpdateBranch? branch) {
                                if (branch == null) return;

                                user.settings.updateBranch = branch;

                                user.markUpdated();
                              }
                            : null,
                    value: user.settings.updateBranch,
                    items: [
                      DropdownMenuItem(
                        value: UpdateBranch.releasesOnly,
                        child: Text(
                          AppLocalizations.of(context)!
                              .profile_updatesBranchReleases,
                        ),
                      ),
                      DropdownMenuItem(
                        value: UpdateBranch.prereleases,
                        child: Text(
                          AppLocalizations.of(context)!
                              .profile_updatesBranchPrereleases,
                        ),
                      ),
                    ],
                  ),
                ),

                // Версия приложения.
                ListTile(
                  leading: const Icon(
                    Icons.info,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.profile_appVersionTitle,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!
                        .profile_appVersionDescription("v$appVersion"),
                  ),
                  onTap: () => Updater.checkForUpdates(
                    context,
                    allowPre:
                        user.settings.updateBranch == UpdateBranch.prereleases,
                    showLoadingOverlay: true,
                    showMessageOnNoUpdates: true,
                  ),
                ),

                // Debug-опции.
                if (kDebugMode)
                  ListTile(
                    leading: const Icon(
                      Icons.key,
                    ),
                    title: const Text(
                      "Скопировать Kate Mobile токен",
                    ),
                    subtitle: const Text(
                      "Debug-режим",
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
                if (kDebugMode && user.recommendationsToken != null)
                  ListTile(
                    leading: const Icon(
                      Icons.key,
                    ),
                    title: const Text(
                      "Скопировать VK Admin токен",
                    ),
                    subtitle: const Text(
                      "Debug-режим",
                    ),
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

                // Выход из аккаунта.
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.home_profilePageLogout,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => const ProfileLogoutExitDialog(),
                  ),
                ),

                // Данный SizedBox нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
                if (player.loaded && isMobileLayout)
                  const SizedBox(
                    height: 80,
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
