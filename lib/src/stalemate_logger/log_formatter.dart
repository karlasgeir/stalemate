import 'stalemate_log_level.dart';

/// A utility class that can be used to colorize text in the console.
class Colorizer {
  static const String _reset = '\u001b[0m';
  static const String _red = '\u001b[31m';
  static const String _green = '\u001b[32m';
  static const String _yellow = '\u001b[33m';
  static const String _blue = '\u001b[34m';
  static const String _magenta = '\u001b[35m';
  static const String _cyan = '\u001b[36m';
  static const String _white = '\u001b[37m';

  static String red(String text) => colorize(text, _red);
  static String green(String text) => colorize(text, _green);
  static String yellow(String text) => colorize(text, _yellow);
  static String blue(String text) => colorize(text, _blue);
  static String magenta(String text) => colorize(text, _magenta);
  static String cyan(String text) => colorize(text, _cyan);
  static String white(String text) => colorize(text, _white);

  static String colorize(String text, String color) {
    return '$color$text$_reset';
  }
}

/// A utility class that can be used to format log messages.
class LogFormatter {
  /// The level of the log message.
  final StaleMateLogLevel logLevel;

  /// The message to log.
  final String message;

  /// The tag to use for the log message.
  final String? tag;

  /// The error to log.
  final Object? error;

  /// The stack trace to log.
  final StackTrace? stackTrace;

  /// The data to log.
  final Object? data;

  LogFormatter({
    required this.logLevel,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    this.data,
  });

  /// A utility method to colorize the log message based on the log level.
  String colorizeForLogLevel(String text) {
    switch (logLevel) {
      case StaleMateLogLevel.error:
        return Colorizer.red(text);
      case StaleMateLogLevel.warning:
        return Colorizer.yellow(text);
      case StaleMateLogLevel.info:
        return Colorizer.blue(text);
      case StaleMateLogLevel.debug:
        return Colorizer.cyan(text);
      default:
        return text;
    }
  }

  /// Returns the emoji for the log level.
  String get emoji {
    switch (logLevel) {
      case StaleMateLogLevel.info:
        return 'ℹ️'; // Information
      case StaleMateLogLevel.debug:
        return '🐛'; // Debugging
      case StaleMateLogLevel.error:
        return '❌'; // Error
      case StaleMateLogLevel.warning:
        return Colorizer.yellow('⚠️'); // Warning
      default:
        // The last case is StaleMateLogLevel.none, which should not log anything.
        return '';
    }
  }

  /// Returns the string representation of the log level.
  String get logLevelString {
    switch (logLevel) {
      case StaleMateLogLevel.error:
        return 'ERROR';
      case StaleMateLogLevel.warning:
        return 'WARNING';
      case StaleMateLogLevel.info:
        return 'INFO';
      case StaleMateLogLevel.debug:
        return 'DEBUG';
      default:
        // The last case is StaleMateLogLevel.none, which should not log anything.
        return '';
    }
  }

  /// Returns the current timestamp in the format: yyyy-MM-dd HH:mm:ss
  String get timeStamp =>
      DateTime.now().toIso8601String().substring(0, 19).replaceFirst('T', ' ');

  /// Returns the formatted log message.
  /// Example: 2021-07-04 12:00:00 | ℹ️ [tag] INFO: This is a log message.
  String formatBaseMessage() {
    final stringBuffer = StringBuffer();
    stringBuffer.write(timeStamp);
    stringBuffer.write(' | ');
    stringBuffer.write('$emoji ');
    if (tag != null) stringBuffer.write('[$tag] ');
    stringBuffer.write(logLevelString);
    stringBuffer.write(': ');
    stringBuffer.write(message);
    return colorizeForLogLevel(stringBuffer.toString());
  }

  /// Returns the formatted error message.
  /// Includes the error and stack trace if available.
  /// Example: Error: This is an error.
  ///          Stack Trace:
  ///             #0      main (file:///Users/username/Projects/project_name/bin/main.dart:10:3)
  String? formatError() {
    if (error == null && stackTrace == null) return null;

    final stringBuffer = StringBuffer();

    if (error != null) {
      stringBuffer.writeln(Colorizer.red('    Error: $error'));
    }
    if (stackTrace != null) {
      final indentedStackTrace = stackTrace
          .toString()
          .trim()
          .split('\n')
          .map((line) => '        $line')
          .join('\n');
      stringBuffer
          .writeln(Colorizer.yellow('    Stack Trace:\n$indentedStackTrace'));
    }
    return stringBuffer.toString();
  }

  /// Returns formatted map data colorised for the console.
  /// Example:
  ///         key1: value1,
  ///         key2: value2,
  String formatMap(Map map) {
    return map.entries
        .map((entry) =>
            '        ${Colorizer.cyan(entry.key)}: ${Colorizer.magenta(entry.value)}')
        .join('\n');
  }

  /// Returns the formatted iterable data
  /// Example: value1, value2, value3
  String formatIterable(Iterable iterable) {
    return iterable.map((item) => '$item').join(', ');
  }

  /// Returns the formatted data colorised for the console.
  /// Example: Data[Map<String,String>]: {
  ///              key1: value1,
  ///              key2: value2,
  ///          }
  String? formatData() {
    if (data == null) return null;

    final stringBuffer = StringBuffer();
    stringBuffer.write(Colorizer.cyan('    Data[${data.runtimeType}]: '));

    if (data is Map) {
      stringBuffer.writeln(Colorizer.green('{'));
      stringBuffer.writeln(formatMap(data as Map));
      stringBuffer.writeln(Colorizer.green('    }'));
    } else if (data is Iterable) {
      stringBuffer.write(Colorizer.green('['));
      stringBuffer.write(Colorizer.cyan(formatIterable(data as Iterable)));
      stringBuffer.write(Colorizer.green(']'));
    } else {
      stringBuffer.write(Colorizer.magenta(data.toString()));
    }

    return stringBuffer.toString();
  }

  /// Returns the formatted log message.
  String format() {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln(formatBaseMessage());
    final errorMessage = formatError();
    if (errorMessage != null) {
      buffer.writeln(errorMessage);
    }

    final dataMessage = formatData();
    if (dataMessage != null) {
      buffer.writeln(dataMessage);
    }

    return buffer.toString();
  }
}
