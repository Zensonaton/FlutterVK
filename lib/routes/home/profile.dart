import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:provider/provider.dart";
import "package:responsive_builder/responsive_builder.dart";

import "../../main.dart";
import "../../provider/user.dart";
import "../../widgets/page_route.dart";
import "../../widgets/wip_dialog.dart";
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
    Key? key,
  }) : super(
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context, listen: false);

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.logout_outlined,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              AppLocalizations.of(context)!.home_profilePageLogoutTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.home_profilePageLogoutDescription(
                user.fullName!,
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                )
              ],
            )
          ],
        ),
      ),
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
    Key? key,
  }) : super(
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_fix_high,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              AppLocalizations.of(context)!.music_ConnectRecommendationsTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!
                  .music_ConnectRecommendationsDescription,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                    AppLocalizations.of(context)!
                        .music_ConnectRecommendationsConnect,
                  ),
                )
              ],
            )
          ],
        ),
      ),
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
  @override
  Widget build(BuildContext context) {
    final UserProvider user = Provider.of<UserProvider>(context);

    final bool isMobileLayout =
        getDeviceType(MediaQuery.of(context).size) == DeviceScreenType.mobile;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: ListView(
            children: [
              if (user.photoMaxUrl != null)
                // TODO: Сделать скругление аватара.
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CachedNetworkImage(
                    imageUrl: user.photoMaxUrl!,
                    width: 80,
                    height: 80,
                  ),
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
              if (user.photoMaxUrl != null)
                const SizedBox(
                  height: 24,
                ),
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
                    builder: (context) => const ConnectRecommendationsDialog(),
                  ),
                ),
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.profile_discordRPCTitle,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.profile_discordRPCDescription,
                ),
                leading: const Icon(
                  Icons.discord,
                ),
                trailing: Switch(
                  onChanged: (bool? enabled) async {
                    if (enabled == null) return;

                    user.settings.discordRPCEnabled = enabled;
                    await player.setDiscordRPCEnabled(enabled);

                    user.markUpdated();
                    setState(() {});
                  },
                  value: player.discordRPCEnabled,
                ),
              ),
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.profile_exportMusicThumbsTitle,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!
                      .profile_exportMusicThumbsDescription,
                ),
                leading: const Icon(
                  Icons.photo_library_outlined,
                ),
                onTap: () => showWipDialog(context),
              ),
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.profile_importMusicThumbsTitle,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!
                      .profile_importMusicThumbsDescription,
                ),
                leading: const Icon(
                  Icons.photo_library,
                ),
                onTap: () => showWipDialog(context),
              ),
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.profile_musicNormalizationTitle,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!
                      .profile_musicNormalizationDescription,
                ),
                leading: const Icon(
                  Icons.multitrack_audio,
                ),
                trailing: Switch(
                  onChanged: (bool? enabled) async {
                    if (enabled == null) return;

                    await player.setAudioNormalization(enabled);
                    setState(() {});
                  },
                  value: player.normalizationEnabled,
                ),
              ),
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!
                      .profile_volumeMusicPauseTimerTitle,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!
                      .profile_volumeMusicPauseTimerDescription,
                ),
                leading: const Icon(
                  Icons.timer,
                ),
                trailing: const Switch(
                  onChanged: null,
                  value: false,
                ),
              ),
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.profile_exportMusicListTitle,
                ),
                leading: const Icon(
                  Icons.my_library_music,
                ),
              ),
              if (kDebugMode)
                ListTile(
                  title: const Text("Скопировать Kate Mobile токен"),
                  subtitle: const Text("Debug-режим"),
                  leading: const Icon(Icons.key),
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
                  title: const Text("Скопировать VK Admin токен"),
                  subtitle: const Text("Debug-режим"),
                  leading: const Icon(Icons.key),
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
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.home_profilePageLogout,
                ),
                leading: const Icon(Icons.logout),
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => const ProfileLogoutExitDialog(),
                ),
              ),

              // Данный SizedBox нужен, что бы плеер снизу при мобильном layout'е не закрывал ничего важного.
              if (player.isLoaded && isMobileLayout)
                const SizedBox(
                  height: 70,
                ),
            ],
          ),
        ),

        // Данный SizedBox нужен, что бы плеер снизу при desktop layout'е не закрывал ничего важного.
        // Мы его располагаем после ListView, что бы ScrollBar не был закрыт плеером.
        if (player.isLoaded && !isMobileLayout)
          const SizedBox(
            height: 90,
          ),
      ],
    );
  }
}
