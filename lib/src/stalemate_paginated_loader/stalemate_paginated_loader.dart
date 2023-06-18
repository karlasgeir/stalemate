part of '../stalemate_loader/stalemate_loader.dart';

/// A [StaleMateLoader] that supports pagination.
///
/// This loader is useful when you have data that needs to be loaded in pages.
///
/// The [StaleMatePaginatedLoader] supports everything that the [StaleMateLoader] supports
/// and its constructor arguments are mostly the same.
///
/// Difference from base [StaleMateLoader]:
/// - [paginationConfig] is required and it is used to load the data in pages.
///  - The [StaleMatePaginationConfig] is used to provide the params for the next page of data.
/// - [getRemoteData] should not be implemented, instead [getRemotePaginatedData] is required.
///     - The [getRemotePaginatedData] method is used to fetch the next page of data.
/// - [fetchMore] method is added to fetch more data from the server.
/// - [isFetchingMore] flag is added to indicate if fetch more is in progress.
///
/// See also:
/// - [StaleMatePaginationConfig]
/// - [StaleMatePagePagination]
/// - [StaleMateOffsetLimitPagination]
/// - [StaleMateCursorPagination]
/// - [StaleMateFetchMoreResult]
///
/// Example:
/// ```dart
/// class MyPaginatedLoader extends StaleMatePaginatedLoader<MyData> {
///   MyPaginatedLoader() : super(
///     paginationConfig: StaleMatePagePagination(
///       pageSize: 10,
///       zeroBasedIndexing: false,
///     );
///
///   @override
///   Future<List<MyData>> getRemotePaginatedData(Map<String, dynamic> paginationParams) async {
///     final pageSize = paginationParams['pageSize'];
///     final pageNumber = paginationParams['pageNumber'];
///
///     // Fetch the data from the server
///    }
/// }
///
/// final loader = MyPaginatedLoader();
///
/// // Load the first page of data
/// await loader.initialize();
///
/// // Fetch more data
/// final result = await loader.fetchMore();
/// result.on(
///   success: (mergedData, newData, isDone) {
///     // Datat is already in the data stream
///     // Do something with the data if needed
///   },
///   failure: (error) {
///     // Do something with the error
///   },
///);
///```
abstract class StaleMatePaginatedLoader<T> extends StaleMateLoader<List<T>> {
  /// Pagination config used to load the data in pages
  ///
  /// See also:
  /// - [StaleMatePaginationConfig]
  /// - [StaleMatePagePagination]
  /// - [StaleMateOffsetLimitPagination]
  /// - [StaleMateCursorPagination]
  final StaleMatePaginationConfig<T> paginationConfig;

  /// Indicates if fetch more is in progress
  bool isFetchingMore = false;

  /// Create a new [StaleMatePaginatedLoader] instance
  ///
  /// Used to load data in pages.
  ///
  /// Arguments:
  /// - **paginationConfig:** Pagination config used to load the data in pages
  /// - **updateOnInit:** If true, the loader will update the data stream on initialization
  /// - **showLocalDataOnError:** If true, the loader will show the local data on error
  /// - **refreshConfig:** Refresh config used to refresh the data
  StaleMatePaginatedLoader({
    required this.paginationConfig,
    super.updateOnInit,
    super.showLocalDataOnError,
    super.refreshConfig,
    super.logLevel,
  }) : super(emptyValue: const []);

  /// This method is called when the loader needs to fetch the next page of data from the server
  ///
  /// The [paginationParams] argument contains the params needed to fetch the next page of data
  ///
  /// Override this method to fetch the next page of data from the server based on the [paginationParams]
  ///
  /// The data returned from this method will be passed through the [StaleMatePaginationConfig.onReceivedData] method
  /// which handles merging the data and setting the [canFetchMore] flag
  ///
  /// Returns the page of data based on the [paginationParams]
  Future<List<T>> getRemotePaginatedData(Map<String, dynamic> paginationParams);

  /// This method is called when the loader is refreshed or initialized
  ///
  /// ** DO NOT OVERRIDE THIS METHOD **
  /// Instead override [getRemotePaginatedData] method
  /// If you absolutely need to override this method, make sure to call super
  /// and return the data returned from super
  /// This method is used to fetch the first page of data from the server
  /// The data returned from this method will be passed through the [StaleMatePaginationConfig.onReceivedData] method
  /// which handles merging the data and setting the [canFetchMore] flag
  ///
  /// Returns the first page of data
  @override
  Future<List<T>> getRemoteData() async {
    // Get remote data is only called on initial loading and refresh
    // In those cases we reset the pagination and get the first page of data
    paginationConfig.reset();
    final queryParams = paginationConfig.getQueryParams(
      0,
      null,
    );

    // The data returned from the server is passed through the [onReceivedData] method
    // which handles merging the data and setting the [canFetchMore] flag
    final data = await getRemotePaginatedData(queryParams);
    return paginationConfig.onReceivedData(data, []);
  }

  /// Fetch more data from the server
  ///
  /// This method is used to fetch the next page of data from the server
  ///
  /// The data returned from this method will be passed through the [StaleMatePaginationConfig.onReceivedData] method
  /// which handles merging the data and setting the [canFetchMore] flag
  ///
  /// Returns a [StaleMateFetchMoreResult] which can be used to handle the result of the fetch more operation
  /// The status of the fetch more operation can be checked using the [StaleMateFetchMoreResult.status] property
  /// - [StaleMateFetchMoreStatus.done] indicates that the fetch more was successful and there is no more data to fetch
  /// - [StaleMateFetchMoreStatus.moreDataAvailable] indicates that the fetch more was successful and there is more data to fetch
  /// - [StaleMateFetchMoreStatus.alreadyFetching] indicates that the fetch more is already in progress
  /// - [StaleMateFetchMoreStatus.error] indicates that the fetch more failed with an error
  ///
  /// Example:
  /// ```dart
  /// final result = await loader.fetchMore();
  ///
  /// // Check the status of the fetch more operation
  /// switch (result.status) {
  ///   case StaleMateFetchMoreStatus.done:
  ///     final data = result.requireData;
  ///     // do something when there is no more data to fetch
  ///     break;
  ///   case StaleMateFetchMoreStatus.moreDataAvailable:
  ///    final data = result.requireData;
  ///    // do something when there is more data to fetch
  ///     break;
  ///   case StaleMateFetchMoreStatus.alreadyFetching:
  ///     // Do something when fetch more is already in progress
  ///     break;
  ///   case StaleMateFetchMoreStatus.error:
  ///     final error = result.requireError;
  ///       // Do something with the error
  ///     break;
  ///  }
  ///
  ///  // Or use the on method
  /// result.on(
  ///   success: (mergedData, newData, isDone) {
  ///     // Do something on success
  ///   },
  ///   failure: (error) {
  ///     // Do something on error
  ///   },
  /// );
  /// ```
  Future<StaleMateFetchMoreResult<T>> fetchMore() async {
    if (paginationConfig.canFetchMore) {
      // If fetch more is already in progress, return already refreshing
      if (isFetchingMore) {
        return StaleMateFetchMoreResult<T>.alreadyFetching();
      }

      // Set is fetching more to true so that we don't call fetch more again
      isFetchingMore = true;

      final fetchMoreInitiatedAt = DateTime.now();

      // Retreive the next query params from the pagination config
      final queryParams = paginationConfig.getQueryParams(
        value.length,
        value.last,
      );

      try {
        // Get the new data from the implemented getRemotePaginatedData method
        final newData = await getRemotePaginatedData(queryParams);

        // The data returned from the server is passed through the [onReceivedData] method
        // which handles merging the data and setting the [canFetchMore] flag
        final mergedData = paginationConfig.onReceivedData(newData, value);

        // Add the merged data to the stream
        addData(mergedData);

        // If we can fetch more data, return more data available
        if (paginationConfig.canFetchMore) {
          return StaleMateFetchMoreResult<T>.moreDataAvailable(
            fetchMoreInitiatedAt: fetchMoreInitiatedAt,
            queryParams: queryParams,
            newData: newData,
            mergedData: mergedData,
          );
        }

        // If we can't fetch more data, return done
        return StaleMateFetchMoreResult<T>.done(
          fetchMoreInitiatedAt: fetchMoreInitiatedAt,
          queryParams: queryParams,
          newData: newData,
          mergedData: mergedData,
        );
      } catch (error) {
        // Tell the base loader to handle the error appropritaly
        _onRemoteDataError(error);

        // Return failure
        return StaleMateFetchMoreResult<T>.failure(
          fetchMoreInitiatedAt: fetchMoreInitiatedAt,
          queryParams: queryParams,
          error: error,
        );
      } finally {
        // Set is fetching more to false so that we can call fetch more again
        isFetchingMore = false;
      }
    } else {
      // We were done fetching more data before this request
      // This can happen if the user calls fetch more after the last page of data has been fetched
      // We include the fetch more parameters and the merged data in the result
      // We have no new data since no fetch more was initiated, so we return an empty list
      // We also return the fetchMoreInitiatedAt and fetchMoreFinishedAt times since the user would
      // expect those values to be set when the status is done
      return StaleMateFetchMoreResult<T>.done(
        fetchMoreInitiatedAt: DateTime.now(),
        queryParams: paginationConfig.getQueryParams(
          value.length,
          value.last,
        ),
        newData: [],
        mergedData: value,
      );
    }
  }

  @override
  Future<void> reset() {
    paginationConfig.reset();
    return super.reset();
  }
}
