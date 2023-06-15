import 'package:example/pages/initialization_refresh/loaders/simple_stale_mate_loader.dart';
import 'package:example/pages/initialization_refresh/widgets/initialization_refresh_emty_state.dart';
import 'package:example/pages/initialization_refresh/widgets/initialization_refresh_error_state.dart';
import 'package:example/widgets/base_app_page.dart';
import 'package:flutter/material.dart';
import 'package:stalemate/stalemate.dart';

import '../../services/snack_bar_service.dart';
import 'widgets/initialization_refresh_data_state.dart';
import 'widgets/initialization_refresh_loading_state.dart';

class InitializationRefresh extends StatefulWidget {
  const InitializationRefresh({super.key});

  @override
  State<InitializationRefresh> createState() => _InitializationRefreshState();
}

class _InitializationRefreshState extends State<InitializationRefresh> {
  // This is the loader that will be used throughout the page
  /// The loader is not initialized automatically, so we need to initialize it
  /// manually before it starts loading data
  /// If you know that the loader can initialize as soon as the page is loaded,
  /// you can call this method in the initState() method
  final loader = SimpleStaleMateLoader();

  // These are just flags used to show when the loader is in a certain state
  // They are not required for the loader to work, it is just to show the state
  // of the loader in the UI of the example app
  bool initializing = false;
  bool refreshing = false;
  bool errorRefreshing = false;

  bool get isLoading => initializing || refreshing || errorRefreshing;

  @override
  void dispose() {
    // It is important to close the loader when it is no longer needed to avoid
    // memory leaks
    loader.close();
    super.dispose();
  }

  initializeLoader() async {
    setState(() {
      initializing = true;
    });
    // The initialize method can be awaited to know when the loader is ready
    // If the loader has local data available, it will be returned immediately
    // and theh remote data will be fetched subsequently if the [StaleMateLoader.updateOnInit] is set to true
    // If the loader does not have local data available, the remote data will be fetched immediately
    // irrespective of the [StaleMateLoader.updateOnInit] value
    await loader.initialize();
    setState(() {
      initializing = false;
    });
  }

  performRefresh() async {
    // The refresh method can be awaited to know when the loader has finished
    // refreshing the data
    // The refresh method returns a [StaleMateRefreshResult] object that can be used
    // to handle the result of the refresh operation
    // The [StaleMateRefreshResult.on] is a utility method that can be used to handle
    // the result of the refresh operation
    (await loader.refresh()).on(
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
  }

  refreshLoader() async {
    setState(() {
      refreshing = true;
    });
    await performRefresh();
    setState(() {
      refreshing = false;
    });
  }

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

  resetLoader() {
    // The reset method clears all data from the loader and the local data source
    // if the [StaleMateLoader.removeLocalData] method was overridden
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
