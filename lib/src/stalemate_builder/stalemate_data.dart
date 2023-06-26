import 'package:flutter/widgets.dart';

/// A class that holds the data state of a StaleMateBuilder
///
/// This class can be used to decide what to show in the UI
/// based on the state of the data
///
/// States:
/// - [StaleMateDataState.loading] : The data is currently being loaded
/// - [StaleMateDataState.loaded] : The data has been loaded successfully
/// - [StaleMateDataState.error] : An error was thrown while loading the data
/// - [StaleMateDataState.empty] : The data is empty
///
/// The [StaleMateData.when] method can be used to handle the state of the data
/// in a more convenient way
///
/// See also:
/// - [StaleMateBuilder]
/// - [StaleMateDataState]
///
/// Example:
/// ```dart
/// StaleMateBuilder(
///  loader: loader,
///  builder: (context, data) {
///   // Retuern different widgets based on the state of the data
///   switch (data.state) {
///     case StaleMateDataState.loading:
///       return Text('Loading...');
///     case StaleMateDataState.loaded:
///       return Text('Data: ${data.data}');
///     case StaleMateDataState.empty:
///       return Text('Empty');
///     case StaleMateDataState.error:
///       return Text('Error: ${data.errorData}');
///   }
///
///   // Or use the convinient [StaleMateData.when] method
///   return data.when(
///     loading: () => Text('Loading...'),
///     data: (data) => Text('Data: $data'),
///     empty: () => Text('Empty'),
///     error: (error) => Text('Error: $error'),
/// );
/// ```
class StaleMateData<T> {
  /// The data that was loaded
  ///
  /// Null if no data was loaded
  ///
  /// Use [hasData] to check if the data is available
  final T? data;

  /// The error that was thrown while loading the data
  ///
  /// Null if no error was thrown
  ///
  /// Use [hasError] to check if the error is available
  final Object? errorData;

  /// The state of the data
  ///
  /// Available states:
  /// - [StaleMateDataState.loading]: The data is currently being loaded
  /// - [StaleMateDataState.loaded]: The data has been loaded successfully
  /// - [StaleMateDataState.error]: An error was thrown while loading the data
  /// - [StaleMateDataState.empty]: The data is empty
  final StaleMateDataState state;

  /// Creates a new [StaleMateData] object
  ///
  /// Arguments:
  /// - **data:** The data that was loaded (null if no data was loaded)
  /// - **errorData:** The error that was thrown while loading the data (null if no error was thrown)
  /// - **state:** The state of the data
  const StaleMateData({
    this.data,
    this.errorData,
    required this.state,
  });

  /// Indicates if the data is available
  bool get hasData => data != null;

  /// Indicates if the error is available
  bool get hasError => errorData != null;

  /// Returns the data
  ///
  /// Throws an assertion error if the data is not available
  ///
  /// Use [hasData] to check if the data is available
  T get requireData {
    assert(hasData,
        'Data cannot be required if it is null. Use hasData to check if data is available.');
    return data as T;
  }

  /// Returns the error
  ///
  /// Throws an assertion error if the error is not available
  ///
  /// Use [hasError] to check if the error is available
  Object get requireError {
    assert(hasError,
        'Error cannot be required if it is null. Use hasError to check if error is available.');
    return errorData!;
  }

  /// Indicates if the data is loading
  bool get isLoading => state == StaleMateDataState.loading;

  /// Indicates if the data is loaded
  bool get isLoaded => state == StaleMateDataState.loaded;

  /// Indicates if the data has an error
  bool get isError => state == StaleMateDataState.error;

  /// Indicates if the data is empty
  bool get isEmpty => state == StaleMateDataState.empty;

  /// Utility method to make it easier to render different widgets based on the state of the data
  ///
  /// All widgets are optional except for [data], which is required
  ///
  /// If no widget is provided for a specific state, the [fallback] widget will be rendered
  ///
  /// If the [fallback] widget is not provided, an empty container will be rendered
  ///
  /// Arguments:
  /// - **data:** The widget to render if the data is loaded
  /// - **error:** The widget to render if the data has an error
  /// - **empty:** The widget to render if the data is empty
  /// - **loading:** The widget to render if the data is loading
  /// - **fallback:** The widget to render if the state of the data is unknown or
  ///  if no other widget was provided
  ///
  /// Example:
  /// ```dart
  /// StaleMateBuilder(
  ///   loader: loader,
  ///   builder: (context, data) {
  ///     return data.when(
  ///       loading: () => Text('Loading...'),
  ///       data: (data) => Text('Data: $data'),
  ///       empty: () => Text('Empty'),
  ///       error: (error) => Text('Error: $error'),
  ///     );
  ///   }
  /// );
  /// ```
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
    final buffer = StringBuffer();
    buffer.writeln('StaleMateData{');
    buffer.writeln('    data: $data, ');
    buffer.writeln('    errorData: $errorData, ');
    buffer.writeln('    state: $state, ');
    buffer.write('}');
    return buffer.toString();
  }
}

/// The state of the data
///
/// Enum values:
/// - **loading:** The data is currently being loaded
/// - **loaded:** The data has been loaded successfully
/// - **error:** An error was thrown while loading the data
/// - **empty:** The data is empty
enum StaleMateDataState {
  loading,
  loaded,
  error,
  empty,
}
