import 'package:logger/logger.dart';

/// The level of a log message.
/// 
/// none: Indicating no logging should occur.
/// error: critical errors or failures.
/// warning: potential issues or warnings that should be noted but don't disrupt the functionality.
/// info: Provides informational messages about the system's behavior or important events.
/// debug: Used for detailed debugging information during development and troubleshooting.
enum StaleMateLogLevel {
  /// Indicating no logging should occur.
  none,

  /// critical errors or failures.
  error,

  /// potential issues or warnings that should be noted but don't disrupt the functionality.
  warning,

  /// Provides informational messages about the system's behavior or important events.
  info,

  /// Used for detailed debugging information during development and troubleshooting.
  debug,
}

/// Converts a [StaleMateLogLevel] to a [Level].
/// 
/// We don't want to expose the [Level] enum to the user.
/// This is because the [Level] enum is specific to the logger package.
/// and we don't want to export it from this package or force
/// the user to import it specifcly to change the log level.
/// Also, this gives us the option to change the logger package
/// in the future without breaking the API.
Level staleMateLogLevelToLevel(StaleMateLogLevel logLevel) {
  switch (logLevel) {
    case StaleMateLogLevel.error:
      return Level.error;
    case StaleMateLogLevel.warning:
      return Level.warning;
    case StaleMateLogLevel.info:
      return Level.info;
    case StaleMateLogLevel.debug:
      return Level.debug;
    default:
      return Level.nothing;
  }
}
