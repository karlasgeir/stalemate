/// The status of a refresh operation
///
/// Enum values:
/// - success: The refresh operation was successful
/// - failure: The refresh operation failed
/// - alreadyRefreshing: A refresh operation is already in progress
enum StaleMateRefreshStatus {
  success,
  failure,
  alreadyRefreshing,
}

/// The result of a refresh operation
///
/// This class is used to return the result of a refresh operation
///
/// It contains information about the success of the refresh operation
/// along with properties thatn can be used to debug the refresh operation
///
/// The [StaleMateRefreshResult.on] method is a useful utility method that can be used
/// to simplify handling the result of a refresh operation
class StaleMateRefreshResult<T> {
  /// The status of the refresh operation
  ///
  /// See also:
  /// - [StaleMateRefreshStatus]
  final StaleMateRefreshStatus status;

  /// The time at which the refresh was initiated
  ///
  /// This is the time at which the refresh method was called
  final DateTime refreshInitiatedAt;

  /// The duration of the refresh operation
  ///
  /// This is the time at which the refresh method completed
  final DateTime refreshFinishedAt;

  /// The refreshed data if the refresh was successful
  ///
  /// Use [isSuccess] to check if data is available
  /// Use [requireData] to avoid null checks after checking [isSuccess]
  ///
  /// Null if:
  /// - The refresh failed
  /// - The refresh was already in progress
  ///
  /// Useful for:
  /// - Debugging the refresh operation
  /// - Showing how many items were refreshed
  /// - Logging the refreshed data
  final T? refreshedData;

  /// The error if the refresh failed
  ///
  /// Use [isFailure] to check if error is available
  /// Use [requireError] to avoid null checks after checking [isFailure]
  ///
  /// Null if:
  /// - The refresh was successful
  /// - The refresh was already in progress
  ///
  /// Useful for:
  /// - Debugging the refresh operation
  /// - Showing the error to the user
  /// - Logging the error
  final Object? error;

  /// Constructs a [StaleMateRefreshResult]
  ///
  /// Arguments:
  /// - **status**: The [StaleMateRefreshStatus] of the refresh operation
  /// - **refreshInitiatedAt**: The time at which the refresh was initiated
  /// - **refreshFinishedAt**: The time at which the refresh method completed
  /// - **refreshedData**: The refreshed data if the refresh was successful
  /// - **error**: The error if the refresh failed
  StaleMateRefreshResult({
    required this.status,
    required this.refreshInitiatedAt,
    required this.refreshFinishedAt,
    this.refreshedData,
    this.error,
  });

  /// The duration of the refresh operation
  ///
  /// This is the difference between [refreshFinishedAt] and [refreshInitiatedAt]
  ///
  /// Useful for:
  /// - Debugging the refresh operation
  /// - Showing the duration of the refresh operation to the user
  /// - Logging the duration of the refresh operation
  Duration get refreshDuration =>
      refreshFinishedAt.difference(refreshInitiatedAt);

  /// Whether the refresh was successful
  bool get isSuccess => status == StaleMateRefreshStatus.success;

  /// Whether the refresh failed
  bool get isFailure => status == StaleMateRefreshStatus.failure;

  /// Whether a refresh is already in progress
  bool get isAlreadyRefreshing =>
      status == StaleMateRefreshStatus.alreadyRefreshing;

  /// The refreshed data if the refresh was successful
  ///
  /// Throws an assertion error if the refresh failed
  ///
  /// Use [isSuccess] to check if data is available
  T get requireData {
    assert(isSuccess,
        'Data cannot be required if it is null. Use isSuccess to check if data is available.');
    return refreshedData as T;
  }

  /// The error if the refresh failed
  ///
  /// Throws an assertion error if the refresh was successful
  ///
  /// Use [isFailure] to check if error is available
  Object get requireError {
    assert(isFailure,
        'Error cannot be required if it is null. Use isFailure to check if error is available.');
    return error!;
  }

  /// Utility method to simplify handling the result of a refresh operation
  ///
  /// Arguments:
  /// - **success**: The callback to be called if the refresh was successful,
  ///  the refreshed data is passed as an argument
  /// - **failure**: The callback to be called if the refresh failed,
  ///   the error is passed as an argument
  on({
    Function(T data)? success,
    Function(Object error)? failure,
  }) {
    if (isSuccess && success != null) {
      return success(requireData);
    }
    if (isFailure && failure != null) {
      return failure(requireError);
    }
  }

  /// Shorthand for [StaleMateRefreshStatus.success]
  ///
  /// Use this method to create a successful refresh result
  factory StaleMateRefreshResult.success({
    required T data,
    required DateTime refreshInitiatedAt,
    required DateTime refreshFinishedAt,
  }) {
    return StaleMateRefreshResult<T>(
      status: StaleMateRefreshStatus.success,
      refreshedData: data,
      refreshInitiatedAt: refreshInitiatedAt,
      refreshFinishedAt: refreshFinishedAt,
    );
  }

  /// Shorthand for [StaleMateRefreshStatus.failure]
  ///
  /// Use this method to create a failed refresh result
  factory StaleMateRefreshResult.failure({
    required DateTime refreshInitiatedAt,
    required DateTime refreshFinishedAt,
    required Object error,
  }) {
    return StaleMateRefreshResult<T>(
      status: StaleMateRefreshStatus.failure,
      refreshInitiatedAt: refreshInitiatedAt,
      refreshFinishedAt: refreshFinishedAt,
      error: error,
    );
  }

  /// Shorthand for [StaleMateRefreshStatus.alreadyRefreshing]
  ///
  /// Use this method to create a refresh result when a refresh is already in progress
  factory StaleMateRefreshResult.alreadyRefreshing({
    required DateTime refreshInitiatedAt,
    required DateTime refreshFinishedAt,
  }) {
    return StaleMateRefreshResult<T>(
      status: StaleMateRefreshStatus.alreadyRefreshing,
      refreshInitiatedAt: refreshInitiatedAt,
      refreshFinishedAt: refreshFinishedAt,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('StaleMateRefreshResult<$T>(');
    buffer.writeln('    status: $status,');
    buffer.writeln('    refreshInitiatedAt: $refreshInitiatedAt,');
    buffer.writeln('    refreshFinishedAt: $refreshFinishedAt,');
    buffer.writeln('    refreshedData: $refreshedData,');
    buffer.writeln('    error: $error,');
    buffer.writeln('    refreshDuration: $refreshDuration');
    buffer.write(')');
    return buffer.toString();
  }
}
