/// StaleMateRefreshStatus is the status of a refresh operation
/// success: The refresh operation was successful
/// failure: The refresh operation failed
/// alreadyRefreshing: A refresh operation is already in progress
enum StaleMateRefreshStatus {
  success,
  failure,
  alreadyRefreshing,
}

/// StaleMateRefreshResult is the result of a refresh operation
class StaleMateRefreshResult<T> {
  /// The status of the refresh operation
  final StaleMateRefreshStatus status;

  /// The time at which the refresh was initiated
  final DateTime refreshInitiatedAt;

  /// The duration of the refresh operation
  final DateTime refreshFinishedAt;

  /// The refreshed data if the refresh was successful
  final T? refreshedData;

  /// The error if the refresh failed
  final Object? error;

  StaleMateRefreshResult({
    required this.status,
    required this.refreshInitiatedAt,
    required this.refreshFinishedAt,
    this.refreshedData,
    this.error,
  });

  Duration get refreshDuration =>
      refreshFinishedAt.difference(refreshInitiatedAt);

  bool get isSuccess => status == StaleMateRefreshStatus.success;
  bool get isFailure => status == StaleMateRefreshStatus.failure;
  bool get isAlreadyRefreshing =>
      status == StaleMateRefreshStatus.alreadyRefreshing;

  /// The refreshed data if the refresh was successful
  /// Throws an assertion error if the refresh failed
  /// Use isSuccess to check if data is available
  T get requireData {
    assert(isSuccess,
        'Data cannot be required if it is null. Use isSuccess to check if data is available.');
    return refreshedData as T;
  }

  /// The error if the refresh failed
  /// Throws an assertion error if the refresh was successful
  /// Use isFailure to check if error is available
  Object get requireError {
    assert(isFailure,
        'Error cannot be required if it is null. Use isFailure to check if error is available.');
    return error!;
  }

  /// Utility method to handle the result of a refresh operation
  /// calls [success] with the refreshed data if the refresh was successful
  /// calls [failure] with the error if the refresh failed
  on(
    Function(T data) success, {
    Function(Object error)? failure,
  }) {
    if (isSuccess) {
      return success(requireData);
    }
    if (isFailure && failure != null) {
      return failure(requireError);
    }
  }

  /// Factory method to create a successful refresh result
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

  /// Factory method to create a failed refresh result
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

  /// Factory method to create a refresh result when a refresh is already in progress
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
}
