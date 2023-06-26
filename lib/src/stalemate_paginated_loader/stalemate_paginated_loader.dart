part of '../stalemate_loader/stalemate_loader.dart';

/// A [StaleMateLoader] that supports pagination.
///
/// This loader is useful when you have data that needs to be loaded in pages.
///
/// The [StaleMatePaginatedLoader] supports everything that the [StaleMateLoader] supports,
/// and adds the ability to load paginated data
///
/// Additions to base [StaleMateLoader]:
/// - **handler** must use [PaginatedHandlerMixin]
/// - **paginationConfig** is required and it is used to load the data in pages.
/// - [fetchMore] method is added to fetch more data from the server.
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
/// final loader = MyPaginatedLoader(
///   paginationConfig: StaleMatePagePagination(
///     pageSize: 10,
///     zeroBasedIndexing: false,
///   );
///   handler: MyPaginatedHandler(),
/// );
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
class StaleMatePaginatedLoader<T, HandlerType extends PaginatedHandlerMixin<T>>
    extends StaleMateLoader<List<T>, HandlerType> {
  /// Create a new [StaleMatePaginatedLoader] instance
  ///
  /// Used to load data in pages.
  ///
  /// Arguments:
  /// - [paginationConfig] : Pagination config used to load the data in pages
  /// - [handler] : Handler used to handle the data, must use [PaginatedHandlerMixin]
  /// - [updateOnInit] : If true, the loader will update the data stream on initialization
  /// - [showLocalDataOnError] : If true, the loader will show the local data on error
  /// - [refreshConfig] : Refresh config used to refresh the data
  /// - [logLevel] : Log level used to log the loader events
  StaleMatePaginatedLoader({
    required StaleMatePaginationConfig<T> paginationConfig,
    required HandlerType handler,
    super.updateOnInit,
    super.showLocalDataOnError,
    super.refreshConfig,
    super.logLevel,
  }) : super(
          handler: handler,
        ) {
    handler.setPaginationConfig(paginationConfig);
  }

  @override
  Future<void> initialize() async {
    // Cancel any ongoing fetch more operations
    _handler.cancelFetchMore();

    await super.initialize();
  }

  /// Fetch more data from the server
  ///
  /// This method is used to fetch the next page of data from the server
  ///
  /// The data returned from this method will be passed through the [StaleMatePaginationConfig.onReceivedData] method
  /// which handles merging the data and setting the [StaleMatePaginationConfig.canFetchMore] flag
  ///
  /// Returns a [StaleMateFetchMoreResult] which can be used to handle the result of the fetch more operation
  /// The status of the fetch more operation can be checked using the [StaleMateFetchMoreResult.status] property
  /// - [StaleMateFetchMoreStatus.done] indicates that the fetch more was successful and there is no more data to fetch
  /// - [StaleMateFetchMoreStatus.moreDataAvailable] indicates that the fetch more was successful and there is more data to fetch
  /// - [StaleMateFetchMoreStatus.alreadyFetching] indicates that the fetch more is already in progress
  /// - [StaleMateFetchMoreStatus.failure] indicates that the fetch more failed with an error
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
    // If we are already fetching data, return already fetching
    if (state.loading) {
      _logger.i('Could not fetch more. Already fetching data');
      return StaleMateFetchMoreResult<T>.alreadyFetching();
    }

    _stateManager.setRemoteState(
      StaleMateStatus.loading,
      fetchReason: StaleMateFetchReason.fetchMore,
    );

    final fetchMoreResult = await _handler.fetchNextPage(value);

    _logger.d(fetchMoreResult);

    if (fetchMoreResult.hasData) {
      addData(fetchMoreResult.requireMergedData);

      _stateManager.setRemoteState(
        StaleMateStatus.loaded,
        fetchReason: StaleMateFetchReason.fetchMore,
      );
    }

    if (fetchMoreResult.isCancelled) {
      _logger.i('Fetch more operation cancelled');
    } else if (fetchMoreResult.isAlreadyFetching) {
      _logger.i('Could not fetch more. Already fetching data');
    } else if (fetchMoreResult.isFailure) {
      final error = fetchMoreResult.requireError;
      _logger.e('Fetch more operation failed', error);
      // Tell the base loader to handle the error appropritaly
      _onRemoteDataError(error, StackTrace.current);

      _stateManager.setRemoteState(
        StaleMateStatus.loaded,
        fetchReason: StaleMateFetchReason.fetchMore,
        error: error,
      );
    } else if (fetchMoreResult.isDone) {
      _logger.i('Fetch more operation successful, no more data to fetch');
    }

    return fetchMoreResult;
  }

  @override
  Future<void> reset() {
    _handler.reset();
    return super.reset();
  }
}
