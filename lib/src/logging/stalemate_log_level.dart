import 'package:logger/logger.dart';

/// The level of a log message.
///
/// Available log levels:
/// - **none:** Indicating no logging should occur.
/// - **error:** critical errors or failures.
/// - **warning:** potential issues or warnings that should be noted but don't disrupt the functionality.
/// - **info:** Provides informational messages about the system's behavior or important events.
/// - **debug:** Used for detailed debugging information during development and troubleshooting.
enum StaleMateLogLevel {
  none,
  error,
  warning,
  info,
  debug,
}

/// Converts a [StaleMateLogLevel] to a [Level].
///
/// This is used internally to convert the [StaleMateLogLevel]
/// to a [Level] that the logger package understands.
///
/// ** Why not use the [Level] enum directly? **
/// - The [Level] enum is specific to the logger package.
/// - We don't want to export it from this package
/// - We don't want to force the user to import it specifically.
/// - This gives us the option to change the logger package
///   in the future without breaking the API.
///
/// returns the [Level] corresponding to the [StaleMateLogLevel].
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
