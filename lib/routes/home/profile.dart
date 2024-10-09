import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:share_plus/share_plus.dart";
import "package:url_launcher/url_launcher.dart";

import "../../consts.dart";
import "../../enums.dart";
import "../../main.dart";
import "../../provider/auth.dart";
import "../../provider/download_manager.dart";
import "../../provider/l18n.dart";
import "../../provider/player_events.dart";
import "../../provider/preferences.dart";
import "../../provider/updater.dart";
import "../../provider/user.dart";
import "../../provider/vk_api.dart";
import "../../services/cache_manager.dart";
import "../../services/logger.dart";
import "../../utils.dart";
import "../../widgets/audio_player.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/fallback_user_avatar.dart";
import "../../widgets/isolated_cached_network_image.dart";
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

  /// [Padding] для [children] внутри виджета [Card].
  final EdgeInsetsGeometry padding;

  /// Содержимое этой категории.
  final List<Widget> children;

  const ProfileSettingCategory({
    super.key,
    required this.icon,
    required this.title,
    this.centerTitle = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 14,
    ),
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final Widget titleWidget = Row(
      mainAxisSize: centerTitle ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // Разделитель.
        if (centerTitle)
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Divider(),
            ),
          ),

        // Иконка.
        if (!centerTitle) const Gap(16),
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const Gap(12),

        // Название категории.
        SelectionContainer.disabled(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Разделитель.
        if (centerTitle)
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Divider(),
            ),
          ),
      ],
    );

    return Column(
      children: [
        // Иконка и название вне Card.
        if (centerTitle) ...[
          titleWidget,
          const Gap(20),
        ],

        // Внутреннее содержимое.
        ClipRRect(
          borderRadius: BorderRadius.circular(
            globalBorderRadius,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                globalBorderRadius,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка и название, располагаемые внутри Card.
                if (!centerTitle) ...[
                  const Gap(14),
                  titleWidget,
                ],

                // Содержимое.
                Padding(
                  padding: padding,
                  child: Column(
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

/// Виджет для [HomeProfilePage], отображающий предупреждение о том, что рекомендации не подключены.
class ProfileRecommendationsWarning extends ConsumerWidget {
  const ProfileRecommendationsWarning({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
      ),
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (context) {
            return const ConnectRecommendationsDialog();
          },
        ),
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            16,
          ),
          child: Row(
            children: [
              // Иконка.
              Icon(
                Icons.auto_fix_high,
                color: Theme.of(context).colorScheme.primary,
              ),
              const Gap(12),

              // Содержимое.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Рекомендации не подключены".
                    Text(
                      l18n.profile_recommendationsNotConnectedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(4),

                    // "Рекомендации не подключены".
                    Text(
                      l18n.profile_recommendationsNotConnectedDescription,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет для [HomeProfilePage], отображающий аватар пользователя, а так же кнопку для выхода из аккаунта.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final user = ref.watch(userProvider);

    void onLogoutPressed() => showDialog(
          context: context,
          builder: (context) => const ProfileLogoutExitDialog(),
        );

    return Column(
      children: [
        // Аватар пользователя, при наличии.
        if (user.photoMaxUrl != null)
          IsolatedCachedImage(
            imageUrl: user.photoMaxUrl!,
            cacheKey: "${user.id}400",
            memCacheWidth: 80 * MediaQuery.of(context).devicePixelRatio.toInt(),
            memCacheHeight:
                80 * MediaQuery.of(context).devicePixelRatio.toInt(),
            cacheManager: CachedNetworkImagesManager.instance,
            placeholder: const UserAvatarPlaceholder(),
            imageBuilder: (_, imageProvider) {
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
          )
        else
          const UserAvatarPlaceholder(),
        const Gap(12),

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
                  fontWeight: FontWeight.w400,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(8),
        ],
        const Gap(8),

        // Выход из аккаунта.
        FilledButton.tonalIcon(
          onPressed: onLogoutPressed,
          icon: const Icon(
            Icons.logout,
          ),
          label: Text(
            l18n.home_profilePageLogout,
          ),
        ),
      ],
    );
  }
}

/// Страница для [HomeRoute] для просмотра собственного профиля.
class HomeProfilePage extends HookConsumerWidget {
  static final AppLogger logger = getLogger("HomeProfilePage");

  const HomeProfilePage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final user = ref.watch(userProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);
    final downloadManager = ref.watch(downloadManagerProvider);
    ref.watch(playerLoadedStateProvider);

    final logExists = useFuture(
      useMemoized(() async => (await logFilePath()).existsSync()),
    );

    final bool mobileLayout = isMobileLayout(context);
    final bool recommendationsConnected =
        ref.watch(secondaryTokenProvider) != null;
    final EdgeInsets settingsPadding = EdgeInsets.only(
      top: mobileLayout ? 0 : 8,
    );

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
              actions: [
                // Кнопка для менеджера загрузок.
                if (downloadManager.downloadStarted)
                  IconButton(
                    onPressed: () => context.go("/profile/downloadManager"),
                    icon: const Icon(
                      Icons.download,
                    ),
                  ),
                const Gap(16),
              ],
              centerTitle: true,
            )
          : null,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(
                mobileLayout ? 16 : 24,
              ).copyWith(
                bottom: 0,
              ),
              children: [
                // Информация о текущем пользователе.
                const ProfileAvatar(),
                const Gap(18),

                // Блок, предупреждающий пользователя о том, что рекомендации не подключены.
                if (!recommendationsConnected) ...[
                  const ProfileRecommendationsWarning(),
                  const Gap(18),
                ],

                // Визуал.
                ProfileSettingCategory(
                  icon: Icons.color_lens,
                  title: l18n.profile_visualTitle,
                  centerTitle: mobileLayout,
                  padding: settingsPadding,
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
                      subtitle:
                          l18n.profile_playerDynamicColorSchemeTypeDescription,
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

                                prefsNotifier
                                    .setAlternateDesktopMiniplayerSlider(
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
                  ],
                ),
                const Gap(16),

                // Музыкальный плеер.
                ProfileSettingCategory(
                  icon: Icons.music_note,
                  title: l18n.profile_musicPlayerTitle,
                  centerTitle: mobileLayout,
                  padding: settingsPadding,
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
                          CloseBehavior.minimize:
                              l18n.profile_closeActionMinimize,
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
                        RewindBehavior.always:
                            l18n.profile_rewindOnPreviousAlways,
                        RewindBehavior.onlyViaUI:
                            l18n.profile_rewindOnPreviousOnlyViaUI,
                        RewindBehavior.onlyViaNotification:
                            l18n.profile_rewindOnPreviousOnlyViaNotification,
                        RewindBehavior.disabled:
                            l18n.profile_rewindOnPreviousDisabled,
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
                ),
                const Gap(16),

                // Экспериментальные функции.
                ProfileSettingCategory(
                  icon: Icons.science,
                  title: l18n.profile_experimentalTitle,
                  centerTitle: mobileLayout,
                  padding: settingsPadding,
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
                              HapticFeedback.lightImpact();
                              if (enabled == null) return;

                              prefsNotifier.setDeezerThumbnails(enabled);
                            }
                          : null,
                    ),

                    // Тексты песен через LRCLIB.
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.lyrics_outlined,
                      ),
                      title: Text(
                        l18n.profile_LRCLibLyricsTitle,
                      ),
                      subtitle: Text(
                        l18n.profile_LRCLibLyricsDescription,
                      ),
                      value: preferences.lrcLibEnabled,
                      onChanged: (bool? enabled) async {
                        HapticFeedback.lightImpact();
                        if (enabled == null) return;

                        prefsNotifier.setLRCLIBEnabled(enabled);
                      },
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

                // О Flutter VK.
                ProfileSettingCategory(
                  icon: Icons.info,
                  title: l18n.profile_aboutTitle,
                  centerTitle: mobileLayout,
                  padding: settingsPadding,
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
                        UpdateBranch.preReleases:
                            l18n.profile_updatesBranchPrereleases,
                      }[preferences.updateBranch]!,
                    ),

                    // Список изменений этой версии.
                    ListTile(
                      leading: const Icon(
                        Icons.article,
                      ),
                      title: Text(
                        l18n.profile_showChangelogTitle,
                      ),
                      subtitle: Text(
                        l18n.profile_showChangelogDescription,
                      ),
                      onTap: () async {
                        if (!networkRequiredDialog(ref, context)) return;

                        await ref.read(updaterProvider).showChangelog(
                              context,
                              showLoadingOverlay: true,
                            );
                      },
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
                        l18n.profile_appVersionDescription(
                          "v$appVersion${kDebugMode ? " (Debug)" : isPrerelease ? " (${l18n.profile_appVersionPreRelease})" : ""}",
                        ),
                      ),
                      onTap: () async {
                        if (!networkRequiredDialog(ref, context)) return;

                        await ref.read(updaterProvider).checkForUpdates(
                              context,
                              allowPre: preferences.updateBranch ==
                                  UpdateBranch.preReleases,
                              showLoadingOverlay: true,
                              showMessageOnNoUpdates: true,
                            );
                      },
                    ),
                  ],
                ),
                const Gap(16),

                // Debug-опции.
                if (kDebugMode || preferences.debugOptionsEnabled) ...[
                  ProfileSettingCategory(
                    icon: Icons.logo_dev,
                    title: "Debugging options",
                    centerTitle: mobileLayout,
                    padding: settingsPadding,
                    children: [
                      // Информация о том, что данный раздел показан поскольку включен режим отладки.
                      Padding(
                        padding: const EdgeInsets.all(
                          24,
                        ),
                        child: Text(
                          kDebugMode
                              ? "Those options are shown because the app is running in debug mode."
                              : "This section is shown because \"force-show debug\" is enabled in settings.\nNormally, this section is hidden in non-debug modes.",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),

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
                        onTap: () => context.push("/profile/colorSchemeDebug"),
                      ),

                      // Debug-меню для отображения всех плейлистов.
                      ListTile(
                        leading: const Icon(
                          Icons.art_track_outlined,
                        ),
                        title: const Text(
                          "Playlists viewer",
                        ),
                        onTap: () =>
                            context.push("/profile/playlistsViewerDebug"),
                      ),

                      // Debug-меню для отображения Markdown-разметки.
                      ListTile(
                        leading: const Icon(
                          Icons.article,
                        ),
                        title: const Text(
                          "Markdown viewer",
                        ),
                        onTap: () =>
                            context.push("/profile/markdownViewerDebug"),
                      ),

                      // Кнопка для запуска фейковой загрузки.
                      ListTile(
                        leading: const Icon(
                          Icons.update,
                        ),
                        title: const Text(
                          "Force-trigger update dialog",
                        ),
                        onTap: () => ref.read(updaterProvider).checkForUpdates(
                              context,
                              allowPre: true,
                              showLoadingOverlay: true,
                              showMessageOnNoUpdates: true,
                              disableCurrentVersionCheck: true,
                            ),
                      ),

                      // Кнопка для открытия экрана загрузок.
                      ListTile(
                        leading: const Icon(
                          Icons.download,
                        ),
                        title: const Text(
                          "Open download manager",
                        ),
                        onTap: () => context.go("/profile/downloadManager"),
                      ),

                      // Кнопка для создания тестового API-запроса.
                      ListTile(
                        leading: const Icon(
                          Icons.speed,
                        ),
                        title: const Text(
                          "API call test",
                        ),
                        onTap: () async {
                          if (!networkRequiredDialog(ref, context)) return;

                          final totalStopwatch = Stopwatch()..start();

                          final List<int> times = [];
                          for (int i = 0; i < 10; i++) {
                            final stopwatch = Stopwatch()..start();
                            await ref
                                .read(vkAPIProvider)
                                .execute
                                .massGetAudio(user.id);
                            stopwatch.stop();

                            times.add(stopwatch.elapsedMilliseconds);
                          }

                          totalStopwatch.stop();
                          final String printString =
                              "Time took: ${totalStopwatch.elapsedMilliseconds}ms, avg: ${times.reduce((a, b) => a + b) ~/ times.length}ms, times: ${times.join(", ")}";
                          logger.d(printString);

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                printString,
                              ),
                            ),
                          );
                        },
                      ),

                      // Включение отладочного режима.
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.developer_mode,
                        ),
                        title: const Text(
                          "Force-show debug",
                        ),
                        subtitle: const Text(
                          "Shows debugging options in profile even in non-debug modes",
                        ),
                        value: preferences.debugOptionsEnabled,
                        onChanged: (bool? enabled) async {
                          HapticFeedback.lightImpact();
                          if (enabled == null) return;

                          prefsNotifier.setDebugOptionsEnabled(enabled);
                        },
                      ),
                    ],
                  ),
                  const Gap(16),
                ],

                // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
                if (player.loaded && mobileLayout)
                  const Gap(MusicPlayerWidget.mobileHeightWithPadding),
              ],
            ),
          ),

          // Данный Gap нужен, что бы плеер снизу при Desktop Layout'е не закрывал ничего важного.
          // Мы его располагаем после ListView, что бы ScrollBar не был закрыт плеером.
          if (player.loaded && !mobileLayout)
            const Gap(MusicPlayerWidget.desktopMiniPlayerHeight),
        ],
      ),
    );
  }
}
