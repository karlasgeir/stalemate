import 'package:example/pages/initialization_refresh/loaders/simple_stale_mate_loader.dart';
import 'package:example/pages/initialization_refresh/widgets/initialization_refresh_emty_state.dart';
import 'package:example/pages/initialization_refresh/widgets/initialization_refresh_error_state.dart';
import 'package:example/widgets/base_app_page.dart';
import 'package:flutter/material.dart';
import 'package:stalemate/stalemate.dart';

import '../../services/snack_bar_service.dart';
import 'widgets/initialization_refresh_data_state.dart';
import 'widgets/initialization_refresh_loading_state.dart';

/// This page demonstrates how to use the [SimpleStaleMateLoader] to
/// initialize and refresh data.
///
/// The loader is initialized in the [initState] method
class InitializationRefresh extends StatefulWidget {
  const InitializationRefresh({super.key});

  @override
  State<InitializationRefresh> createState() => _InitializationRefreshState();
}

class _InitializationRefreshState extends State<InitializationRefresh> {
  // The loader that provides the data
  final loader = SimpleStaleMateLoader(
    // The log level is set to debug to show the logs in the console
    // Debug is very verbose and can be turned off if preferred
    // The default value is [StaleMateLogLevel.none]
    // Nothing will log in release mode
    logLevel: StaleMateLogLevel.debug,
  );

  /// State variables to track the state of the loader,
  /// so that the UI can be updated accordingly

  /// Loader is currently initializing
  bool initializing = false;

  /// Loader is currently refreshing
  bool refreshing = false;

  /// Loader is currently refreshing with an error
  /// This is not a state that you would normally track in an
  /// application, but it is tracked here to be able to show
  /// different messages when we know we are going to get an error
  bool errorRefreshing = false;

  /// Combined state variable to track if the loader is currently loading
  bool get isLoading => initializing || refreshing || errorRefreshing;

  /// When the widget is disposed of, the loader should be closed
  @override
  void dispose() {
    // It is important to close the loader when it is no longer needed to avoid
    // memory leaks
    loader.close();
    super.dispose();
  }

  /// The loader is initialized with the push of a button
  /// However, if you want it to be initialized when the widget is first built,
  /// you can call the [StaleMateLoader.initialize] method in the [initState] method
  initializeLoader() async {
    // Update the state to show that the loader is currently initializing
    setState(() {
      initializing = true;
    });

    // The initialize method can be awaited to know when the loader is ready
    // If the loader has local data available, it will be returned immediately
    // and theh remote data will be fetched subsequently if the [StaleMateLoader.updateOnInit] is set to true
    // If the loader does not have local data available, the remote data will be fetched immediately
    // irrespective of the [StaleMateLoader.updateOnInit] value
    await loader.initialize();

    // Update the state to show that the loader is no longer initializing
    setState(() {
      initializing = false;
    });
  }

  /// The loader is refreshed with the push of a button
  ///
  /// The [StaleMateLoader.refresh] method can be called to refresh the data
  ///
  /// The [StaleMateLoader.refresh] method can be awaited to know when the loader has finished
  /// refreshing the data
  ///
  /// The [StaleMateLoader.refresh] method returns a [StaleMateRefreshResult] object that can be used
  /// to handle the result of the refresh operation
  Future<bool> performRefresh() async {
    final result = await loader.refresh();

    // You can use the [StaleMateRefreshResult.on] method to handle the result of
    // the refresh operation, especially useful if you want to show a message to the user
    result.on(
      success: (data) {
        SnackBarService.of(context).show(
          'Refreshed data successfully: $data',
        );
      },
      failure: (error) {
        SnackBarService.of(context).show(
          'Failed to refresh data with error: $error',
        );
      },
    );

    // You could also just look at the status of the result to determine if the
    // refresh was successful or not
    switch (result.status) {
      case StaleMateRefreshStatus.success:
        // do someting on success
        break;
      case StaleMateRefreshStatus.failure:
        // do someting on failure
        break;
      case StaleMateRefreshStatus.alreadyRefreshing:
        // do someting if already refreshing
        break;
    }

    // You can also just check if the refresh was successful or not
    return result.isSuccess;
  }

  /// This is a helper method that can be used to refresh the loader
  /// It is used to manage the refreshing state of the loader
  refreshLoader() async {
    setState(() {
      refreshing = true;
    });
    await performRefresh();
    setState(() {
      refreshing = false;
    });
  }

  /// This is a helper method that can be used to refresh the loader with an error
  ///
  /// It configures the loader to simulate an error during the refresh operation
  /// and then calls the [refreshLoader] method to refresh the loader
  refreshLoaderWithError() async {
    setState(() {
      errorRefreshing = true;
    });
    // This is not a method that is available on the loader, it is just a flag
    // that is used to simulate an error during the refresh operation
    loader.shouldThrowError = true;
    await performRefresh();
    loader.shouldThrowError = false;
    setState(() {
      errorRefreshing = false;
    });
  }

  /// The loader is reset with the push of a button
  ///
  /// The [StaleMateLoader.reset] method can be called to reset the loader
  /// - The data in the loader will be cleared
  /// - The local data will be removed
  resetLoader() {
    loader.reset();
  }

  @override
  Widget build(BuildContext context) {
    return BaseAppPage(
      title: 'Initialization and Refresh',
      // The StaleMateBuilder widget is used to build the UI based on the state
      // of the loader
      // There is no need to use it, it is possible to just use a StreamBuilder
      // widget to build the UI based on the [StaleMateLoader.stream], or even
      // use the [StaleMateLoader.stream] directly in the UI
      // The StaleMateBuilder widget is just a utility widget that makes it
      // easier to build the UI based on the state of the loader
      body: StaleMateBuilder<String>(
        loader: loader,
        builder: (context, data) {
          // The StaleMateBuilder widget provides the data as a [StaleMateData]
          // object that can be used to build the UI based on the state of the
          // loader
          // You can manually check the state of the data using the [StaleMateData.state]
          // property, or you can use the utility methods provided by the [StaleMateData]
          // object to check the state of the data
          // The [StaleMateData.when] method is also a convinient method to build the UI based on
          // the state of the data
          return data.when(
            loading: () => InitializationRefreshLoadingState(
              initializeLoader: initializeLoader,
              initializing: initializing,
            ),
            data: (data) => InitializationRefreshDataState(
              refreshLoader: refreshLoader,
              refreshLoaderWithError: refreshLoaderWithError,
              resetLoader: resetLoader,
              initializing: initializing,
              refreshing: refreshing,
              errorRefreshing: errorRefreshing,
              isLoading: isLoading,
              data: data,
            ),
            empty: () => InitializationRefreshEmptyState(
              refreshLoader: refreshLoader,
              refreshLoaderWithError: refreshLoaderWithError,
              refreshing: refreshing,
              errorRefreshing: errorRefreshing,
              isLoading: isLoading,
            ),
            error: (error) => InitializationRefreshErrorState(
              refreshLoader: refreshLoader,
              resetLoader: resetLoader,
              refreshing: refreshing,
              errorRefreshing: errorRefreshing,
              isLoading: isLoading,
              error: error,
            ),
          );
        },
      ),
    );
  }
}
