import 'package:example/pages/paginated_loader_page/data/handlers/paginated_example_handler.dart';
import 'package:example/services/snack_bar_service.dart';
import 'package:example/widgets/app_page_button.dart';
import 'package:example/widgets/app_page_buttons.dart';
import 'package:flutter/material.dart';
import 'package:stalemate/stalemate.dart';

// Just a simple loading widget
Widget loadingIndicator(bool isShowing) => Container(
      height: 40,
      width: 40,
      padding: const EdgeInsets.all(12),
      child: isShowing
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox(),
    );

/// A widget that demonstrates the use of the [StaleMatePaginatedLoader] class to load paginated data
///
class PaginatedLoaderExampleWidget extends StatefulWidget {
  /// The pagination configuration that will be used by the loader
  /// It defines what parameters are used to load the data
  final StaleMatePagePagination<String> paginationConfig;

  /// Creates a new [PaginatedLoaderExampleWidget]
  /// Arguments:
  /// - **paginationConfig:** The pagination configuration that will be used by the loader
  ///     - [StaleMatePagePagination]: Page based configuration
  ///     - [StaleMateOffsetPagination]: Offset based configuration
  ///     - [StaleMateCursorPagination]: Cursor based configuration
  const PaginatedLoaderExampleWidget({
    super.key,
    required this.paginationConfig,
  });

  @override
  State<PaginatedLoaderExampleWidget> createState() =>
      _PaginatedLoaderExampleState();
}

/// The state of the [PaginatedLoaderExampleWidget]
///
/// This is just a simple example to show how to use the [StaleMatePaginatedLoader] class
class _PaginatedLoaderExampleState extends State<PaginatedLoaderExampleWidget> {
  /// Scroll controller
  ///
  /// Used to scroll to the top of the list when refreshing
  final ScrollController scrollController = ScrollController();

  final PaginatedExampleHandler handler = PaginatedExampleHandler();

  /// This is the loader that will be used throughout the page
  late StaleMatePaginatedLoader<String, PaginatedExampleHandler> loader;

  /// This is just a utility service to show snack bars
  late SnackBarService snackBarService;

  // These are just flags used to show when the loader is in a certain state
  // They are not required for the loader to work, it is just to show the state
  // of the loader in the UI of the example app
  bool refreshing = false;
  bool fetchingMore = false;

  /// The loader is initialized in the [initState] method
  @override
  void initState() {
    super.initState();

    // Initialize the snack bar service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      snackBarService = SnackBarService.of(context);
    });

    // Create the loader with the pagination configuration
    loader = StaleMatePaginatedLoader(
      handler: handler,
      paginationConfig: widget.paginationConfig,
      // The loader will use the [StaleMateLogLevel.debug] log level
      // This is just to show the logs in the console of the example app
      // The default level is [StaleMateLogLevel.none]
      // Nothing will log in release modes
      logLevel: StaleMateLogLevel.debug,
    );

    // The loader needs to be initialized before it shows any data
    loader.initialize();
  }

  /// The loader needs to be disposed when the widget is disposed
  @override
  void dispose() {
    // It is important to close the loader when it is no longer needed to avoid
    // memory leaks
    loader.close();
    super.dispose();
  }

  /// Perform refresh is called when the refresh button is pressed
  /// The [StaleMateLoader.refresh] method is used to refresh the loader
  /// When refreshing a paginated loader the pagination is reset, so the loader
  /// will only have the first page of data after the refresh
  performRefresh() async {
    // incidate in the UI that the loader is refreshing
    setState(() {
      refreshing = true;
    });

    // The refresh method can be awaited to know when the loader has finished
    (await loader.refresh()).on(
      success: (data) {
        snackBarService.show(
          'Refreshed successfully, the pagination was reset on refresh. The loader now only has ${data.length} items',
        );
      },
      failure: (error) {
        snackBarService.show(
          'Failed to refresh data with error: $error',
        );
      },
    );

    // Scroll to the top of the list when the refresh is finished
    // This is not required for the loader to work
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // incidate in the UI that the loader is no longer refreshing
    setState(() {
      refreshing = false;
    });
  }

  /// Perform fetch more is called when the fetch more button is pressed
  /// The [StaleMateLoader.fetchMore] method is used to fetch more data
  ///
  /// The fetch more method returns a [StaleMateFetchMoreResult] object that can be used
  /// to handle the result of the fetch more operation
  performFetchMore(bool withError) async {
    // incidate in the UI that the loader is fetching more data
    setState(() {
      fetchingMore = true;
    });

    // If the fetch more operation should fail, set the loader to throw an error
    // This would not be done in a real app, it is just to show the error handling
    // of the loader, the loader would through when a remote request fails
    if (withError) {
      handler.shouldThrowError = true;
    }

    // The fetchMore method can be awaited to know when the loader has finished
    // fetching more data
    // The fetchMore method returns a [StaleMateFetchMoreResult] object that can be used
    // to handle the result of the fetch more operation
    final fetchMoreResult = await loader.fetchMore();

    // reset the error flag
    handler.shouldThrowError = false;

    // The [StaleMateFetchMoreResult.on] is a utility method that can be used to handle
    // the result of the fetch more operation, but it is a simplified version of the
    // status handling
    // success: Called when the fetch more operation is successful, it receives the
    // merged data, the new data from the server and a flag indicating if there is more data to fetch
    // failure: Called when the fetch more operation fails, it receives the error
    fetchMoreResult.on(
      success: (mergedData, newData, isDone) {
        if (isDone) {
          snackBarService.show(
            'Fetched more data successfully, received ${newData.length} items. The total amount of items is now ${mergedData.length}. There is no more data to fetch',
          );
        } else {
          snackBarService.show(
            'Fetched more data successfully, received ${newData.length} items. The total amount of items is now ${mergedData.length}',
          );
        }
      },
      failure: (error) {
        snackBarService.show(
          'Failed to fetch more data with error: $error',
        );
      },
    );

    // You can also manually check the status ([StaleMateFetchMoreResult.status])
    // of the fetch more operation and receive the data or error
    // from the [StaleMateFetchMoreResult] object
    // If you want to handle the case where fetch more is called while it is still in progress
    // you can manually check that status
    if (fetchMoreResult.isAlreadyFetching) {
      // ignore: use_build_context_synchronously
      SnackBarService.of(context).show(
        'Could not fetch more, already fetching more data',
      );
    }

    // incidate in the UI that the loader is no longer fetching more data
    setState(() {
      fetchingMore = false;
    });
  }

  /// Perform reset is called when the reset button is pressed
  /// The [StaleMateLoader.reset] method is used to reset the loader
  /// When resetting a paginated loader the pagination is reset, so the loader
  /// will only have the first page of data after the reset
  resetLoader() {
    // The reset method clears all data from the loader and the local data source
    // if the [StaleMateLoader.removeLocalData] method was overridden
    loader.reset();
  }

  @override
  Widget build(BuildContext context) {
    return StaleMateBuilder<List<String>, PaginatedExampleHandler>(
      loader: loader,
      builder: (context, data) {
        return data.when(
          loading: () => Center(
            child: loadingIndicator(true),
          ),
          data: (data) => Column(
            children: [
              loadingIndicator(refreshing),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Center(child: Text(data[index])),
                    );
                  },
                ),
              ),
              loadingIndicator(fetchingMore),
              AppPageButtons(
                buttons: [
                  AppPageButton(
                    text: 'Fetch more',
                    onPressed: () => performFetchMore(false),
                  ),
                  AppPageButton(
                    text: 'Fetch more with error',
                    onPressed: () => performFetchMore(true),
                  ),
                  AppPageButton(
                    text: 'Refresh',
                    isLoading: refreshing,
                    onPressed: performRefresh,
                  ),
                  AppPageButton(
                    text: 'Reset',
                    onPressed: () => loader.reset(),
                  ),
                ],
              ),
            ],
          ),
          empty: () => Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('No data available'),
              loadingIndicator(refreshing),
              AppPageButton(
                text: 'Check again',
                isLoading: refreshing,
                onPressed: performRefresh,
              ),
            ],
          ),
          error: (error) => Text('Error: $error'),
        );
      },
    );
  }
}
