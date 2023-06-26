/// Exception thrown when a feature is not supported
class NotSupportedException implements Exception {
  final String message;

  NotSupportedException(this.message);

  @override
  String toString() {
    return 'NotSupportedException: $message';
  }
}
