import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:logger/logger.dart";
import "package:path/path.dart" as path;
import "package:path_provider/path_provider.dart";

import "../utils.dart";

/// Возвращает объект логгера для передаваемого [owner].
AppLogger getLogger<T>(T owner) {
  String ownerStr = owner is String ? owner : owner.toString();

  return AppLogger(
    owner: ownerStr,
  );
}

/// Возвращает путь к файлу, в котором хранятся логи приложения. Данный метод не создаёт файл в случае его отсутствия.
///
/// Если вам нужно, что бы файл с логом существовал, то вместо этого метода воспользуйтесь методом [createLogFile].
Future<File> logFilePath() async {
  if (isWeb) {
    throw UnsupportedError("Web is not supported");
  }

  final String dir = (await getApplicationSupportDirectory()).path;

  return File(path.join(dir, "Flutter VK logs.txt"));
}

/// Возвращает файл, в котором хранятся логи приложения. Если такового файла нет, то он будет создан.
Future<File> createLogFile() async {
  final File file = await logFilePath();

  if (!file.existsSync()) await file.create();

  return file;
}

/// [DevelopmentFilter] для [AppLogger], который разрешает вывод debug/trace/verbose логов только в debug-версии приложения ([kDebugMode] = true).
class _AppLogFilter extends DevelopmentFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (!kDebugMode && event.level.value <= Level.debug.value) return false;

    return true;
  }
}

/// [LogOutput], который форматирует вывод.
class _AppLogOutput extends LogOutput {
  /// Текстовый файл, в котором хранится лог приложения.
  File? _logFile;

  @override
  void output(OutputEvent event) async {
    final List<String> output = [];

    // Содержимое лога.
    output.addAll(event.lines);

    // Выводим в консоль.
    // ignore: avoid_print
    output.forEach(print);

    // Не позволяем сохранять в файл debug и другие более низкие логи.
    if (event.level.value <= Level.debug.value) return;

    // Сохраняем в файл, удаляя ANSI-символы.
    if (!isWeb) {
      _logFile ??= await createLogFile();

      _logFile!.writeAsStringSync(
        _AppLogPrinter.removeAnsiColors("${output.join("\n")}\n"),
        mode: FileMode.writeOnlyAppend,
      );
    }
  }
}

/// [LogPrinter], выводящий красивый вывод для лога в консоль.
class _AppLogPrinter extends LogPrinter {
  _AppLogPrinter({
    this.owner,
  });

  String? owner;

  /// Префиксы для различных уровней логирования.
  static final levelPrefixes = {
    Level.trace: "TRACE  ",
    Level.debug: "DEBUG  ",
    Level.info: "INFO   ",
    Level.warning: "WARNING",
    Level.error: "ERROR  ",
    Level.fatal: "FATAL  ",
  };

  /// Цвета для различных уровней логирования.
  static final levelColors = {
    Level.trace: const AnsiColor.fg(8),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.none(),
    Level.warning: const AnsiColor.fg(11),
    Level.error: const AnsiColor.fg(160),
    Level.fatal: const AnsiColor.fg(196),
  };

  /// Возвращает текущее время с зелёным фоном.
  static String getColoredTime(DateTime time) =>
      const AnsiColor.fg(10).call(time.toString());

  /// Возвращает текстовое название для [level] лога, окрашенный в свой цвет. Название уровня берётся с [levelPrefixes], пока как цвета с [levelColors].
  static String getColoredLevelName(Level level) =>
      levelColors.containsKey(level)
          ? levelColors[level]!.call(
              levelPrefixes[level]!,
            )
          : "<?$level> ";

  /// Возвращает окрашенное значение для поля [owner].
  String getColoredOwner() =>
      owner != null ? const AnsiColor.fg(43).call(owner!) : "";

  /// Возвращет окрашенный текст ошибки [error].
  static String getColoredError(String error) =>
      levelColors[Level.error]!.call(error);

  /// Возвращет окрашенный текст StackTrace [stackTrace].
  static List<String> getColoredStacktrace(StackTrace stackTrace) => stackTrace
      .toString()
      .split("\n")
      .map((line) => levelColors[Level.error]!.call(line))
      .toList();

  /// Удаляет все ANSI-символы, используемые для окрашивания строки.
  static String removeAnsiColors(String input) =>
      input.replaceAll(RegExp("\x1b\\[[0-9;]*m"), "");

  /// Возвращает строковую версию передаваемого [message]. В случае, если будет передан [Map] или [Iterable], то он будет закодирован как JSON-строка.
  static String stringifyMessage(dynamic message) {
    final finalMessage = message is Function ? message() : message;

    if (finalMessage is Map || finalMessage is Iterable) {
      var encoder = const JsonEncoder.withIndent("\t");

      return encoder.convert(finalMessage);
    }

    return finalMessage.toString();
  }

  /// Возвращает окрашенный текст сообщения.
  static String getColoredMessage(dynamic message, Level level) =>
      levelColors[level]!(stringifyMessage(message));

  @override
  List<String> log(LogEvent event) {
    String time = getColoredTime(event.time);
    String level = getColoredLevelName(event.level);
    String owner = getColoredOwner();
    String message = getColoredMessage(event.message, event.level);

    List<String> outputList = [
      "$time | $level | ${this.owner != null ? '$owner - ' : ''}$message",
    ];
    if (event.error != null) {
      outputList.add(
        getColoredError(
          event.error.toString(),
        ),
      );
    }
    if (event.stackTrace != null) {
      outputList.addAll(
        getColoredStacktrace(
          event.stackTrace!,
        ),
      );
    }

    return outputList;
  }
}

/// Класс, расширяющий [Logger], дающий опции для логирования в stdin а так же в файл, путь к которому возвращается методом [logFilePath].
///
/// Вместо привычных `Logger.error(...)` в данном классе используются сокращённые наименования, где берётся лишь первая буква каждого метода: [d] (debug), [i] (info), [w] (warning), [e] (error), и так далее.
///
/// Вместо инициализации данного класса рекомендуется использовать метод [getLogger], автоматически создающий instance этого класса с правильно передавемым [owner].
class AppLogger extends Logger {
  AppLogger({
    this.owner,
  }) : super(
          filter: _AppLogFilter(),
          output: _AppLogOutput(),
          printer: _AppLogPrinter(owner: owner),
        );

  String? owner;
}
