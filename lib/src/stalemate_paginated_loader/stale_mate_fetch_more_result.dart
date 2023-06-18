/// Indicates the status of a fetch more operation
///
/// Enum values:
/// - **alreadyFetching:** A fetch more operation is already in progress
/// - **moreDataAvailable:** The fetch more operation was successful and more data is available
/// - **failure:** The fetch more operation was unsuccessful
/// - **done:** The fetch more operation was successful but no more data is available
enum StaleMateFetchMoreStatus {
  alreadyFetching,

  moreDataAvailable,

  failure,

  done,
}

/// The result of a fetch more operation
///
/// This class is used to return the result of a fetch more operation
///
/// It contains information about the success of the fetch more operation
/// along with properties that can be used to debug the fetch more operation
///
/// The [StaleMateFetchMoreResult.on] method is a useful utility method that can be used
/// to simplify handling the result of a fetch more operation
class StaleMateFetchMoreResult<T> {
  /// The status of the fetch more operation
  ///
  /// See also:
  /// - [StaleMateFetchMoreStatus]
  final StaleMateFetchMoreStatus status;

  /// The time at which the fetch more was initiated
  ///
  /// Null if the fetch more is in progress
  final DateTime? fetchMoreInitiatedAt;

  /// The time at which the fetch more was completed
  ///
  /// Null if the fetch more is in progress
  final DateTime? fetchMoreFinishedAt;

  /// The parameters that were used for the fetch more
  ///
  /// Null if the fetch more is in progress
  final Map<String, dynamic>? fetchMoreParameters;

  /// The new data that was fetched from the server
  ///
  /// Null if:
  /// - The fetch more failed
  /// - The fetch more was already in progress
  final List<T>? newData;

  /// The merged data after the fetch more
  ///
  /// The actual data in the datasource after the fetch more
  ///
  /// Null if:
  /// - The fetch more failed
  /// - The fetch more was already in progress
  final List<T>? mergedData;

  /// The error if the fetch more failed
  ///
  /// Null if:
  /// - The fetch more was successful
  /// - The fetch more was already in progress
  final Object? error;

  /// Creates a new [StaleMateFetchMoreResult]
  ///
  /// Arguments:
  /// - **status:** The status of the fetch more operation
  /// - **fetchMoreInitiatedAt:** The time at which the fetch more was initiated
  /// - **fetchMoreFinishedAt:** The time at which the fetch more was completed
  /// - **fetchMoreParameters:** The parameters that were used for the fetch more
  /// - **newData:** The new data that was fetched from the server
  /// - **mergedData:** The merged data after the fetch more
  /// - **error:** The error if the fetch more failed
  ///
  /// See also:
  /// - [StaleMateFetchMoreStatus]
  ///
  /// Example:
  /// ```dart
  /// final result = StaleMateFetchMoreResult(
  ///   status: StaleMateFetchMoreStatus.moreDataAvailable,
  ///   fetchMoreInitiatedAt: DateTime.now(),
  ///   fetchMoreFinishedAt: DateTime.now(),
  ///   fetchMoreParameters: {'page': 1},
  ///   newData: [3, 4],
  ///   mergedData: [1, 2, 3, 4],
  ///   error: null,
  /// );
  /// ```
  StaleMateFetchMoreResult({
    required this.status,
    this.fetchMoreInitiatedAt,
    this.fetchMoreFinishedAt,
    this.fetchMoreParameters,
    this.newData,
    this.mergedData,
    this.error,
  });

  /// The duration of the fetch more operation
  ///
  /// Null if the fetch more is in progress
  Duration? get fetchMoreDuration {
    if (fetchMoreInitiatedAt == null || fetchMoreFinishedAt == null) {
      return null;
    }
    return fetchMoreFinishedAt!.difference(fetchMoreInitiatedAt!);
  }

  /// Fetch more successful and more data is available
  bool get moreDataAvailable =>
      status == StaleMateFetchMoreStatus.moreDataAvailable;

  /// Fetch more failed
  bool get isFailure => status == StaleMateFetchMoreStatus.failure;

  /// Fetch more already in progress
  bool get isAlreadyFetching =>
      status == StaleMateFetchMoreStatus.alreadyFetching;

  /// Fetch more successful but no more data is available
  bool get isDone => status == StaleMateFetchMoreStatus.done;

  /// Fetch more successful and has data

  /// It is safe to call [requireNewData] or [requireMergedData] if this is true
  bool get hasData => moreDataAvailable || isDone;

  /// The time when the fetch more was initiated
  ///
  /// Throws an assertion error if the fetch more is in progress
  ///
  /// use [isAlreadyFetching] to check if the fetch more is in progress
  DateTime get requireFetchMoreInitiatedAt {
    assert(!isAlreadyFetching,
        'Fetch more initiated at cannot be required while already fetching. Use isAlreadyFetching to check if fetch more is in progress.');
    return fetchMoreInitiatedAt!;
  }

  /// The time when the fetch more was completed
  ///
  /// Throws an assertion error if the fetch more is in progress
  ///
  /// use [isAlreadyFetching] to check if the fetch more is in progress
  DateTime get requireFetchMoreFinishedAt {
    assert(!isAlreadyFetching,
        'Fetch more finished at cannot be required while already fetching. Use isAlreadyFetching to check if fetch more is in progress.');
    return fetchMoreFinishedAt!;
  }

  /// The parameters that were used for the fetch more
  ///
  /// Throws an assertion error if the fetch more is in progress
  ///
  /// use [isAlreadyFetching] to check if the fetch more is in progress
  Map<String, dynamic> get requireFetchMoreParameters {
    assert(!isAlreadyFetching,
        'Fetch more parameters cannot be required while already fetching. Use isAlreadyFetching to check if fetch more is in progress.');
    return fetchMoreParameters!;
  }

  /// The duration of the fetch more operation
  ///
  /// Throws an assertion error if the fetch more is in progress
  ///
  /// use [isAlreadyFetching] to check if the fetch more is in progress
  Duration get requireFetchMoreDuration {
    assert(!isAlreadyFetching,
        'Fetch more duration cannot be required while already fetching. Use isAlreadyFetching to check if fetch more is in progress.');
    return fetchMoreDuration!;
  }

  /// The new data that was fetched from the server
  ///
  /// Throws an assertion error if the fetch more failed
  ///
  /// use [hasData] to check if the fetch more failed
  List<T> get requireNewData {
    assert(hasData,
        'New data cannot be required while fetch more is in progress or if fetch more failed. Use hasData to check if fetch more was successful.');
    return newData!;
  }

  /// The merged data after the fetch more
  ///
  /// The actual data in the datasource after the fetch more
  ///
  /// Throws an assertion error if the fetch more failed
  ///
  /// use [hasData] to check if the fetch more failed
  List<T> get requireMergedData {
    assert(hasData,
        'Merged data cannot be required while fetch more is in progress or if fetch more failed. Use hasData to check if fetch more was successful.');
    return mergedData!;
  }

  /// The error if the fetch more failed
  ///
  /// Throws an assertion error if the fetch more was successful
  /// or if the fetch more is in progress
  ///
  /// use [isFailure] to check if the fetch more failed
  Object get requireError {
    assert(isFailure,
        'Error cannot be required while fetch more is in progress or if fetch more was successful. Use isFailure to check if fetch more failed.');
    return error!;
  }

  /// Utility method to simplify the handling of [StaleMateFetchMoreResult]
  ///
  /// Arguments:
  /// - **success:** Called if the fetch more was successful and has data
  ///     - **mergedData:** The merged data after the fetch more
  ///     - **newData:** The new data that was fetched from the server
  ///    - **isDone:** True if there is no more data available
  /// - **failure:** Called if the fetch more failed
  ///    - **error:** The error that caused the fetch more to fail
  on({
    Function(List<T> mergedData, List<T> newData, bool isDone)? success,
    Function(Object error)? failure,
  }) {
    if (isFailure) {
      failure?.call(requireError);
    } else if (hasData) {
      success?.call(requireMergedData, requireNewData, isDone);
    }
  }

  /// Short hand for [StaleMateFetchMoreStatus.alreadyFetching]
  ///
  /// Use this to create a [StaleMateFetchMoreResult] with [StaleMateFetchMoreStatus.alreadyFetching]
  factory StaleMateFetchMoreResult.alreadyFetching() {
    return StaleMateFetchMoreResult(
      status: StaleMateFetchMoreStatus.alreadyFetching,
    );
  }

  /// Short hand for [StaleMateFetchMoreStatus.failure]
  ///
  /// Use this to create a [StaleMateFetchMoreResult] with [StaleMateFetchMoreStatus.failure]
  factory StaleMateFetchMoreResult.moreDataAvailable({
    required DateTime fetchMoreInitiatedAt,
    required Map<String, dynamic> queryParams,
    required List<T> newData,
    required List<T> mergedData,
  }) {
    return StaleMateFetchMoreResult(
      status: StaleMateFetchMoreStatus.moreDataAvailable,
      fetchMoreInitiatedAt: fetchMoreInitiatedAt,
      fetchMoreFinishedAt: DateTime.now(),
      fetchMoreParameters: queryParams,
      newData: newData,
      mergedData: mergedData,
    );
  }

  /// Short hand for [StaleMateFetchMoreStatus.done]
  ///
  /// Use this to create a [StaleMateFetchMoreResult] with [StaleMateFetchMoreStatus.done]
  factory StaleMateFetchMoreResult.done({
    required DateTime fetchMoreInitiatedAt,
    required Map<String, dynamic> queryParams,
    required List<T> newData,
    required List<T> mergedData,
  }) {
    return StaleMateFetchMoreResult(
      status: StaleMateFetchMoreStatus.done,
      fetchMoreInitiatedAt: fetchMoreInitiatedAt,
      fetchMoreFinishedAt: DateTime.now(),
      fetchMoreParameters: queryParams,
      newData: newData,
      mergedData: mergedData,
    );
  }

  /// Short hand for [StaleMateFetchMoreStatus.failure]
  ///
  /// Use this to create a [StaleMateFetchMoreResult] with [StaleMateFetchMoreStatus.failure]
  factory StaleMateFetchMoreResult.failure({
    required DateTime fetchMoreInitiatedAt,
    required Map<String, dynamic> queryParams,
    required Object error,
  }) {
    return StaleMateFetchMoreResult(
      status: StaleMateFetchMoreStatus.failure,
      fetchMoreInitiatedAt: fetchMoreInitiatedAt,
      fetchMoreFinishedAt: DateTime.now(),
      fetchMoreParameters: queryParams,
      error: error,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('StaleMateFetchMoreResult(');
    buffer.writeln('    status: $status,');
    buffer.writeln('    fetchMoreInitiatedAt: $fetchMoreInitiatedAt,');
    buffer.writeln('    fetchMoreFinishedAt: $fetchMoreFinishedAt,');
    buffer.writeln('    fetchMoreParameters: $fetchMoreParameters,');
    if (newData != null) {
      buffer.writeln('    newData(count: ${newData!.length}): [');
      for (final item in newData!) {
        buffer.writeln('      $item,');
      }
      buffer.writeln('    ],');
    }
    if (mergedData != null) {
      buffer.writeln('    mergedData(count: ${mergedData!.length}): [');
      for (final item in mergedData!) {
        buffer.writeln('      $item,');
      }
      buffer.writeln('    ],');
    }
    buffer.writeln('    error: $error,');
    buffer.writeln('    fetchMoreDuration: $fetchMoreDuration,');
    buffer.write(')');
    return buffer.toString();
  }
}
