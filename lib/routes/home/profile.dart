import "dart:async";
import "dart:convert";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";
import "package:url_launcher/url_launcher.dart";

import "../../api/vk/shared.dart";
import "../../consts.dart";
import "../../enums.dart";
import "../../main.dart";
import "../../provider/user.dart";
import "../../services/cache_manager.dart";
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

  @override
  void initState() {
    super.initState();

    subscriptions = [
      // Изменения запуска плеера.
      player.loadedStateStream.listen(
        (bool loaded) => setState(() {}),
      ),
    ];
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
                          placeholder: (BuildContext context, String url) {
                            return const SizedBox(
                              height: 80,
                              width: 80,
                            );
                          },
                          placeholderFadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
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
                      String jsondata =
                          """{"response":[{"id":477717529,"nickname":"","domain":"dolbonat.crocodile","bdate":"9.5","city":{"id":5095451,"title":"Twin Peaks"},"country":{"id":9,"title":"США"},"photo_200":"https://sun2-17.userapi.com/s/v1/ig2/-rObrrC_QagHYJxIRBMi4BprFgESNe3_ZvOfXHGw8hudqtho2FiQM3PSIYIz6ZS8sKx_bnKUJ2yF-vg4onJEpLBR.jpg?size=200x200&quality=95&crop=0,86,957,957&ava=1","photo_max":"https://sun2-17.userapi.com/s/v1/ig2/hXA7hEbM560omcdZ39p1AjgGqfpIHmyE1VH_l-o3UwzLEMQGQysTzl0Xx_8tyyvWD6-Ucl2kijSm3m9S_hjwMrUa.jpg?size=400x400&quality=95&crop=0,86,957,957&ava=1","photo_200_orig":"https://sun2-17.userapi.com/s/v1/ig2/-rObrrC_QagHYJxIRBMi4BprFgESNe3_ZvOfXHGw8hudqtho2FiQM3PSIYIz6ZS8sKx_bnKUJ2yF-vg4onJEpLBR.jpg?size=200x200&quality=95&crop=0,86,957,957&ava=1","photo_400_orig":"https://sun2-17.userapi.com/s/v1/ig2/hXA7hEbM560omcdZ39p1AjgGqfpIHmyE1VH_l-o3UwzLEMQGQysTzl0Xx_8tyyvWD6-Ucl2kijSm3m9S_hjwMrUa.jpg?size=400x400&quality=95&crop=0,86,957,957&ava=1","photo_max_orig":"https://sun2-17.userapi.com/s/v1/ig2/hXA7hEbM560omcdZ39p1AjgGqfpIHmyE1VH_l-o3UwzLEMQGQysTzl0Xx_8tyyvWD6-Ucl2kijSm3m9S_hjwMrUa.jpg?size=400x400&quality=95&crop=0,86,957,957&ava=1","photo_id":"477717529_457265348","has_photo":1,"has_mobile":1,"is_friend":0,"can_post":1,"can_see_all_posts":1,"can_see_audio":0,"interests":"","books":"","tv":"","quotes":"","about":"","games":"","movies":"","activities":"","music":"","can_write_private_message":1,"can_send_friend_request":1,"can_be_invited_group":true,"mobile_phone":"","home_phone":"","site":"","status":"добро пожаловать в гости на званый ужин","last_seen":{"platform":1,"time":1709366789},"crop_photo":{"photo":{"album_id":-6,"date":1683133585,"id":457265348,"owner_id":477717529,"sizes":[{"height":75,"type":"s","width":56,"url":"https://sun9-36.userapi.com/impg/AGh5gEfoI6emawYfmNu-rnAQY0A5z9D7L-EC3w/-Qvgm0O4qN0.jpg?size=56x75&quality=95&sign=255c83a7bf13f473b2a8c3f7586ee73d&c_uniq_tag=pyV8kM31xg4Tb85A_eoDGH-kky_5TYVWlkzk1hfUwPY&type=album"},{"height":130,"type":"m","width":97,"url":"https://sun9-36.userapi.com/impg/AGh5gEfoI6emawYfmNu-rnAQY0A5z9D7L-EC3w/-Qvgm0O4qN0.jpg?size=97x130&quality=95&sign=91e022f241b86e01524bb2375d1f5aa6&c_uniq_tag=VS5tRfLh3Yv-CzFaM0EsPIsjTU1PvaR0dyadYCqVUoY&type=album"},{"height":604,"type":"x","width":453,"url":"https://sun9-36.userapi.com/impg/AGh5gEfoI6emawYfmNu-rnAQY0A5z9D7L-EC3w/-Qvgm0O4qN0.jpg?size=453x604&quality=95&sign=569e388832661d0a18c698a4c347c020&c_uniq_tag=Fv9DR9ZWubsRtWKIV_XQkQUblMVe9EvjyXmN7GBp06k&type=album"},{"height":807,"type":"y","width":605,"url":"https://sun9-36.userapi.com/impg/AGh5gEfoI6emawYfmNu-rnAQY0A5z9D7L-EC3w/-Qvgm0O4qN0.jpg?size=605x807&quality=95&sign=02ce4f3083fcf2a4405041e5e0d81af5&c_uniq_tag=YtNXbz7O2i2ex1vOX8awx6ID1pdDzIsF7N6EkwPmX3Y&type=album"},{"height":1080,"type":"z","width":810,"url":"https://sun9-36.userapi.com/impg/AGh5gEfoI6emawYfmNu-rnAQY0A5z9D7L-EC3w/-Qvgm0O4qN0.jpg?size=810x1080&quality=95&sign=e02665b7a6febe2938bf23a011c7ebfa&c_uniq_tag=ONbp--K6VSyRyjsylZywofyrHiWMqOsk0aRUp1MLps8&type=album"},{"height":1280,"type":"w","width":960,"url":"https://sun9-36.userapi.com/impg/AGh5gEfoI6emawYfmNu-rnAQY0A5z9D7L-EC3w/-Qvgm0O4qN0.jpg?size=960x1280&quality=95&sign=7530973dd4fe8daa4e84fd7bcdf5fa6e&c_uniq_tag=Qzan0r5mAAKsNbddLpcChizeftg26qzFbQ7WmPW6FrA&type=album"},{"height":173,"type":"o","width":130,"url":"https://sun9-36.userapi.com/impg/AGh5gEfoI6emawYfmNu-rnAQY0A5z9D7L-EC3w/-Qvgm0O4qN0.jpg?size=130x173&quality=95&sign=359b3976e53aa7df23c29bc59d712694&c_uniq_tag=R-lSnecyhrj6OhYtwn2E5gnSkewUU6xD272Qb5TnqAw&type=album"},{"height":267,"type":"p","width":200,"url":"https://sun9-36.userapi.com/impg/AGh5gEfoI6emawYfmNu-rnAQY0A5z9D7L-EC3w/-Qvgm0O4qN0.jpg?size=200x267&quality=95&sign=1dc27badf9ea60c488c8b3e15955db6e&c_uniq_tag=bsnVY0Ekbmsmlzur961WRFgc8VCRxp7zK_1a753tU7w&type=album"},{"height":427,"type":"q","width":320,"url":"https://sun9-36.userapi.com/impg/AGh5gEfoI6emawYfmNu-rnAQY0A5z9D7L-EC3w/-Qvgm0O4qN0.jpg?size=320x427&quality=95&sign=c89f419fd8e33895dddd54b63faba957&c_uniq_tag=8bRtanfDE0CrVZLjlX1BsYjBe-hFtXK67j7vcPU7n-8&type=album"},{"height":680,"type":"r","width":510,"url":"https://sun9-36.userapi.com/impg/AGh5gEfoI6emawYfmNu-rnAQY0A5z9D7L-EC3w/-Qvgm0O4qN0.jpg?size=510x680&quality=95&sign=21a4e12dd7ee76b8a378e9891348518c&c_uniq_tag=b6rd2jSEexQqwPu5A7gccjbsT4ZkemMGN3CuiDb_-18&type=album"}],"square_crop":"0,86,957","text":"","web_view_token":"b1d65f5bddeabe2f69","has_tags":false},"crop":{"x":0,"y":6.72,"x2":99.69,"y2":81.48},"rect":{"x":0,"y":0,"x2":100,"y2":100}},"followers_count":152,"blacklisted":0,"blacklisted_by_me":0,"is_favorite":0,"is_hidden_from_feed":0,"common_count":3,"occupation":{"id":555,"name":"ВятГУ (бывш. ВятГТУ, КирПИ)","type":"university","country_id":1,"city_id":66},"career":[],"military":[],"university":555,"university_name":"ВятГУ (бывш. ВятГТУ, КирПИ)","faculty":2218302,"faculty_name":"Факультет компьютерных и физико-математических наук (Институт математики и информационных систем)","graduation":0,"education_form":"Очное отделение","education_status":"Студент (бакалавр)","home_town":"","relation":0,"personal":{"alcohol":0,"inspired_by":"","langs":["Русский"],"langs_full":[{"id":0,"native_name":"Русский"}],"life_main":0,"people_main":0,"smoking":0},"universities":[{"chair":2036250,"chair_name":"Математика и компьютерные науки","city":66,"country":9,"education_form":"Очное отделение","education_form_id":1,"education_status":"Студент (бакалавр)","education_status_id":3,"faculty":2218302,"faculty_name":"Факультет компьютерных и физико-математических наук (Институт математики и информационных систем)","id":555,"name":"ВятГУ (бывш. ВятГТУ, КирПИ)"}],"schools":[],"relatives":[],"sex":2,"screen_name":"dolbonat.crocodile","photo_50":"https://sun2-17.userapi.com/s/v1/ig2/CL-YU14TLVtBZGcPZUaVyuLm6fZCRxqBX9tKeU476A43S4QeFrGF5aumtEZwfRAWSDNIPzQSdg6r3uLgnzGS10DK.jpg?size=50x50&quality=95&crop=0,86,957,957&ava=1","photo_100":"https://sun2-17.userapi.com/s/v1/ig2/0XxxWpj-q6jBVOqG5ap9-GmxEw5xAO6GxlxHVY2t-RpMUS2nvgkItKz4h2c27Q2g5064aPYIire6QIWnhtMPtqn3.jpg?size=100x100&quality=95&crop=0,86,957,957&ava=1","online":1,"online_mobile":1,"online_app":2685278,"verified":0,"friend_status":0,"first_name":"Кирилл","last_name":"Комаровских","can_access_closed":true,"is_closed":false}]}""";
                      User.fromJson(jsonDecode(jsondata)["response"][0]);

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
