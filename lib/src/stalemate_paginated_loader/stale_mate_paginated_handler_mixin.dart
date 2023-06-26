import 'package:async/async.dart';

import '../stalemate_loader/stalemate_loader.dart';
import 'stale_mate_fetch_more_result.dart';
import 'stalemate_pagination_config.dart';

/// A mixin that can be used to enable pagination in a [StaleMateHandler]
/// 
/// This mixin is used by the [StaleMatePaginatedLoader] class
/// 
/// When used, instead of overriding the [StaleMateHandler.getRemoteData] method,
/// the [PaginatedHandlerMixin.getRemotePaginatedData] method should be overridden
/// to provide the data retrieval from the server
/// 
/// Example: 
/// ```dart
/// class MyPaginatedStaleMateHandler extends StaleMateHandler<List<MyData>> with PaginatedHandlerMixin<MyData> {
///  @override
///  List<MyData> get emptyValue => [];
/// 
///  @override
///  Future<List<MyData>> getLocalData() async {
///    // Load the data from the local data source
///    return _localDataSource.getData();
///   }
/// 
///   @override
///   Future<List<MyData>> getRemotePaginatedData(Map<String, dynamic> paginationParams) async {
///     // Load the data from the remote data source
///     return _remoteDataSource.getData(paginationParams);
///   }
/// 
///   @override
///   Future<void> storeLocalData(List<MyData> data) async {
///     // Store the data in the local data source
///     await _localDataSource.storeData(data);
///   }
/// 
///   @override
///   Future<void> removeLocalData() async {
///     // Remove the data from the local data source
///     await _localDataSource.removeData();
///   }
/// }
/// ```
mixin PaginatedHandlerMixin<T> on StaleMateHandler<List<T>> {
  /// Pagination config used to load the data in pages
  /// 
  /// This is set automatically by the [StaleMatePaginatedLoader]
  ///
  /// See also:
  /// - [StaleMatePaginationConfig]
  /// - [StaleMatePagePagination]
  /// - [StaleMateOffsetLimitPagination]
  /// - [StaleMateCursorPagination]
  late StaleMatePaginationConfig<T> paginationConfig;

  /// Sets the pagination config
  ///
  /// This method is called from the constructor of the [StaleMatePaginatedLoader]
  ///
  /// See also:
  /// - [StaleMatePaginationConfig]
  /// - [StaleMatePagePagination]
  /// - [StaleMateOffsetLimitPagination]
  /// - [StaleMateCursorPagination]
  setPaginationConfig(StaleMatePaginationConfig<T> paginationConfig) {
    this.paginationConfig = paginationConfig;
  }

  /// Holds the fetch more operation
  ///
  /// This is used to cancel the fetch more operation if needed
  CancelableOperation<List<T>?>? _fetchMoreOperation;

  /// Cancels the fetch more operation if it's in progress
  ///
  /// Called when the loader is refreshed, initialized or disposed
  cancelFetchMore() {
    if (_fetchMoreOperation != null) {
      _fetchMoreOperation?.cancel();
      _fetchMoreOperation = null;
    }
  }

  /// This method is called when the loader needs to fetch the next page of data from the server
  ///
  /// The [paginationParams] argument contains the params needed to fetch the next page of data
  ///
  /// Override this method to fetch the next page of data from the server based on the [paginationParams]
  ///
  /// The data returned from this method will be passed through the [StaleMatePaginationConfig.onReceivedData] method
  /// which handles merging the data and setting the [StaleMatePaginationConfig.canFetchMore] flag
  ///
  /// Returns the page of data based on the [paginationParams]
  Future<List<T>> getRemotePaginatedData(Map<String, dynamic> paginationParams);

  @override
  Future<List<T>> getRemoteData() async {
    cancelFetchMore();

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

  bool get canFetchMore => paginationConfig.canFetchMore;

  Future<StaleMateFetchMoreResult<T>> fetchNextPage(
      List<T> previousData) async {
    final fetchMoreInitiatedAt = DateTime.now();
    if (paginationConfig.canFetchMore) {
      // Retreive the next query params from the pagination config
      final queryParams = paginationConfig.getQueryParams(
        previousData.length,
        previousData.last,
      );

      _fetchMoreOperation = CancelableOperation.fromFuture(
        getRemotePaginatedData(queryParams),
      );

      try {
        // Get the new data from the implemented getRemotePaginatedData method
        final newData = await _fetchMoreOperation!.valueOrCancellation(null);

        // Reset the fetch more operation
        _fetchMoreOperation = null;

        // Null is used to signal that the fetch more operation was cancelled
        // Other errors will throw an exception
        // Empty respones will be an empty list
        if (newData == null) {
          return StaleMateFetchMoreResult<T>.cancelled(
            fetchMoreInitiatedAt: fetchMoreInitiatedAt,
            queryParams: queryParams,
          );
        }

        // The data returned from the server is passed through the [onReceivedData] method
        // which handles merging the data and setting the [canFetchMore] flag
        final mergedData =
            paginationConfig.onReceivedData(newData, previousData);

        // If we can fetch more data, return more data available
        if (paginationConfig.canFetchMore) {
          final fetchMoreResult = StaleMateFetchMoreResult<T>.moreDataAvailable(
            fetchMoreInitiatedAt: fetchMoreInitiatedAt,
            queryParams: queryParams,
            newData: newData,
            mergedData: mergedData,
          );

          return fetchMoreResult;
        }

        // If we can't fetch more data, return done
        final fetchMoreResult = StaleMateFetchMoreResult<T>.done(
          fetchMoreInitiatedAt: fetchMoreInitiatedAt,
          queryParams: queryParams,
          newData: newData,
          mergedData: mergedData,
        );

        return fetchMoreResult;
      } catch (error) {
        return StaleMateFetchMoreResult<T>.failure(
          fetchMoreInitiatedAt: fetchMoreInitiatedAt,
          queryParams: queryParams,
          error: error,
        );
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
          previousData.length,
          previousData.last,
        ),
        newData: [],
        mergedData: previousData,
      );
    }
  }

  reset() {
    cancelFetchMore();
    paginationConfig.reset();
  }
}
