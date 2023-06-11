import 'package:flutter/widgets.dart';

/// Utility class that simplifies the rendering of the UI based on the state of
/// the data.
/// The [when] method can be used to render the UI based on the state of the
/// data.
class StaleMateData<T> {
  /// The data that was loaded
  /// Will be null if the data has not been loaded yet
  final T? data;

  /// The error that was thrown while loading the data
  /// Will be null if no error was thrown
  final Object? errorData;

  /// The state of the data
  final StaleMateDataState state;

  const StaleMateData({
    this.data,
    this.errorData,
    required this.state,
  });

  bool get hasData => data != null;
  bool get hasError => errorData != null;

  /// Returns the data if it is available
  /// Throws an error if the data is not available
  /// Use [hasData] to check if the data is available
  T get requireData {
    assert(hasData,
        'Data cannot be required if it is null. Use hasData to check if data is available.');
    return data as T;
  }

  /// Returns the error if it is available
  /// Throws an error if the error is not available
  /// Use [hasError] to check if the error is available
  Object get requireError {
    assert(hasError,
        'Error cannot be required if it is null. Use hasError to check if error is available.');
    return errorData!;
  }

  bool get isLoading => state == StaleMateDataState.loading;
  bool get isLoaded => state == StaleMateDataState.loaded;
  bool get isError => state == StaleMateDataState.error;
  bool get isEmpty => state == StaleMateDataState.empty;

  Widget when({
    required Widget Function(T data) data,
    Widget Function(Object error)? error,
    Widget Function()? empty,
    Widget Function()? loading,
    Widget Function()? fallback,
  }) {
    if (isLoaded) {
      return data(requireData);
    }
    if (isError && error != null) {
      return error(requireError);
    }
    if (isEmpty && empty != null) {
      return empty();
    }
    if (isLoading && loading != null) {
      return loading();
    }

    if (fallback != null) {
      return fallback();
    }

    return Container();
  }

  @override
  String toString() {
    return 'StaleMateData{data: $data, errorData: $errorData, state: $state}';
  }
}

enum StaleMateDataState {
  loading,
  loaded,
  error,
  empty,
}
