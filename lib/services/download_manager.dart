import "package:http/http.dart";
import "package:queue/queue.dart";

/// Класс-менеджер загрузок.
class DownloadManager {
  /// Очередь загрузок.
  final Queue _queue;

  /// [Map], где в роли ключа выступает поле cacheKey, а значение - Future с загрузкой.
  ///
  /// Используется для предотвращения случайной загрузки одного и того же файла несколько раз, если передаётся cacheKey.
  final Map<String, Future<Response>> _queueItems;

  int get parallelDownloads => _queue.parallel;
  set parallelDownloads(int count) => _queue.parallel = count;

  DownloadManager({
    int parralelDownloads = 1,
  })  : _queue = Queue(
          parallel: parralelDownloads,
        ),
        _queueItems = {};

  /// Загружает файл по указанному [url]. Указав [cacheKey], загрузчик не позволит загружать один и тот же элемент несколько раз, возвращая уже загруженный файл.
  Future<Response> download(
    String url, {
    String? cacheKey,
  }) async {
    // Проверяем, нет ли уже существующего Future с загрузкой данного элемента.
    if (cacheKey != null) {
      Future<Response>? queueFuture = _queueItems[cacheKey];

      if (queueFuture != null) {
        return await queueFuture;
      }
    }

    // Создаём Future для загрузки данного файла, и потом помещаем его в _queueItems.
    Future<Response> future = _queue.add(
      () async => await get(
        Uri.parse(url),
      ),
    );

    if (cacheKey != null) _queueItems[cacheKey] = future;

    // Дожидаемся результата.
    final Response response = await future;

    // Удаляем запись.
    _queueItems.remove(cacheKey);

    return response;
  }
}
