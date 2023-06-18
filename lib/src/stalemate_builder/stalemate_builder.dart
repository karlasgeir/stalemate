import 'package:flutter/widgets.dart';
import 'package:stalemate/src/stalemate_builder/stalemate_data.dart';
import 'package:stalemate/stalemate.dart';

/// A builder that rebuild the UI based on the state of [StaleMateLoader]
///
/// This builder can be used to show different widgets based on the state of the
/// data
///
/// See also:
/// - [StaleMateLoader]
/// - [StaleMateData]
///
/// Example:
/// ```dart
/// StaleMateBuilder(
///  loader: loader,
///  builder: (context, data) {
///   // Return different widgets based on the state of the data
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
class StaleMateBuilder<T> extends StatelessWidget {
  /// The loader that provides the data
  ///
  /// The [StaleMateBuilder] will rebuild the UI based on the state of the data
  /// provided by the [StaleMateLoader.stream]
  final StaleMateLoader<T> loader;

  /// The builder that will be called when the data changes
  ///
  /// The [builder] will be called with the latest state of the data
  /// provided by the [loader]
  final Widget Function(BuildContext context, StaleMateData<T> data) builder;

  /// Creates a [StaleMateBuilder]
  ///
  /// Arguments:
  /// - **loader:** The loader that provides the data
  /// - **builder:** The builder that will be called when the data changes
  const StaleMateBuilder({
    Key? key,
    required this.loader,
    required this.builder,
  }) : super(key: key);

  /// Returns the [StaleMateData] based on the state of the [snapshot]
  /// provided by the [StaleMateLoader.stream]
  ///
  /// This method maps the state of the stream to the [StaleMateData] state
  StaleMateData<T> getData(AsyncSnapshot<T> snapshot) {
    if (snapshot.hasError) {
      return StaleMateData<T>(
          errorData: snapshot.error, state: StaleMateDataState.error);
    }
    if (snapshot.hasData && snapshot.data != loader.emptyValue) {
      return StaleMateData<T>(
          data: snapshot.requireData, state: StaleMateDataState.loaded);
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return StaleMateData<T>(state: StaleMateDataState.loading);
    }
    return StaleMateData<T>(state: StaleMateDataState.empty);
  }

  /// Builds the widget tree for the StaleMateBuilder.
  ///
  /// This method listens to changes in the loader's stream
  /// and rebuilds the UI by calling the builder function with the latest data state.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: loader.stream,
      builder: (context, snapshot) {
        return builder(
          context,
          getData(snapshot),
        );
      },
    );
  }
}
