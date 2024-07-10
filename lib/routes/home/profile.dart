import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:share_plus/share_plus.dart";
import "package:url_launcher/url_launcher.dart";

import "../../consts.dart";
import "../../enums.dart";
import "../../main.dart";
import "../../provider/auth.dart";
import "../../provider/l18n.dart";
import "../../provider/player_events.dart";
import "../../provider/preferences.dart";
import "../../provider/spotify_api.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
import "../../services/logger.dart";
import "../../services/updater.dart";
import "../../utils.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/page_route_builders.dart";
import "profile/debug/colorscheme.dart";
import "profile/debug/playlists_viewer.dart";
import "profile/dialogs.dart";

/// Вызывает окно, дающее пользователю возможность поделиться файлом логов приложения ([logFilePath]), либо же открывающее проводник (`explorer.exe`) с файлом логов (на OS Windows).
void shareLogs() async {
  final File path = await logFilePath();

  // Если пользователь на OS Windows, то просто открываем папку с файлом.
  if (Platform.isWindows) {
    await Process.run(
      "explorer.exe",
      ["/select,", path.path],
    );

    return;
  }

  // В ином случае делимся файлом.
  await Share.shareXFiles([XFile(path.path)]);
}

/// Виджет, отображающий отдельную категорию настроек в профиле.
class ProfileSettingCategory extends StatelessWidget {
  /// Иконка категории.
  final IconData icon;

  /// Название категории.
  final String title;

  /// Указывает, что [title] и [icon] будут располагаться по центру и вне виджета [Card]. Используется при Mobile Layout'е.
  final bool centerTitle;

  /// Содержимое этой категории.
  final List<Widget> children;

  const ProfileSettingCategory({
    super.key,
    required this.icon,
    required this.title,
    this.centerTitle = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final Widget titleWidget = Row(
      mainAxisSize: centerTitle ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // Иконка.
        if (!centerTitle) const Gap(16),
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const Gap(12),

        // Название категории.
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: centerTitle ? 0 : 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: Column(
          children: [
            // Внешнее название виджета.
            if (centerTitle) ...[
              titleWidget,
              const Gap(8),
            ],

            // Внутреннее содержимое.
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  globalBorderRadius,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Иконка и название.
                  if (!centerTitle) ...[
                    const Gap(14),
                    titleWidget,
                    const Gap(8),
                  ],

                  // Содержимое.
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет, отображающий [ListView] с кнопкой внутри (при Desktop Layout) с текущим значением этой настройки, а так же отображающий диалог при нажатии.
class SettingWithDialog extends StatelessWidget {
  /// Иконка настройки.
  final IconData icon;

  /// Название настройки.
  final String title;

  /// Описание настройки.
  final String? subtitle;

  /// [Widget], отображаемый как диалог, который будет открыт при нажатии на эту настройку.
  final Widget dialog;

  /// Указывает, можно ли изменить значение данной настройки.
  final bool enabled;

  /// Текст у кнопки у этой настройки. Текст должен быть равен текущему текстовому описанию настройки.
  final String settingText;

  const SettingWithDialog({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.dialog,
    this.enabled = true,
    required this.settingText,
  });

  @override
  Widget build(BuildContext context) {
    final bool mobileLayout = isMobileLayout(context);

    void onTap() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return dialog;
        },
      );
    }

    return ListTile(
      leading: Icon(
        icon,
      ),
      title: Text(
        title,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
            )
          : null,
      enabled: enabled,
      onTap: onTap,
      trailing: !mobileLayout
          ? FilledButton.icon(
              icon: const Icon(
                Icons.open_in_new,
              ),
              label: Text(
                settingText,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: enabled ? onTap : null,
            )
          : null,
    );
  }
}

/// Страница для [HomeRoute] для просмотра собственного профиля.
class HomeProfilePage extends HookConsumerWidget {
  const HomeProfilePage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final l18n = ref.watch(l18nProvider);
    ref.watch(playerLoadedStateProvider);

    final logExists = useFuture(
      useMemoized(() async => (await logFilePath()).existsSync()),
    );

    final bool mobileLayout = isMobileLayout(context);
    final bool recommendationsConnected =
        ref.watch(secondaryTokenProvider) != null;
    final bool spotifyConnected = ref.watch(spotifySPDCCookieProvider) != null;

    return Scaffold(
      appBar: mobileLayout
          ? AppBar(
              title: StreamBuilder<bool>(
                stream: connectivityManager.connectionChange,
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final bool isConnected = connectivityManager.hasConnection;

                  return Text(
                    isConnected
                        ? l18n.home_profilePageLabel
                        : l18n.home_profilePageLabelOffline,
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
              padding: const EdgeInsets.only(
                top: 8,
              ),
              children: [
                // Информация о текущем пользователе.
                Column(
                  children: [
                    // Аватар пользователя, при наличии.
                    if (user.photoMaxUrl != null) ...[
                      CachedNetworkImage(
                        imageUrl: user.photoMaxUrl!,
                        cacheKey: "${user.id}400",
                        placeholder: (BuildContext context, String url) {
                          return const SizedBox(
                            height: 80,
                            width: 80,
                          );
                        },
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        imageBuilder: (_, ImageProvider imageProvider) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.scaleDown,
                              ),
                            ),
                          );
                        },
                        cacheManager: CachedNetworkImagesManager.instance,
                      ),
                      const Gap(12),
                    ],

                    // Имя пользователя.
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),

                    // @domain пользователя.
                    if (user.domain != null) ...[
                      SelectableText(
                        "@${user.domain}",
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(8),
                    ],
                    const Gap(8),

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
                        l18n.home_profilePageLogout,
                      ),
                    ),
                    const Gap(8),
                  ],
                ),

                // Подключение рекомендаций.
                if (recommendationsConnected)
                  ListTile(
                    title: Text(
                      l18n.music_connectRecommendationsChipTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    subtitle: Text(
                      l18n.music_connectRecommendationsChipDescription,
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
                      builder: (context) {
                        return const ConnectRecommendationsDialog();
                      },
                    ),
                  ),
                const Gap(18),

                // Музыкальный плеер.
                ProfileSettingCategory(
                  icon: Icons.music_note,
                  title: l18n.profile_musicPlayerTitle,
                  centerTitle: mobileLayout,
                  children: [
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
                          if (enabled == null) return;

                          prefsNotifier.setDiscordRPCEnabled(enabled);
                          await player.setDiscordRPCEnabled(enabled);
                        },
                      ),

                    // Поведение при закрытии.
                    if (isDesktop)
                      SettingWithDialog(
                        icon: Icons.close,
                        title: l18n.profile_closeActionTitle,
                        subtitle: l18n.profile_closeActionDescription,
                        dialog: const CloseActionDialog(),
                        settingText: {
                          CloseBehavior.close: l18n.profile_closeActionClose,
                          CloseBehavior.minimize:
                              l18n.profile_closeActionMinimize,
                          CloseBehavior.minimizeIfPlaying:
                              l18n.profile_closeActionMinimizeIfPlaying,
                        }[preferences.closeBehavior]!,
                      ),

                    // Пауза воспроизведения при минимальной громкости.
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
                        if (enabled == null) return;

                        prefsNotifier.setStopOnPauseEnabled(enabled);
                        player.setStopOnPauseEnabled(enabled);
                      },
                    ),

                    // Предупреждение создание дубликата при сохранении.
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.copy,
                      ),
                      title: Text(
                        l18n.profile_checkBeforeFavoriteTitle,
                      ),
                      subtitle: Text(
                        l18n.profile_checkBeforeFavoriteDescription,
                      ),
                      value: preferences.checkBeforeFavorite,
                      onChanged: (bool? enabled) async {
                        if (enabled == null) return;

                        prefsNotifier.setCheckBeforeFavorite(enabled);
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
                ),
                const Gap(16),

                // Визуал.
                ProfileSettingCategory(
                  icon: Icons.color_lens,
                  title: l18n.profile_visualTitle,
                  centerTitle: mobileLayout,
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
                              if (enabled == null) return;

                              prefsNotifier.setOLEDThemeEnabled(enabled);
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
                              if (enabled == null) return;

                              prefsNotifier.setPlayerThumbAsBackground(enabled);
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
                              if (enabled == null) return;

                              prefsNotifier.setPlayerColorsAppWide(enabled);
                            }
                          : null,
                    ),

                    // Тип палитры цветов обложки.
                    SettingWithDialog(
                      icon: Icons.auto_fix_high,
                      title: l18n.profile_playerDynamicColorSchemeTypeTitle,
                      subtitle:
                          l18n.profile_playerDynamicColorSchemeTypeDescription,
                      dialog: const PlayerDynamicSchemeDialog(),
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
                  ],
                ),
                const Gap(16),

                // Экспериментальные функции.
                ProfileSettingCategory(
                  icon: Icons.science,
                  title: l18n.profile_experimentalTitle,
                  centerTitle: mobileLayout,
                  children: [
                    // Загрузка отсутсвующих обложек из Deezer.
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.image_search,
                      ),
                      title: Text(
                        l18n.profile_deezerThumbnailsTitle,
                      ),
                      subtitle: Text(
                        l18n.profile_deezerThumbnailsDescription,
                      ),
                      value: preferences.deezerThumbnails,
                      onChanged: recommendationsConnected
                          ? (bool? enabled) async {
                              if (enabled == null) return;

                              prefsNotifier.setDeezerThumbnails(enabled);
                            }
                          : null,
                    ),

                    // Тексты песен из Spotify, если авторизация не пройдена.
                    if (!spotifyConnected)
                      SettingWithDialog(
                        icon: Icons.lyrics,
                        title: l18n.profile_spotifyLyricsTitle,
                        subtitle: l18n.profile_spotifyLyricsDescription,
                        dialog: const SpotifyLyricsDialog(),
                        settingText: l18n.profile_spotifyLyricsAuthorizeButton,
                      ),

                    // Тексты песен из Spotify, если авторизация пройдена.
                    if (spotifyConnected)
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.lyrics,
                        ),
                        title: Text(
                          l18n.profile_spotifyLyricsTitle,
                        ),
                        subtitle: Text(
                          l18n.profile_spotifyLyricsDescription,
                        ),
                        value: preferences.spotifyLyrics,
                        onChanged: recommendationsConnected
                            ? (bool? enabled) async {
                                if (enabled == null) return;

                                prefsNotifier.setSpotifyLyricsEnabled(enabled);
                              }
                            : null,
                      ),

                    // Экспорт списка треков.
                    ListTile(
                      leading: const Icon(
                        Icons.my_library_music,
                      ),
                      title: Text(
                        l18n.profile_exportMusicListTitle,
                      ),
                      onTap: () => showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const ExportTracksListDialog();
                        },
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                // О приложении.
                ProfileSettingCategory(
                  icon: Icons.info,
                  title: l18n.profile_aboutTitle,
                  centerTitle: mobileLayout,
                  children: [
                    // Поделиться логами.
                    ListTile(
                      leading: const Icon(
                        Icons.bug_report,
                      ),
                      title: Text(
                        l18n.profile_shareLogsTitle,
                      ),
                      enabled: logExists.data ?? false,
                      subtitle: Text(
                        logExists.data ?? false
                            ? l18n.profile_shareLogsDescription
                            : l18n.profile_shareLogsNoLogsDescription,
                      ),
                      onTap: shareLogs,
                    ),

                    // Сбросить базу данных.
                    ListTile(
                      leading: const Icon(
                        Icons.delete,
                      ),
                      title: Text(
                        l18n.profile_resetDBTitle,
                      ),
                      subtitle: Text(
                        l18n.profile_resetDBDescription,
                      ),
                      onTap: () => showWipDialog(context),
                    ),

                    // Github.
                    ListTile(
                      leading: const Icon(
                        Icons.source,
                      ),
                      title: Text(
                        l18n.profile_githubTitle,
                      ),
                      subtitle: Text(
                        l18n.profile_githubDescription,
                      ),
                      onTap: () => launchUrl(
                        Uri.parse(repoURL),
                      ),
                    ),

                    // Политика для обновлений.
                    SettingWithDialog(
                      icon: Icons.update,
                      title: l18n.profile_updatesPolicyTitle,
                      subtitle: l18n.profile_updatesPolicyDescription,
                      dialog: const UpdatesDialogTypeActionDialog(),
                      settingText: {
                        UpdatePolicy.dialog: l18n.profile_updatesPolicyDialog,
                        UpdatePolicy.popup: l18n.profile_updatesPolicyPopup,
                        UpdatePolicy.disabled:
                            l18n.profile_updatesPolicyDisabled,
                      }[preferences.updatePolicy]!,
                    ),

                    // Канал для автообновлений.
                    SettingWithDialog(
                      icon: Icons.route,
                      title: l18n.profile_updatesBranchTitle,
                      subtitle: l18n.profile_updatesBranchDescription,
                      dialog: const UpdatesChannelDialog(),
                      enabled:
                          preferences.updatePolicy != UpdatePolicy.disabled,
                      settingText: {
                        UpdateBranch.releasesOnly:
                            l18n.profile_updatesBranchReleases,
                        UpdateBranch.prereleases:
                            l18n.profile_updatesBranchPrereleases,
                      }[preferences.updateBranch]!,
                    ),

                    // Версия приложения (и проверка текущей версии).
                    ListTile(
                      leading: const Icon(
                        Icons.info,
                      ),
                      title: Text(
                        l18n.profile_appVersionTitle,
                      ),
                      subtitle: Text(
                        l18n.profile_appVersionDescription("v$appVersion"),
                      ),
                      onTap: () {
                        if (!networkRequiredDialog(ref, context)) return;

                        Updater.checkForUpdates(
                          context,
                          allowPre: preferences.updateBranch ==
                              UpdateBranch.prereleases,
                          showLoadingOverlay: true,
                          showMessageOnNoUpdates: true,
                        );
                      },
                    ),
                  ],
                ),
                const Gap(16),

                // Debug-опции.
                if (kDebugMode) ...[
                  ProfileSettingCategory(
                    icon: Icons.logo_dev,
                    title: "Debugging options",
                    centerTitle: mobileLayout,
                    children: [
                      // Кнопка для копирования ID пользователя.
                      ListTile(
                        leading: const Icon(
                          Icons.person,
                        ),
                        title: const Text(
                          "Copy user ID",
                        ),
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: user.id.toString(),
                            ),
                          );
                        },
                      ),

                      // Кнопка для копирования Kate Mobile токена.
                      ListTile(
                        leading: const Icon(
                          Icons.key,
                        ),
                        title: const Text(
                          "Copy main token",
                        ),
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: ref.read(tokenProvider)!,
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
                          "Copy secondary token",
                        ),
                        enabled: recommendationsConnected,
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: ref.read(secondaryTokenProvider)!,
                            ),
                          );
                        },
                      ),

                      // Debug-меню для тестирования ColorScheme.
                      ListTile(
                        leading: const Icon(
                          Icons.palette,
                        ),
                        title: const Text(
                          "ColorScheme test menu",
                        ),
                        onTap: () => Navigator.of(context).push(
                          Material3PageRoute(
                            builder: (BuildContext context) {
                              return const ColorSchemeDebugMenu();
                            },
                          ),
                        ),
                      ),

                      // Debug-меню для отображения всех плейлистов.
                      ListTile(
                        leading: const Icon(
                          Icons.art_track_outlined,
                        ),
                        title: const Text(
                          "Playlists viewer",
                        ),
                        onTap: () => Navigator.of(context).push(
                          Material3PageRoute(
                            builder: (BuildContext context) {
                              return const PlaylistsViewerDebugMenu();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                ],

                // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
                if (player.loaded && mobileLayout)
                  const Gap(mobileMiniPlayerHeight),
              ],
            ),
          ),

          // Данный Gap нужен, что бы плеер снизу при Desktop Layout'е не закрывал ничего важного.
          // Мы его располагаем после ListView, что бы ScrollBar не был закрыт плеером.
          if (player.loaded && !mobileLayout)
            const Gap(desktopMiniPlayerHeight),
        ],
      ),
    );
  }
}
