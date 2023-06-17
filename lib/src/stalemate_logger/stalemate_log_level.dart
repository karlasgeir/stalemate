/// The level of a log message.
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
