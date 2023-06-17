export 'log_formatter.dart';
export 'stalemate_log_level.dart';

import 'log_formatter.dart';
import 'stalemate_log_level.dart';

/// An abstract logger that can be used to log messages
abstract class StaleMateLogger {
  static const String defaultTag = 'StaleMateLogger';
  StaleMateLogLevel _logLevel;

  StaleMateLogger({
    // If no log level is specified, default to none.
    StaleMateLogLevel logLevel = StaleMateLogLevel.none,
  }) : _logLevel = logLevel;

  /// Change the log level.
  /// [StaleMateLogLevel.none]: nothing will be logged.
  /// [StaleMateLogLevel.error]: only errors will be logged.
  /// [StaleMateLogLevel.warning]: errors and warnings will be logged.
  /// [StaleMateLogLevel.info]: Provides informational messages about the system's behavior or important events.
  /// [StaleMateLogLevel.debug]: Used for detailed debugging information during development and troubleshooting.
  setLogLevel(StaleMateLogLevel logLevel) {
    _logLevel = logLevel;
  }

  /// Log a message.
  /// [message]: The message to log.
  /// [level]: The [StaleMateLogLevel] of the log message.
  /// [tag]: The tag to use for the log message.
  /// [error]: The error to log.
  /// [stackTrace]: The stack trace to log.
  void log(
    /// The message to log.
    String message,

    /// The level of the log message.
    StaleMateLogLevel level, {
    /// The tag to use for the log message.
    String? tag = defaultTag,

    /// The error to log.
    Object? error,

    /// The stack trace to log.
    StackTrace? stackTrace,

    /// The data to log.
    Object? data,
  });

  /// Log a message at the error level.
  /// Will only log if the log level is set to [StaleMateLogLevel.error] or higher.
  void logError(
    /// The message to log.
    String message, {
    /// The tag to use for the log message.
    String? tag = defaultTag,

    /// The error to log.
    Object? error,

    /// The stack trace to log.
    StackTrace? stackTrace,
  }) =>
      log(
        message,
        StaleMateLogLevel.error,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );

  /// Log a message at the warning level.
  /// Will only log if the log level is set to [StaleMateLogLevel.warning] or higher.
  void logWarning(
    /// The message to log.
    String message, {
    /// The tag to use for the log message.
    String? tag = defaultTag,
  }) =>
      log(
        message,
        StaleMateLogLevel.warning,
        tag: tag,
      );

  /// Log a message at the info level.
  /// Will only log if the log level is set to [StaleMateLogLevel.info] or higher.
  void logInfo(
    /// The message to log.
    String message, {
    /// The tag to use for the log message.
    String? tag = defaultTag,

    /// The data to log.
    Object? data,
  }) =>
      log(
        message,
        StaleMateLogLevel.info,
        tag: tag,
        data: data,
      );

  /// Log a message at the debug level.
  /// Will only log if the log level is set to [StaleMateLogLevel.debug].
  void logDebug(
    /// The message to log.
    String message, {
    /// The tag to use for the log message.
    String? tag = defaultTag,

    /// The error to log.
    Object? error,

    /// The stack trace to log.
    StackTrace? stackTrace,

    /// The data to log.
    Object? data,
  }) =>
      log(
        message,
        StaleMateLogLevel.debug,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
        data: data,
      );
}

/// A logger that logs to the console
class StaleMateConsoleLogger extends StaleMateLogger {
  StaleMateConsoleLogger({
    // If no log level is specified, default to none.
    StaleMateLogLevel logLevel = StaleMateLogLevel.none,
  }) : super(logLevel: logLevel);

  @override
  void log(
    String message,
    StaleMateLogLevel level, {
    String? tag = StaleMateLogger.defaultTag,
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) {
    try {
      // Only log if the log level is greater than or equal to the specified log level.
      // none: nothing will be logged.
      // error: only errors will be logged.
      // warning: errors and warnings will be logged.
      // info: errors, warnings, and info will be logged.
      // debug: everything will be logged.
      if (level.index <= _logLevel.index) {
        // Format the log message.
        final logFormatter = LogFormatter(
          logLevel: level,
          message: message,
          tag: tag,
          error: error,
          stackTrace: stackTrace,
          data: data,
        );
        // ignore: avoid_print
        print(logFormatter.format());
      }
    } catch (e) {
      // Ignore any errors that occur while logging.
      // We don't want to cause a crash because of a logging error.
      // ignore: avoid_print
      print('StaleMateLoader: Error while logging: $e');
    }
  }
}
