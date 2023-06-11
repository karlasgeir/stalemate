import 'package:flutter/widgets.dart';
import 'package:stalemate/src/stalemate_builder/stalemate_data.dart';
import 'package:stalemate/stalemate.dart';

/// StaleMateBuilder is a widget that builds itself based on the latest state
/// of the data provided by the StaleMateLoader.
/// The builder provides a [StaleMateData] object that can be used to render
/// the UI based on the state of the data.
class StaleMateBuilder<T> extends StatelessWidget {
  /// The loader that will be used to load the data
  final StaleMateLoader<T> loader;

  /// The builder that provides the [StaleMateData] object
  final Widget Function(BuildContext context, StaleMateData<T> data) builder;

  const StaleMateBuilder({
    Key? key,
    required this.loader,
    required this.builder,
  }) : super(key: key);

  /// Returns a [StaleMateData] object based on the latest state of the data
  /// provided by the [loader]
  StaleMateData<T> getData(AsyncSnapshot<T> snapshot) {
    if (snapshot.hasError) {
      return StaleMateData<T>(
          errorData: snapshot.error, state: StaleMateDataState.error);
    }
    if (snapshot.hasData) {
      return StaleMateData<T>(
          data: snapshot.requireData, state: StaleMateDataState.loaded);
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return StaleMateData<T>(state: StaleMateDataState.loading);
    }
    return StaleMateData<T>(state: StaleMateDataState.empty);
  }

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
