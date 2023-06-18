import 'package:logger/logger.dart';

/// A [PrettyPrinter] that adds a tag to each log line.
///
/// This is useful when you have multiple loggers and want to
/// differentiate between them.
class TaggedLoggingPrinter extends PrettyPrinter {
  /// The tag to add to each log line.
  final String tag;

  TaggedLoggingPrinter({
    required this.tag,
    super.stackTraceBeginIndex,
    super.methodCount,
    super.errorMethodCount,
    super.lineLength,
    super.colors,
    super.printEmojis,
    super.printTime,
    super.excludeBox,
    super.noBoxingByDefault,
    super.excludePaths,
  });

  @override
  List<String> log(LogEvent event) {
    return super.log(event).map((line) => '[$tag] $line').toList();
  }
}
