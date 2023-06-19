# StaleMate example app

This app is designed to showcase the features of the StaleMate library, a versatile tool for handling data retrieval and caching in Flutter applications. The examples here demonstrate how you can utilize StaleMate's functionality to manage data from various sources and cache it for efficient use.

StaleMate addresses key challenges faced in Flutter data management, such as initial loading, refreshing, error handling, and paginating data. This app provides practical code snippets demonstrating the application of the StaleMate library in different scenarios.

> Currently, there are only two examples that show basic functionality, but the plan is to add more soon. The next example added will probably be a simple TODO list.

**The current examples are:**

- **Example 1:** Simple Data Loading: This example details the usage of the core functionality of the StaleMate library with a custom loader, SimpleStaleMateLoader. This loader retrieves data from either a local source or a remote source and demonstrates initial loading, refreshing, and error handling.
- **Example 2:** Using StaleMatePaginatedLoader to paginate data: This example outlines the process of handling paginated data with the StaleMatePaginatedLoader. This is especially useful when dealing with large datasets that need to be paginated

## Example 1: Simple Data Loading

This example demonstrates the core functionality of the StaleMate library using a simple StaleMateLoader that retrieves data either from a local source or a remote source.

In this example, we create a loader called SimpleStaleMateLoader, an extension of the StaleMateLoader with a String datatype. This loader mimics both local and remote data sources.

You can find the full implementation of **SimpleDataLoader** here: [SimpleDataLoader](lib/pages/initialization_refresh/loaders/simple_stale_mate_loader.dart)

Here is a simplified version:

```dart
import 'package:stalemate/stalemate.dart';


class SimpleStaleMateLoader extends StaleMateLoader<String> {
  // A varible that holds the "local data"
  // This is to simulate storing the data locally
  String _localData = 'initial local data';

  SimpleStaleMateLoader() : super(
          // The empty value is used to determine if the data is empty.
          // The empty value depends on the data type
          // Since the data type is a String, it is an empty string,
          // For arrays use empty array, for nullable values null, etc.
          emptyValue: '',
        );

  /// This is where you retrieve your local data
  /// Just override this method and return the data
  @override
  Future<String> getLocalData() async {
    // Here you could retrieve the local data, using Hive, Isar, Shared preferences, etc.
    // For this example, we just return the local data variable
    return _localData;
  }


  /// This is where you retrieve your remote data
  /// just override this methodto retrieve the remote data
  @override
  Future<String> getRemoteData() async {
    // Here you would call any remote data, retrieving the data from the server

    // To simulate the data retrieval we can just delay and return the data
    Future.wait(const Duration(seconds: 3));
    return 'Remote data';
  }

  /// This is where the local data is stored
  /// Just override this method to store the
  /// local data
  @override
  Future<void> storeLocalData(String data) async {
    // Here you would store the local data, using Hive, Isar, Shared preferences, etc.
    // For this example, we just set the local data
    _localData = data;
  }

  /// Here you would clear the local data
  /// It is called when the loader is reset
  /// and you want to clear all remaining
  /// data from the storage
  @override
  Future<void> removeLocalData() async {
   /// Here you would remove the local data from Hive, Isar, Shared preferences, etc.
   // For this example, we just set the local data to empty
   _localData = '';
  }
}
```

This loader is used in our InitializationRefresh page, which shows different UI states based on the data's state. This demonstrates how to handle initial loads, refreshing, and errors.

For the full implementation, see: [InitializationRefresh](lib/pages/initialization_refresh/initalization_refresh.dart).

Here is a simplified version of the widget

```dart
class _InitializationRefreshState extends State<InitializationRefresh> {
  final loader = SimpleStaleMateLoader();

  /// When the widget is disposed of, the loader should be closed
  @override
  void dispose() {
    // It is important to close the loader when it is no longer needed to avoid
    // memory leaks
    loader.close();
    super.dispose();
  }

  @override
  void initState() {
    loader.initialize();
  }

  Future<bool> refreshLoader() async {
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

  resetLoader() {
    loader.reset();
  }

  @override
  Widget build(BuildContext context) {
    return BaseAppPage(
      title: 'Initialization and Refresh',
      body: StaleMateBuilder<String>(
        loader: loader,
        builder: (context, data) {
          return data.when(
            loading: () => InitializationRefreshLoadingState(),
            data: (data) => InitializationRefreshDataState(
              refreshLoader: refreshLoader,
              resetLoader: resetLoader,
              data: data,
            ),
            empty: () => InitializationRefreshEmptyState(
               refreshLoader: refreshLoader,
            ),
            error: (error) => InitializationRefreshErrorState(
              refreshLoader: refreshLoader,
              resetLoader: resetLoader,
              error: error,
            ),
          );
        },
      ),
    );
  }
}
```

## Example 2: Using StaleMatePaginatedLoader to paginate data

This example demonstrates the use of **StaleMatePaginatedLoader** in a typical Flutter widget. The loader helps to manage paginated data in your application.

We begin by creating a loader that implements data loading and pagination.

For the full implementation, see: [PaginatedExampleLoader](lib/pages/paginated_loader_page/data/loaders/paginated_example_loader.dart)

Here is a simplified version:

```dart
class PaginatedExampleLoader extends StaleMatePaginatedLoader<String> {
  /// A remote datasource that can handle paginated data
  final RemoteDatasource remoteDatasource;

  PaginatedExampleLoader({
    required this.remoteDatasource,
  }) : (
    // Configure what kind of pagination the server supports
    // Built in pagination options:
    // - StaleMatePagePagination: Page based pagination
    // - StaleMateOffsetLimitPagination : Offset/limit based pagination
    // - StaleMateCursorPagination: Cursor based pagination
    paginationConfig: StaleMatePagePagination(
        // Size of each page
        pageSize: 10,
        // Indicates whether the first page is 0 or 1
        zeroBasedIndexing: false,
    )
  );

  /// Override the getRemotePaginated data
  @override
  Future<List<String>> getRemotePaginatedData(
    Map<String, dynamic> paginationParams,
  ) async {
    // The params received here depend on the pagination config passed
    final page = paginationParams['page'] as int;
    final pageSize = paginationParams['pageSize'] as int;
    return _remoteDatasource.getItems(page, pageSize);
  }
}
```

An example of how to use the paginated loader can be found in [PaginatedLoaderExampleWidget](lib/pages/paginated_loader_page/widgets/paginated_loader_example_widget.dart)

Here is a simplified example:

```dart

class _PaginatedLoaderExampleState extends State<PaginatedLoaderExampleWidget> {
  /// This is the loader that will be used throughout the page
  PaginatedExampleLoader loader = PaginatedExampleLoader(
        remoteDatasource: // pass remote datasource
    );

  /// The loader needs to be initialized before it can show data
  @override
  void initState() {
    super.initState();

    loader.initialize();
  }

  /// The loader needs to be disposed when the widget is disposed
  @override
  void dispose() {
    loader.close();
    super.dispose();
  }

  /// Refreshing is identical to normal [StaleMateLoader]s
  /// Note that, when a paginated loader is reset, the pagination
  // is reset and it will only have the first page of data
  performRefresh();

  performFetchMore() async {
    // Call fetch more to load the next page of data
    final fetchMoreResult = await loader.fetchMore();

    // Fetch more is done and the merged data is already in the data stream.

    // You can check the status of the fetch more result to handle different scenarios
    switch(fetchMoreResult.status) {
      case StaleMateFetchMoreStatus.alreadyFetching:
        // Do something when the loader is already fetching more data
        break;
      case StaleMateFetchMoreStatus.failure:
        final error = fetchMoreResult.requireError;
        // Do something when the fetch more operation fails
        break;
      case StaleMateFetchMoreStatus.moreDataAvailable:
        final newData = fetchMoreResult.requiredNewData;
        final mergedData = fetchMoreResult.requireMergedData;
        // Do something when there is more data available
        break;
      case StaleMateFetchMoreStatus.done:
        final newData = fetchMoreResult.requiredNewData;
        final mergedData = fetchMoreResult.requireMergedData;
        // Do something when there is no more data available
        break;
    }

    // You can also use the [StaleMateFetchMoreResult.on] utility method
    fetchMoreResult.on(
      success: (mergedData, newData, isDone) {
        // Could show a snack bar on success
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
        // Could show a snack bar on error
        snackBarService.show(
          'Failed to fetch more data with error: $error',
        );
      },
    );

    // The "on" method does not handle already fetching, but you can
    // check it like this
    if (fetchMoreResult.isAlreadyFetching) {
      SnackBarService.of(context).show(
        'Could not fetch more, already fetching more data',
      );
    }
  }

  // Same as the normal loader
  // Note that when a paginated loader is reset,
  // the pagination is also reset
  resetLoader()

  @override
  Widget build(BuildContext context) {
    return StaleMateBuilder<List<String>>(
      loader: loader,
      builder: (context, data) {
        // Use the [StaleMateData.when] method to
        // return different widgets based on the state of the data
        return data.when(
          loading: () => Center(
            child: loadingIndicator(true),
          ),
          data: (data) => Column(
            children: [
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
              AppPageButtons(
                buttons: [
                  AppPageButton(
                    text: 'Fetch more',
                    onPressed: performFetchMore,
                  ),
                  AppPageButton(
                    text: 'Refresh',
                    isLoading: refreshing,
                    onPressed: performRefresh,
                  ),
                  AppPageButton(
                    text: 'Reset',
                    onPressed: resetLoader,
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

```
