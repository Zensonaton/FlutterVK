import "dart:io";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:queue/queue.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "../main.dart";
import "../services/download_manager.dart";
import "../services/logger.dart";

part "download_manager.g.dart";

/// Класс, отображающий состояние для [DownloadManager]'а.
class DownloadManagerState {
  static final AppLogger logger = getLogger("DownloadManagerState");

  /// Список из [DownloadTask].
  final List<DownloadTask> tasks;

  /// Список из [DownloadTask], являющийся копией [tasks], который отображает старые, уже выполненные задачи.
  final List<DownloadTask> oldTasks;

  /// Указывает, что была начата задача по загрузке.
  final bool downloadStarted;

  /// [ValueNotifier], возвращающий общий прогресс по всем задачам.
  final ValueNotifier<double> progress;

  /// Текущая задача, которая загружается в данный момент.
  final DownloadTask? currentTask;

  /// Делает копию этого класа с новыми передаваемыми значениями.
  DownloadManagerState copyWith({
    List<DownloadTask>? tasks,
    List<DownloadTask>? oldTasks,
    bool? downloadStarted,
    ValueNotifier<double>? progress,
    DownloadTask? currentTask,
    Queue? queue,
  }) {
    return DownloadManagerState(
      tasks: tasks ?? this.tasks,
      oldTasks: oldTasks ?? this.oldTasks,
      downloadStarted: downloadStarted ?? this.downloadStarted,
      progress: progress ?? this.progress,
      currentTask: currentTask ?? this.currentTask,
    );
  }

  DownloadManagerState({
    required this.tasks,
    this.oldTasks = const [],
    this.downloadStarted = false,
    required this.progress,
    this.currentTask,
  });
}

/// [Provider], предоставляющий доступ к менеджеру загрузок.
@riverpod
class DownloadManager extends _$DownloadManager {
  static final AppLogger logger = getLogger("DownloadManagerProvider");

  /// Очередь из задач по загрузке.
  Queue? _queue;

  /// Последнее изменение FGS-уведомления на OS Android.
  ///
  /// Хранимое здесь число - [DateTime.millisecondsSinceEpoch].
  int? _lastNotificationUpdate;

  @override
  DownloadManagerState build() {
    return DownloadManagerState(
      tasks: [],
      progress: ValueNotifier(0.0),
    );
  }

  /// Возвращает [AndroidFlutterLocalNotificationsPlugin] если вызван на OS Android.
  AndroidFlutterLocalNotificationsPlugin? _getNotifsPlugin() {
    if (!Platform.isAndroid) return null;

    return notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
  }

  /// Создаёт уведомление на Android.
  Future<void> _createNotification({
    required String title,
    required double progress,
  }) async {
    assert(
      progress >= 0.0 && progress <= 1.0,
      "Progress should be on range of 0.0 to 1.0, but got $progress instead",
    );

    if (!Platform.isAndroid) return;

    // Если прошло менее 1 секунды с момента последнего обновления, то ничего не делаем.
    final int curEpoch = DateTime.now().millisecondsSinceEpoch;
    if (_lastNotificationUpdate != null &&
        curEpoch - _lastNotificationUpdate! < 1000) {
      return;
    }

    logger.d("Updating notification with progress $progress");

    _lastNotificationUpdate = curEpoch;
    await _getNotifsPlugin()?.startForegroundService(
      1,
      title,
      "${(progress * 100).round()}%",
      notificationDetails: AndroidNotificationDetails(
        "downloadManager",
        "Download Manager",
        progress: (progress * 100).ceil(),
        showProgress: true,
        autoCancel: false,
        ongoing: true,
        maxProgress: 100,
        importance: Importance.min,
        priority: Priority.min,
      ),
      foregroundServiceTypes: {
        AndroidServiceForegroundType.foregroundServiceTypeDataSync,
      },
    );
  }

  /// Добавляет новую задачу типа [DownloadTask] в список задач, и сразу же начинает её выполнять. К примеру, данная задача может являться задачей по загрузке треков с плейлиста.
  ///
  /// У [task] есть [DownloadTask.id], используемый для идентификации задачи. При добавлении уже существующей задачи, под-задачи ([DownloadTask.tasks]) будут объединены в одну.
  ///
  /// Данный метод считается завершённым лишь тогда, когда [task] будет выполнен. Таким образом,
  /// ```dart
  /// await newTask(...);
  /// print("completed!");
  /// ```
  /// "compeleted!" будет отображён после полного выполнения [task].
  Future<void> newTask(DownloadTask task) async {
    void progressListener() async {
      final List<DownloadTask> tasks = state.tasks;
      final double progress = tasks.isEmpty
          ? 1.0
          : tasks.fold(
                0.0,
                (total, item) => total + item.progress.value,
              ) /
              tasks.length;

      state.progress.value = progress;
      await _createNotification(title: task.longTitle, progress: progress);
    }

    // Если нам не дана задачи, то ничего не делаем.
    if (task.tasks.isEmpty) return;

    // Ищем существующую задачу.
    final existingTask =
        state.tasks.firstWhereOrNull((item) => item.id == task.id);
    if (existingTask != null) {
      logger.d("Found existing task $existingTask");

      // TODO: Реализовать объединение задач с одинаковыми ID.
      //
      // Не удалось реализовать, поскольку из-за модификации [tasks] во время выполнения,
      //  появляется ошибка "Concurrent modification during iteration".
    }

    logger.d("Running task $task");

    state = state.copyWith(
      tasks: [...state.tasks, task],
    );

    // Если очередь не существует, то создаём её.
    if (_queue == null) {
      _queue = Queue();

      // По завершению очереди, очищаем её.
      _queue!.onComplete.then((_) {
        logger.d("Queue completed!");

        _queue!.cancel();
        _queue = null;

        // Все задачи выполнены.
        state = state.copyWith(
          downloadStarted: false,
          oldTasks: [...state.tasks, ...state.oldTasks],
          tasks: [],
        );

        // Если мы на OS Android, то убираем FGS-уведомление.
        if (Platform.isAndroid) {
          _getNotifsPlugin()?.stopForegroundService();
        }
      });
    }

    // Добавляем задачу в очередь.
    await _queue!.add(() async {
      // Запоминаем, что мы начали загрузку.
      state = state.copyWith(downloadStarted: true, currentTask: task);
      task.progress.addListener(progressListener);

      // Запускаем задачу.
      try {
        await task.download();
      } catch (e) {
        // TODO: Обработчик ошибок.
      }

      logger.d("Completed task $task");
      task.progress.removeListener(progressListener);

      return;
    });
  }
}

/// Возвращает [DownloadTask] по его [id].
@riverpod
DownloadTask? downloadTaskByID(DownloadTaskByIDRef ref, String id) {
  return ref
      .watch(downloadManagerProvider)
      .tasks
      .firstWhereOrNull((item) => item.id == id);
}
