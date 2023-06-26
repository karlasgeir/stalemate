# StaleMate example app

This app is designed to showcase the features of the StaleMate library, a versatile tool for handling data retrieval and caching in Flutter applications. The examples here demonstrate how you can utilize StaleMate's functionality to manage data from various sources and cache it for efficient use.

StaleMate addresses key challenges faced in Flutter data management, such as initial loading, refreshing, error handling, and paginating data. This app provides practical code snippets demonstrating the application of the StaleMate library in different scenarios.

> Currently, there are only two examples that show basic functionality, but the plan is to add more soon. The next example added will probably be a simple TODO list.

**The current examples are:**

- **Example 1:** Simple Usage: This example details the usage of the core functionality of the StaleMate library with a custom loader, SimpleStaleMateLoader. This loader retrieves data from either a local source or a remote source and demonstrates initial loading, refreshing, and error handling.
- **Example 2:** Using StaleMatePaginatedLoader to paginate data: This example outlines the process of handling paginated data with the StaleMatePaginatedLoader. This is especially useful when dealing with large datasets that need to be paginated

## Example 1: Simple Data Loading

This example demonstrates the core functionality of the StaleMate library using a simple StaleMateLoader that retrieves data either from a local source or a remote source.

In this example, we create a loader called SimpleStaleMateLoader, an extension of the StaleMateLoader with a String datatype. This loader mimics both local and remote data sources.

You can find the full implementation of **SimpleStaleMateHandler** here: [SimpleStaleMateHandler](lib/pages/simple_usage/handlers/simple_stale_mate_handler.dart)

Here is a slightly simplified version:

```dart
class SimpleStaleMateHandler extends StaleMateHandler<String> {
  String _localData = 'initial local data';
  int timesUpdatedFromRemote = 0;

  /// You need to provide the empty value,
  /// in this case an empty string
  @override
  String get emptyValue => '';

  /// This is the method that is called to get the local data.
  ///
  /// Usually this would be used to call a local database or cache.
  ///
  /// In this case, it just simulates a local data source by returning
  /// the `_localData` property.
  @override
  Future<String> getLocalData() async {
    return _localData;
  }

  /// This is the method that is called to get the remote data.
  ///
  /// Usually this would be used to call an API.
  ///
  /// In this case, it just simulates a remote data source by returning
  /// a string after a 5 second delay.
  @override
  Future<String> getRemoteData() async {
    await Future.delayed(const Duration(seconds: 5));
    return 'Remote data after ${++timesUpdatedFromRemote} updates';
  }

  /// This is the method that is called to store the local data.
  ///
  /// Usually this would be used to store the data in a local database or cache.
  ///
  /// In this case, it just simulates a local data source by setting
  /// the `_localData` property.
  @override
  Future<void> storeLocalData(String data) async {
    _localData = data;
  }

  /// This is the method that is called to remove the local data.
  ///
  /// Usually this would be used to remove the data from a local database or cache.
  ///
  /// In this case, it just simulates a local data source by setting
  /// the `_localData` property to an empty string.
  @override
  Future<void> removeLocalData() async {
    timesUpdatedFromRemote = 0;
    _localData = '';
  }
}

```

This loader is used in our SimpleUsage page, which shows different UI states based on the data's state. This demonstrates how to handle initial loads, refreshing, and errors.

For the full implementation, see: [SimpleUsage](lib/pages/simple_usage/simple_usage.dart).

Here is stripped down version:

```dart
// ...
// Widget implementation
// ...
//
class _InitializationRefreshState extends State<InitializationRefresh> {
  final StaleMateLoader<String, SimpleStaleMateHandler> loader = StaleMateLoader(
      handler: SimpleStaleMateHandler(),
    );

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

This example demonstrates the use of **StaleMatePaginatedHandlerMixin** and the **StaleMatePaginatedLoader** in a typical Flutter widget. The loader helps to manage paginated data in your application.

We begin by creating a handler that configures how to fetch the paginated data

For the full implementation, see: [PaginatedExampleLoader](lib/pages/paginated_loader_page/data/loaders/paginated_example_loader.dart)

Here is a simplified version:

```dart
class PaginatedExampleHandler extends RemoteOnlyStaleMateHandler<List<String>>
    // Use the PaginatedHandlerMixin to get the pagination functionality
    with
        PaginatedHandlerMixin<String> {

  final PaginatedExampleRemoteDatasource _remoteDatasource =
      PaginatedExampleRemoteDatasource();

  /// Provides an empty value for when the loader is reset
  /// and to determine if the loader is empty
  @override
  List<String> get emptyValue => [];

   /// Override the getRemotePaginated data
  @override
  Future<List<String>> getRemotePaginatedData(
    Map<String, dynamic> paginationParams,
  ) async {
    // The params received here depend on the pagination config passed
    // to the Paginated loader
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
  final StaleMatePaginatedLoader<String, PaginatedExampleHandler> loader = StaleMatePaginatedLoader(
    handler: PaginatedExampleHandler(
        remoteDatasource: // pass remote datasource
    ),
    paginationConfig: StaleMatePagePagination(
      pageSize: 10,
      zeroBasedIndexing: false,
    ),
  );


  performRefresh() async {
    // Refreshing is identical to normal [StaleMateLoader]s
    // Note that, when a paginated loader is reset, the pagination
    // is reset and it will only have the first page of data
  }

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


  resetLoader() {
    // Same as the normal loader
    // Note that when a paginated loader is reset,
    // the pagination is also reset
  }

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
