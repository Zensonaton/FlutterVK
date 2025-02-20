import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:gap/gap.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

import "../../../consts.dart";
import "../../../enums.dart";
import "../../../main.dart";
import "../../../provider/download_manager.dart";
import "../../../provider/l18n.dart";
import "../../../provider/player.dart";
import "../../../services/cache_manager.dart";
import "../../../services/download_manager.dart";
import "../../../utils.dart";
import "../../../widgets/audio_player.dart";
import "../../../widgets/fallback_audio_photo.dart";

/// Виджет, отображаемый отдельный загружающийся элемент, например, плейлист.
class DownloadItemWidget extends HookConsumerWidget {
  /// [DownloadTask], отражающий загрузку чего-либо.
  final DownloadTask task;

  /// Указывает, что данная задача выполняется в данный момент.
  final bool isCurrent;

  const DownloadItemWidget({
    super.key,
    required this.task,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    final progress = useValueListenable(task.progress);
    final valueAnimController = useAnimationController(
      initialValue: progress,
    );
    useValueChanged(progress, (_, __) {
      return valueAnimController.animateTo(
        progress,
        curve: Curves.decelerate,
        duration: const Duration(
          milliseconds: 500,
        ),
      );
    });
    final animatedProgress = useValueListenable(valueAnimController);

    final scheme = Theme.of(context).colorScheme;
    final bool isCompleted = progress == 1.0;
    final allTasks = task.tasks;

    return AnimatedContainer(
      curve: Curves.easeInOutCubicEmphasized,
      duration: const Duration(
        milliseconds: 500,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        gradient: isCurrent
            ? LinearGradient(
                colors: [
                  scheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  Colors.transparent,
                ],
              )
            : null,
      ),
      child: Row(
        children: [
          // Изображение для данной задачи.
          DownloadItemIconWidget(
            task: task,
          ),
          const Gap(12),

          // Название.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название.
                Text(
                  task.longTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Количество выполняемых задач, если их больше 1.
                if ((isCurrent || isCompleted) && allTasks.length > 1)
                  Text(
                    l18n.download_manager_all_tasks(
                      count: allTasks.length,
                    ),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          const Gap(12),

          // Анимация загрузки, либо иконка завершённой загрузки.
          SizedBox(
            width: 50,
            height: 50,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 250,
                ),
                child: isCompleted
                    ? Icon(
                        key: const ValueKey(
                          true,
                        ),
                        Icons.check,
                        color: scheme.primary,
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          // Анимация загрузки.
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              key: const ValueKey(
                                false,
                              ),
                              value: animatedProgress,
                            )
                                .animate(
                                  onComplete: (controller) => controller.loop(),
                                )
                                .rotate(
                                  duration: const Duration(
                                    seconds: 2,
                                  ),
                                  begin: 0,
                                  end: 1,
                                ),
                          ),

                          // Прогресс загрузки.
                          AnimatedOpacity(
                            curve: Curves.easeInOutCubicEmphasized,
                            duration: const Duration(
                              milliseconds: 500,
                            ),
                            opacity: animatedProgress > 0.0 ? 1.0 : 0.0,
                            child: Text(
                              "${(animatedProgress * 100).round()}%",
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для [DownloadIconWidget], отображающий иконку, отображаемую слева, в зависимости от типа передаваемой задачи [task].
class DownloadItemIconWidget extends StatelessWidget {
  /// [DownloadTask], отражающий загрузку чего-либо.
  final DownloadTask task;

  const DownloadItemIconWidget({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final int memCacheSize =
        (50 * MediaQuery.devicePixelRatioOf(context)).round();

    if (task is PlaylistCacheDownloadTask) {
      final playlistTask = task as PlaylistCacheDownloadTask;
      final playlist = playlistTask.playlist;

      return ClipRRect(
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: playlist.photo != null
            ? CachedNetworkImage(
                imageUrl: playlist.photo!.photo600,
                cacheKey: "${playlist.mediaKey}600",
                width: 50,
                height: 50,
                memCacheHeight: memCacheSize,
                memCacheWidth: memCacheSize,
                placeholder: (BuildContext context, String string) {
                  return const FallbackAudioAvatar();
                },
                cacheManager: CachedNetworkImagesManager.instance,
              )
            : FallbackAudioPlaylistAvatar(
                favoritesPlaylist: playlist.type == PlaylistType.favorites,
                size: 50,
              ),
      );
    } else if (task is AppUpdaterDownloadTask) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          globalBorderRadius,
        ),
        child: Image.asset(
          "assets/icon.png",
          width: 50,
          height: 50,
          cacheHeight: memCacheSize,
          cacheWidth: memCacheSize,
        ),
      );
    }

    // Перед нами неизвестная задача, отображаем стандартную иконку.
    return const SizedBox(
      width: 50,
      height: 50,
      child: Icon(
        Icons.download,
      ),
    );
  }
}

/// Виджет, отображающий отдельную "категорию" в разделе "загрузки".
///
/// Примером одной из таких категорий является "загружаются сейчас".
class DownloadCategory extends ConsumerWidget {
  /// Название категории.
  final String title;

  /// Список из задач в этой категории.
  final List<DownloadTask> tasks;

  /// Указывает выполняемую в данный момент задачу.
  final DownloadTask? currentTask;

  /// Указывает, что если список задач [tasks] пуст, то покажет надпись "ещё ничего не было загружено".
  final bool showNoTasksIfEmpty;

  const DownloadCategory({
    super.key,
    required this.title,
    required this.tasks,
    required this.currentTask,
    this.showNoTasksIfEmpty = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Название категории.
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(8),

            // Надпись с количеством загружаемых элементов.
            if (tasks.isNotEmpty)
              Text(
                tasks.length.toString(),
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.75),
                ),
              ),
          ],
        ),
        Gap((showNoTasksIfEmpty && tasks.isEmpty) ? 8 : 14),

        // Содержимое загрузки.
        for (DownloadTask task in tasks) ...[
          DownloadItemWidget(
            task: task,
            isCurrent: task == currentTask,
          ),
          const Gap(8),
        ],

        // Если ничего нет, то отображаем сообщение об этом.
        if (showNoTasksIfEmpty && tasks.isEmpty)
          Text(
            l18n.download_manager_no_tasks,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.8),
            ),
          ),
      ],
    );
  }
}

/// Route менеджера загрузок, где отображаются активные загрузки, а так же загрузки, которые были завершены ранее.
///
/// go_route: `/download_manager`.
class DownloadManagerRoute extends HookConsumerWidget {
  const DownloadManagerRoute({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l18n = ref.watch(l18nProvider);
    final player = ref.read(playerProvider);
    final downloadManager = ref.watch(downloadManagerProvider);
    ref.watch(playerIsLoadedProvider);

    final bool mobileLayout = isMobileLayout(context);

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<bool>(
          stream: connectivityManager.connectionChange,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            final bool isConnected = connectivityManager.hasConnection;

            return Text(
              isConnected ? l18n.downloads_label : l18n.downloads_label_offline,
            );
          },
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: mobileLayout ? 16 : 24,
          vertical: mobileLayout ? 20 : 30,
        ).copyWith(
          bottom: 0,
        ),
        children: [
          // Раздел "загружаются сейчас".
          DownloadCategory(
            title: l18n.download_manager_current_tasks,
            tasks: downloadManager.tasks,
            currentTask: downloadManager.currentTask,
            showNoTasksIfEmpty: true,
          ),
          const Gap(18),

          // Раздел "загружено ранее".
          if (downloadManager.oldTasks.isNotEmpty) ...[
            // Разделитель.
            const Divider(),
            const Gap(18),

            // Раздел.
            DownloadCategory(
              title: l18n.download_manager_old_tasks,
              tasks: downloadManager.oldTasks,
              currentTask: null,
            ),
          ],

          // Данный Gap нужен, что бы плеер снизу при Mobile Layout'е не закрывал ничего важного.
          if (player.isLoaded && mobileLayout)
            const Gap(MusicPlayerWidget.mobileHeightWithPadding),
        ],
      ),
    );
  }
}
