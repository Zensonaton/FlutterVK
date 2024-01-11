import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" as path;
import "package:logger/logger.dart";

/// Возвращает объект логгера.
AppLogger getLogger<T>(
  T owner,
) {
  String ownerStr = owner is String ? owner : owner.toString();

  return AppLogger(owner: ownerStr);
}

/// Возвращает файл, в котором хранятся логи ошибок.
Future<File> _getLogFile() async {
  final String dir = (await getApplicationSupportDirectory()).path;

  final file = File(path.join(dir, "fluttervk.log"));
  if (!file.existsSync()) await file.create();

  return file;
}

class _AppLogFilter extends DevelopmentFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kDebugMode && event.level == Level.debug) return true;

    return super.shouldLog(event);
  }
}

class _AppLogOutput extends LogOutput {
  @override
  void output(
    OutputEvent event,
  ) async {
    // ignore: avoid_print
    event.lines.forEach(print);
  }
}

class _AppLogPrinter extends LogPrinter {
  _AppLogPrinter({
    this.owner,
  });

  String? owner;
  static final levelPrefixes = {
    Level.trace: "TRACE  ",
    Level.debug: "DEBUG  ",
    Level.info: "INFO   ",
    Level.warning: "WARNING",
    Level.error: "ERROR  ",
    Level.fatal: "FATAL  ",
  };

  static final levelColors = {
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(011),
    Level.error: const AnsiColor.fg(31),
    Level.fatal: const AnsiColor.fg(199),
  };

  String _getColoredTime(DateTime time) {
    return const AnsiColor.fg(10)(time.toString());
  }

  String _getColoredLabelName(Level level) {
    return levelColors[level]!(levelPrefixes[level]!);
  }

  String _getColoredOwner() {
    return owner != null ? const AnsiColor.fg(43)(owner!) : "";
  }

  String _getColoredError(String error) {
    return levelColors[Level.error]!(error);
  }

  String _stringifyMessage(dynamic message) {
    final finalMessage = message is Function ? message() : message;

    if (finalMessage is Map || finalMessage is Iterable) {
      var encoder = const JsonEncoder.withIndent("\t");

      return encoder.convert(finalMessage);
    }

    return finalMessage.toString();
  }

  String _getColoredMessage(dynamic message, Level level) {
    return levelColors[level]!(_stringifyMessage(message));
  }

  @override
  List<String> log(LogEvent event) {
    String time = _getColoredTime(event.time);
    String level = _getColoredLabelName(event.level);
    String owner = _getColoredOwner();
    String message = _getColoredMessage(event.message, event.level);

    List<String> outputList = [
      "$time | $level | ${this.owner != null ? '$owner - ' : ''}$message"
    ];
    if (event.error != null) {
      outputList.add(_getColoredError(
        event.error.toString(),
      ));
    }

    return outputList;
  }
}

class AppLogger extends Logger {
  AppLogger({
    this.owner,
  }) : super(
          filter: _AppLogFilter(),
          output: _AppLogOutput(),
          printer: _AppLogPrinter(
            owner: owner,
          ),
        );

  String? owner;

  @override
  void log(
    Level level,
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      super.log(
        level,
        message,
        error: error,
        stackTrace: stackTrace,
      );
}
