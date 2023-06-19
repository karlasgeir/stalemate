import 'stalemate_loader.dart';

/// Enum for the status of the [StaleMateLoader].
///
/// Enum values:
/// - **idle:** Loading hasn't started. Loader has been reset or hasn't been initialized
/// - **loading:** Loading is in progress.
/// - **loaded:** Loading completed successfully, data is available or empty
/// - **error:** Loading failed, error is available
enum StaleMateStatus {
  idle,
  loading,
  loaded,
  error,
}

/// Enum for the reason for loading the data
///
/// Enum values:
/// - **initial:** Initial load
/// - **refresh:** Refresh
/// - **fetchMore:** Fetch more
enum StaleMateFetchReason {
  initial,
  refresh,
  fetchMore,
}

/// This state includes two separate loading states:
/// - **localStatus:** Represents the loading status of the local data. This can be idle, loading, loaded, or error.
/// - **remoteStatus:** Represents the loading status of the remote data. This can also be idle, loading, loaded, or error.
///
/// Additionally, it includes a fetch reason, which can be initial, refresh, or fetchMore,
/// and two separate error fields, one for local and one for remote errors.
///
/// Use [StaleMateLoader.state] to check the status of the loader.
class StaleMateLoaderState {
  /// The status of the local data
  final StaleMateStatus localStatus;

  /// The status of the remote data
  final StaleMateStatus remoteStatus;

  /// The reason for loading the data
  final StaleMateFetchReason? fetchReason;

  /// The error that was thrown while loading the data, if any
  final Object? localError;

  /// The error that was thrown while loading the data
  /// from the remote data source
  final Object? remoteError;

  /// Creates a new [StaleMateLoaderState] object
  ///
  /// Arguments:
  /// - **localStatus:** The status of the local data
  /// - **remoteStatus:** The status of the remote data
  /// - **fetchReason:** The reason for loading the data (null if loading hasn't started)
  /// - **localError:** The error that was thrown while loading the local data (null if no error was thrown)
  /// - **remoteError:** The error that was thrown while loading the remote data (null if no error was thrown)
  StaleMateLoaderState({
    required this.localStatus,
    required this.remoteStatus,
    this.fetchReason,
    this.localError,
    this.remoteError,
  });

  /// Loader got remote data from an initial load
  bool get isInitalLoad => fetchReason == StaleMateFetchReason.initial;

  /// Loader got remote data after a refresh
  bool get isRefresh => fetchReason == StaleMateFetchReason.refresh;

  /// Loader got remote data after fetching more
  bool get isFetchMore => fetchReason == StaleMateFetchReason.fetchMore;

  /// Local data is loading
  bool get loadingLocal => localStatus == StaleMateStatus.loading;

  /// Remote data is loading
  bool get loadingRemote => remoteStatus == StaleMateStatus.loading;

  /// Data is loading
  ///
  /// This is true if either the local or remote data is loading
  bool get loading => loadingLocal || loadingRemote;

  /// Local data is loaded
  bool get loadedLocal => localStatus == StaleMateStatus.loaded;

  /// Remote data is loaded
  bool get loadedRemote => remoteStatus == StaleMateStatus.loaded;

  /// Data is loaded
  ///
  /// This is true if either the local or remote data is loaded
  bool get loaded => loadedLocal || loadedRemote;

  /// Local data has an error
  bool get hasLocalError => localStatus == StaleMateStatus.error;

  /// Remote data has an error
  bool get hasRemoteError => remoteStatus == StaleMateStatus.error;

  /// Data has an error
  ///
  /// This is true if either the local or remote data has an error
  bool get hasError => hasLocalError || hasRemoteError;

  /// Local data is idle
  bool get localIdle => localStatus == StaleMateStatus.idle;

  /// Remote data is idle
  bool get remoteIdle => remoteStatus == StaleMateStatus.idle;

  /// Data is idle
  ///
  /// This is true if both the local and remote data is idle
  bool get isIdle => localIdle && remoteIdle;

  /// Returns the local error
  ///
  /// Throws an assertion error if there is no local error
  ///
  /// Use [hasLocalError] to check if there is an error
  Object get requireLocalError {
    assert(
      hasLocalError,
      'Cannot require local error when there is none, use hasLocalError to check if there is an error',
    );
    return localError!;
  }

  /// Returns the remote error
  ///
  /// Throws an assertion error if there is no remote error
  ///
  /// Use [hasRemoteError] to check if there is an error
  Object get requireRemoteError {
    assert(
      hasRemoteError,
      'Cannot require remote error when there is none, use hasRemoteError to check if there is an error',
    );
    return remoteError!;
  }

  /// Returns the fetch reason
  ///
  /// Throws an assertion error if there is no fetch reason
  ///
  /// Use [remoteIdle] to check if there is a reason
  StaleMateFetchReason get requireFetchReason {
    assert(
      !remoteIdle,
      'Cannot require fetch reason when there is none, use remoteIdle to check if there is a reason',
    );
    return fetchReason!;
  }

  factory StaleMateLoaderState.initial() {
    return StaleMateLoaderState(
      localStatus: StaleMateStatus.idle,
      remoteStatus: StaleMateStatus.idle,
    );
  }

  /// Change the local status
  ///
  /// Arguments:
  /// - **status:** The new status
  /// - **error:** The error that was thrown while loading the data (null if no error was thrown)
  StaleMateLoaderState copyWithLocalStatus(
    StaleMateStatus status, {
    Object? error,
  }) {
    return StaleMateLoaderState(
      localStatus: status,
      remoteStatus: remoteStatus,
      fetchReason: fetchReason,
      localError: error,
      remoteError: remoteError,
    );
  }

  /// Change the remote status
  /// Arguments:
  /// - **status:** The new status
  /// - **fetchReason:** The reason for loading the data (null if loading hasn't started)
  /// - **error:** The error that was thrown while loading the data (null if no error was thrown)
  StaleMateLoaderState copyWithRemoteStatus(
    StaleMateStatus status, {
    StaleMateFetchReason? fetchReason,
    Object? error,
  }) {
    return StaleMateLoaderState(
      localStatus: localStatus,
      remoteStatus: status,
      fetchReason: fetchReason ?? this.fetchReason,
      localError: localError,
      remoteError: error,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('StaleMateLoaderState(');
    buffer.writeln('  localStatus: $localStatus,');
    buffer.writeln('  remoteStatus: $remoteStatus,');
    buffer.writeln('  fetchReason: $fetchReason,');
    buffer.writeln('  localError: $localError,');
    buffer.writeln('  remoteError: $remoteError,');
    buffer.writeln(')');
    return buffer.toString();
  }
}
