/// Exception thrown when there is no local data available.
class NoLocalDataException implements Exception {
  final String message;

  NoLocalDataException(this.message);

  @override
  String toString() {
    return 'NoLocalDataException: $message';
  }
}
