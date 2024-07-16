import "dart:async";
import "dart:io";

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:queue/queue.dart";

import "../utils.dart";
import "logger.dart";

/// [DownloadTask], загружающий обновление для Flutter VK.
class AppUpdaterDownloadTask extends DownloadTask {
  final Dio dio = Dio();

  /// Url на загрузку данного файла.
  final String url;

  /// Полный путь, куда будет сохранён данный файл после загрузки.
  final File file;

  AppUpdaterDownloadTask({
    required super.smallTitle,
    required super.longTitle,
    required this.url,
    required this.file,
  }) : super(
          tasks: [
            DownloaderTaskItem(
              url: url,
              file: file,
            ),
          ],
        );
}

/// [DownloadTaskItem], загружающий файл по передаваемому [url], и дальше сохраняет его в [file] после успешной загрузки.
class DownloaderTaskItem extends DownloadTaskItem {
  final Dio dio = Dio();

  /// Url на загрузку данного файла.
  final String url;

  /// Полный путь, куда будет сохранён данный файл после загрузки.
  final File file;

  DownloaderTaskItem({
    required this.url,
    required this.file,
  });

  @override
  Future<void> download() async {
    final response = await dio.get(
      url,
      options: Options(
        responseType: ResponseType.bytes,
      ),
      onReceiveProgress: (int received, int total) {
        progress.value = received / total;
      },
    );

    file.writeAsBytesSync(response.data);
  }

  @override
  Future<void> cancel() async => dio.close(force: true);
}

@Deprecated("Not used")
class TestDownloadTask extends DownloadTaskItem {
  TestDownloadTask();

  @override
  Future<void> download() async {
    while (progress.value < 1.0) {
      progress.value += 0.5;
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }
}

/// Отдельная, под-задача для [DownloadTask], олицетворяющая маленькую задачу для загрузки чего-либо.
///
/// К примеру, здесь может быть задача по загрузке отдельного трека в плейлисте.
class DownloadTaskItem {
  static final AppLogger logger = getLogger("DownloadTaskItem");

  /// [ValueNotiifer], показывающий прогресс загрузки, где `0.0` - 0%, `1.0` - 100%.
  final ValueNotifier<double> progress = ValueNotifier(0.0);

  /// Метод, вызываемый при загрузке данной задачи.
  Future<void> download() async {
    throw UnimplementedError();
  }

  /// Метод, вызываемый при остановке данной задачи.
  Future<void> cancel() async {
    throw UnimplementedError();
  }

  @override
  String toString() =>
      "DownloadTaskItem, ${(progress.value * 100).round()}% completed";

  DownloadTaskItem();
}

/// Отдельная, глобальная задача по загрузке чего-либо для DownloadManager'а.
///
/// В данной задаче может быть множество под-задач ([DownloadTaskItem]), к примеру, данная задача может использоваться для кэширования целого плейлиста, а под-задачами будет кэширование каждого отдельного трека внутри этого плейлиста.
class DownloadTask {
  static final AppLogger logger = getLogger("DownloadTask");

  /// Маленькое название у данной задачи, отображаемое при наведении на [DownloadManagerIconWidget].
  ///
  /// Содержимое данное переменной должно быть максимально кратким, что бы оно с большей вероятностью вместилось в [DownloadManagerIconWidget]. Пример: "Любимая музыка" или "Обновление".
  final String smallTitle;

  /// Более длинное название у данной задачи, отображаемое в других местах, например, уведомлении на OS Android.
  ///
  /// Пример: "Кэширование плейлиста 'Любимая музыка'" или "Обновление Flutter VK v1.2.3".
  final String longTitle;

  /// Общий список из всех задач типа [DownloadTaskItem].
  final List<DownloadTaskItem> tasks;

  /// [ValueNotifier], возвращающий общий прогресс по всем задачам.
  final ValueNotifier<double> progress = ValueNotifier(0.0);

  /// [Queue], используемый для одновременной загрузки задач из [tasks].
  final Queue queue = Queue(parallel: isDesktop ? 5 : 3);

  /// Начинает задачу по загрузке всех [tasks].
  Future<void> download() async {
    void listener() {
      progress.value = tasks.fold(
            0.0,
            (total, item) => total + item.progress.value,
          ) /
          tasks.length;
    }

    for (DownloadTaskItem item in tasks) {
      queue.add(() async {
        item.progress.addListener(listener);

        await item.download();
        item.progress.removeListener(listener);
      }).onError((error, stackTrace) {
        if (error is QueueCancelledException) return;

        logger.e(
          "Download error:",
          error: error,
          stackTrace: stackTrace,
        );
      });
    }
    await queue.onComplete;
  }

  @override
  String toString() =>
      "DownloadTask \"$smallTitle\" with ${tasks.length} tasks, ${(progress.value * 100).round()}% completed";

  DownloadTask({
    required this.smallTitle,
    required this.longTitle,
    required this.tasks,
  });
}
