import "dart:async";
import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:share_plus/share_plus.dart";
import "package:url_launcher/url_launcher.dart";

import "../../consts.dart";
import "../../enums.dart";
import "../../main.dart";
import "../../provider/auth.dart";
import "../../provider/l18n.dart";
import "../../provider/preferences.dart";
import "../../provider/spotify_api.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
import "../../services/logger.dart";
import "../../services/updater.dart";
import "../../utils.dart";
import "../../widgets/dialogs.dart";
import "../../widgets/page_route_builders.dart";
import "profile/color_debug_menu.dart";
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

/// Страница для [HomeRoute] для просмотра собственного профиля.
class HomeProfilePage extends ConsumerStatefulWidget {
  const HomeProfilePage({
    super.key,
  });

  @override
  ConsumerState<HomeProfilePage> createState() => _HomeProfilePageState();
}

class _HomeProfilePageState extends ConsumerState<HomeProfilePage> {
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
        (_) => setState(() {}),
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
    final bool isMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;
    final user = ref.watch(userProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final preferences = ref.watch(preferencesProvider);

    final bool recommendationsConnected =
        ref.watch(secondaryTokenProvider) != null;
    final bool spotifyConnected = ref.watch(spotifySPDCCookieProvider) != null;

    final l18n = ref.watch(l18nProvider);

    return Scaffold(
      // appBar: isMobileLayout
      //     ? AppBar(
      //         title: StreamBuilder<bool>(
      //           stream: connectivityManager.connectionChange,
      //           builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
      //             final bool isConnected = connectivityManager.hasConnection;

      //             return Text(
      //               isConnected
      //                   ? l18n.home_profilePageLabel
      //                   : l18n
      //                       .home_profilePageLabelOffline,
      //             );
      //           },
      //         ),
      //         centerTitle: true,
      //       )
      //     : null,
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
                            cacheKey: "${user.id}400",
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
                        user.fullName,
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
                                        .onSurface
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
                          l18n.home_profilePageLogout,
                        ),
                      ),
                    ],
                  ),
                ),

                // Подключение рекомендаций.
                if (!recommendationsConnected)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: ListTile(
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
                                  l18n.profile_musicPlayerTitle,
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
                            ListTile(
                              leading: const Icon(
                                Icons.close,
                              ),
                              title: Text(
                                l18n.profile_closeActionTitle,
                              ),
                              subtitle: Text(
                                l18n.profile_closeActionDescription,
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
                                          CloseBehavior.close:
                                              l18n.profile_closeActionClose,
                                          CloseBehavior.minimize:
                                              l18n.profile_closeActionMinimize,
                                          CloseBehavior
                                              .minimizeIfPlaying: AppLocalizations
                                                  .of(
                                            context,
                                          )!
                                              .profile_closeActionMinimizeIfPlaying,
                                        }[preferences.closeBehavior]!,
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
                                  l18n.profile_visualTitle,
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
                              l18n.profile_themeTitle,
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
                                            l18n.profile_themeSystem,
                                        ThemeMode.light:
                                            l18n.profile_themeLight,
                                        ThemeMode.dark: l18n.profile_themeDark,
                                      }[preferences.theme]!,
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
                              l18n.profile_oledThemeTitle,
                            ),
                            subtitle: Text(
                              l18n.profile_oledThemeDescription,
                            ),
                            value: preferences.oledTheme,
                            onChanged: (bool? enabled) async {
                              if (enabled == null) return;

                              prefsNotifier.setOLEDThemeEnabled(enabled);
                            },
                          ),

                          // Использование изображения трека для фона в полноэкранном плеере.
                          SwitchListTile(
                            secondary: const Icon(
                              Icons.photo_filter,
                            ),
                            title: Text(
                              l18n.profile_useThumbnailAsBackgroundTitle,
                            ),
                            subtitle: Text(
                              l18n.profile_useThumbnailAsBackgroundDescription,
                            ),
                            value: preferences.playerThumbAsBackground,
                            onChanged: recommendationsConnected
                                ? (bool? enabled) async {
                                    if (enabled == null) return;

                                    prefsNotifier
                                        .setPlayerThumbAsBackground(enabled);
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

                                    prefsNotifier
                                        .setPlayerColorsAppWide(enabled);
                                  }
                                : null,
                          ),

                          // Тип палитры цветов обложки.
                          ListTile(
                            leading: const Icon(
                              Icons.auto_fix_high,
                            ),
                            title: Text(
                              l18n.profile_playerDynamicColorSchemeTypeTitle,
                            ),
                            subtitle: Text(
                              l18n.profile_playerDynamicColorSchemeTypeDescription,
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  const PlayerDynamicSchemeDialog(),
                            ),
                            trailing: !isMobileLayout
                                ? FilledButton(
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          const PlayerDynamicSchemeDialog(),
                                    ),
                                    child: Text(
                                      {
                                        DynamicSchemeType.tonalSpot: l18n
                                            .profile_playerDynamicColorSchemeTonalSpot,
                                        DynamicSchemeType.neutral: l18n
                                            .profile_playerDynamicColorSchemeNeutral,
                                        DynamicSchemeType.content: l18n
                                            .profile_playerDynamicColorSchemeContent,
                                        DynamicSchemeType.monochrome: l18n
                                            .profile_playerDynamicColorSchemeMonochrome,
                                      }[preferences.dynamicSchemeType]!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : null,
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
                                  l18n.profile_experimentalTitle,
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
                            ListTile(
                              leading: const Icon(
                                Icons.lyrics,
                              ),
                              title: Text(
                                l18n.profile_spotifyLyricsTitle,
                              ),
                              subtitle: Text(
                                l18n.profile_spotifyLyricsDescription,
                              ),
                              onTap: recommendationsConnected
                                  ? () => showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return const SpotifyLyricsDialog();
                                        },
                                      )
                                  : null,
                              trailing: !isMobileLayout
                                  ? FilledButton(
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return const SpotifyLyricsDialog();
                                        },
                                      ),
                                      child: Text(
                                        l18n.profile_spotifyLyricsAuthorizeButton,
                                      ),
                                    )
                                  : null,
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

                                      prefsNotifier
                                          .setSpotifyLyricsEnabled(enabled);
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
                                  l18n.profile_aboutTitle,
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
                                  l18n.profile_shareLogsTitle,
                                ),
                                enabled: exists,
                                subtitle: Text(
                                  exists
                                      ? l18n.profile_shareLogsDescription
                                      : l18n.profile_shareLogsNoLogsDescription,
                                ),
                                onTap: shareLogs,
                              );
                            },
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
                            onTap: () async {
                              // final UserProvider user =
                              //     Provider.of<UserProvider>(
                              //   context,
                              //   listen: false,
                              // );
                              final bool result = await showDialog(
                                    context: context,
                                    builder: (context) => const ResetDBDialog(),
                                  ) ??
                                  false;

                              if (!result) return;

                              getLogger("ProfileResetDB")
                                  .i("User requested DB reset");

                              // Если плеер играет, то останаливаем его.
                              if (player.loaded) {
                                await player.stop();
                              }

                              // Очищаем базу данных.
                              await appStorage.resetDB();

                              // //TODO: Удаляем плейлисты пользователя.
                              // user.allPlaylists = {};
                            },
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
                              l18n.profile_updatesPolicyTitle,
                            ),
                            subtitle: Text(
                              l18n.profile_updatesPolicyDescription,
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
                                            l18n.profile_updatesPolicyDialog,
                                        UpdatePolicy.popup:
                                            l18n.profile_updatesPolicyPopup,
                                        UpdatePolicy.disabled:
                                            l18n.profile_updatesPolicyDisabled,
                                      }[preferences.updatePolicy]!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : null,
                          ),

                          // Канал для автообновлений.
                          ListTile(
                            enabled: preferences.updatePolicy !=
                                UpdatePolicy.disabled,
                            leading: const Icon(
                              Icons.route,
                            ),
                            title: Text(
                              l18n.profile_updatesBranchTitle,
                            ),
                            subtitle: Text(
                              l18n.profile_updatesBranchDescription,
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
                                            l18n.profile_updatesBranchReleases,
                                        UpdateBranch.prereleases: l18n
                                            .profile_updatesBranchPrereleases,
                                      }[preferences.updateBranch]!,
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
                              l18n.profile_appVersionTitle,
                            ),
                            subtitle: Text(
                              l18n.profile_appVersionDescription(
                                "v$appVersion",
                              ),
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
                                  builder: (BuildContext context) =>
                                      const ColorSchemeDebugMenu(),
                                ),
                              ),
                            ),

                            // Debug-тест.
                            ListTile(
                              leading: const Icon(
                                Icons.bug_report,
                              ),
                              title: const Text(
                                "DEBUG-test",
                              ),
                              onTap: () async {
                                // No-op.
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
