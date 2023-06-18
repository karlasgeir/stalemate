/// The status of the fetch more operation
/// alreadyFetching: A fetch more operation is already in progress
/// moreDataAvailable: The fetch more operation was successful and more data is available
/// failure: The fetch more operation was unsuccessful
/// done: The fetch more operation was successful but no more data is available
enum StaleMateFetchMoreStatus {
  /// If fetch more data is called while already fetching, this status is returned
  /// Only one fetch more operation can be in progress at a time
  alreadyFetching,

  /// If the fetch more operation was successful and more data is available
  /// for another fetch more operation
  moreDataAvailable,

  /// If the fetch more operation was unsuccessful
  failure,

  /// If the fetch more operation was successful but no more data is available
  done,
}

class StaleMateFetchMoreResult<T> {
  /// The status of the fetch more operation
  /// alreadyFetching: A fetch more operation is already in progress
  /// moreDataAvailable: The fetch more operation was successful and more data is available
  /// failure: The fetch more operation was unsuccessful
  /// done: The fetch more operation was successful but no more data is available
  final StaleMateFetchMoreStatus status;

  /// The time at which the fetch more was initiated
  /// This is null if the fetch more is in progress
  final DateTime? fetchMoreInitiatedAt;

  /// The duration of the fetch more operation
  /// This is null if the fetch more is in progress
  final DateTime? fetchMoreFinishedAt;

  /// The parameters that were used to fetch more data
  /// This is null if the fetch more is in progress
  final Map<String, dynamic>? fetchMoreParameters;

  /// The new data if the fetch more was successful
  /// This is the data that was fetched from the server
  /// This data is not merged with the existing data
  /// Use [mergedData] to get the merged data
  /// This is null if the fetch more was unsuccessful or if fetch more is in progress
  /// If you call fetch more again after there are no more items, this will be an empty list
  final List<T>? newData;

  /// The merged data if the fetch more was successful
  /// This is the new data from the server merged with the existing data
  /// Use [newData] to just get the data that was fetched from the server
  /// This is null if the fetch more was unsuccessful or if fetch more is in progress
  final List<T>? mergedData;

  /// The error if the fetch more failed
  /// This is null if the fetch more was successful or if fetch more is in progress
  final Object? error;

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
  /// This is null if the fetch more is in progress
  Duration? get fetchMoreDuration {
    if (fetchMoreInitiatedAt == null || fetchMoreFinishedAt == null) {
      return null;
    }
    return fetchMoreFinishedAt!.difference(fetchMoreInitiatedAt!);
  }

  /// If true, the fetch more operation was successful and more data is available
  /// for another fetch more operation
  bool get moreDataAvailable =>
      status == StaleMateFetchMoreStatus.moreDataAvailable;

  /// If true, the fetch more operation was unsuccessful
  bool get isFailure => status == StaleMateFetchMoreStatus.failure;

  /// If true, the fetch more operation is already in progress
  bool get isAlreadyFetching =>
      status == StaleMateFetchMoreStatus.alreadyFetching;

  /// If true, the fetch more operation was successful but no more data is available
  bool get isDone => status == StaleMateFetchMoreStatus.done;

  /// If true, the fetch more operation was successful or if fetch more is in progress
  bool get hasData => moreDataAvailable || isDone;

  /// Same as [requireFetchMoreInitiatedAt] but throws an error if it is not available
  DateTime get requireFetchMoreInitiatedAt {
    assert(!isAlreadyFetching,
        'Fetch more initiated at cannot be required while already fetching. Use isAlreadyFetching to check if fetch more is in progress.');
    return fetchMoreInitiatedAt!;
  }

  /// Same as [requireFetchMoreFinishedAt] but throws an error if it is not available
  DateTime get requireFetchMoreFinishedAt {
    assert(!isAlreadyFetching,
        'Fetch more finished at cannot be required while already fetching. Use isAlreadyFetching to check if fetch more is in progress.');
    return fetchMoreFinishedAt!;
  }

  /// Same as [requireFetchMoreParameters] but throws an error if it is not available
  Map<String, dynamic> get requireFetchMoreParameters {
    assert(!isAlreadyFetching,
        'Fetch more parameters cannot be required while already fetching. Use isAlreadyFetching to check if fetch more is in progress.');
    return fetchMoreParameters!;
  }

  /// Same as [requireFetchMoreDuration] but throws an error if it is not available
  Duration get requireFetchMoreDuration {
    assert(!isAlreadyFetching,
        'Fetch more duration cannot be required while already fetching. Use isAlreadyFetching to check if fetch more is in progress.');
    return fetchMoreDuration!;
  }

  /// Same as [requireNewData] but throws an error if it is not available
  List<T> get requireNewData {
    assert(hasData,
        'New data cannot be required while fetch more is in progress or if fetch more failed. Use hasData to check if fetch more was successful.');
    return newData!;
  }

  /// Same as [requireMergedData] but throws an error if it is not available
  List<T> get requireMergedData {
    assert(hasData,
        'Merged data cannot be required while fetch more is in progress or if fetch more failed. Use hasData to check if fetch more was successful.');
    return mergedData!;
  }

  /// Same as [requireError] but throws an error if it is not available
  Object get requireError {
    assert(isFailure,
        'Error cannot be required while fetch more is in progress or if fetch more was successful. Use isFailure to check if fetch more failed.');
    return error!;
  }

  /// Utility method to handle the result of a fetch more operation
  /// calls [success] with the updated merged data if the refresh was successful
  /// it is called for both [StaleMateFetchMoreStatus.moreDataAvailable] and [StaleMateFetchMoreStatus.done]
  /// calls [failure] with the error if the refresh failed
  /// it is called for [StaleMateFetchMoreStatus.failure]
  /// There is no callback for [StaleMateFetchMoreStatus.alreadyFetching] since it should in most cases be ignored
  /// If you want more granular control, use [status] to check the status of the fetch more operation
  /// and use the corresponding getters to get the data
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

  /// Factory method to create a [StaleMateFetchMoreResult] with [StaleMateFetchMoreStatus.alreadyFetching]
  factory StaleMateFetchMoreResult.alreadyFetching() {
    return StaleMateFetchMoreResult(
      status: StaleMateFetchMoreStatus.alreadyFetching,
    );
  }

  /// Factory method to create a [StaleMateFetchMoreResult] with [StaleMateFetchMoreStatus.moreDataAvailable]
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

  // Factory method to create a [StaleMateFetchMoreResult] with [StaleMateFetchMoreStatus.done]
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

  /// Factory method to create a [StaleMateFetchMoreResult] with [StaleMateFetchMoreStatus.failure]
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
