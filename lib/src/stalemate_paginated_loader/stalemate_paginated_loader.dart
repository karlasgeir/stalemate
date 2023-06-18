part of '../stalemate_loader/stalemate_loader.dart';

abstract class StaleMatePaginatedLoader<T> extends StaleMateLoader<List<T>> {
  /// The pagination config that will be used to load the data
  /// The [StaleMatePaginationConfig] is used to provide the params for the next page of data
  /// The params will be received in the [getRemotePaginatedData] method
  final StaleMatePaginationConfig<T> paginationConfig;
  
  /// This flag is used to indicate if the loader is currently fetching more data
  bool isFetchingMore = false;

  StaleMatePaginatedLoader({
    /// The pagination config that will be used to load the data
    required this.paginationConfig,
    super.updateOnInit,
    super.showLocalDataOnError,
    super.refreshConfig,
    super.logLevel,
  }) : super(emptyValue: const []);

  /// Override this method in subclasses of [StaleMatePaginatedLoader]
  /// the params in the [paginationParams] depend on the [StaleMatePaginationConfig] used
  /// The [paginationParams] can be used to fetch the next page of data
  Future<List<T>> getRemotePaginatedData(Map<String, dynamic> paginationParams);

  /// Do not override this method in subclasses of [StaleMatePaginatedLoader]
  /// The getRemoteData function is implemented for you in [StaleMatePaginatedLoader]
  @override
  Future<List<T>> getRemoteData() async {
    // Get remote data is only called on initial loading and refresh
    // In those cases we reset the pagination and get the first page of data
    paginationConfig.reset();
    final queryParams = paginationConfig.getQueryParams(
      0,
      null,
    );

    _logger.i('Get remote data called, which will reset the pagination');
    _logger.d('Resetting pagination with Query params: $queryParams');

    // The data returned from the server is passed through the [onReceivedData] method
    // which handles merging the data and setting the [canFetchMore] flag
    final data = await getRemotePaginatedData(queryParams);
    final mergedData = paginationConfig.onReceivedData(data, []);
    _logger.i(
      'Received ${data.length} items from server, merged data is now ${mergedData.length}',
    );
    _logger.d('Data from server: ');
    _logger.d(data);
    _logger.d('Merged data: ');
    _logger.d(mergedData);
    return mergedData;
  }

  /// Call this method to fetch more data from the server
  /// This method will return a [StaleMateFetchMoreResult] with the status of the fetch more
  /// The [StaleMateFetchMoreResult] will contain the new data and the merged data if fetch more is sucessful
  /// The [StaleMateFetchMoreResult] will contain the error if fetch more fails
  /// There is no need to use the data returned from this method, the data will be added to the stream automatically
  /// The data is there for your convinience if you want to do something with it, show how many items were added etc
  Future<StaleMateFetchMoreResult<T>> fetchMore() async {
    if (paginationConfig.canFetchMore) {
      // If fetch more is already in progress, return already refreshing
      if (isFetchingMore) {
        _logger.i('Fetch more called, but it is already in progress');
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

      _logger.i('Fetch more called with query params: $queryParams');

      try {
        // Get the new data from the implemented getRemotePaginatedData method
        final newData = await getRemotePaginatedData(queryParams);
        // The data returned from the server is passed through the [onReceivedData] method
        // which handles merging the data and setting the [canFetchMore] flag
        final mergedData = paginationConfig.onReceivedData(newData, value);

        _logger.i(
            'Received ${newData.length} items from server, merged data is now ${mergedData.length}');
        _logger.d('New data from server: ');
        _logger.d(newData);
        _logger.d('Merged data: ');
        _logger.d(mergedData);

        // Add the merged data to the stream
        addData(mergedData);

        // If we can fetch more data, return more data available
        if (paginationConfig.canFetchMore) {
          final result = StaleMateFetchMoreResult<T>.moreDataAvailable(
            fetchMoreInitiatedAt: fetchMoreInitiatedAt,
            queryParams: queryParams,
            newData: newData,
            mergedData: mergedData,
          );
          _logger.i('More data available');
          _logger.d('Fetch more result: ');
          _logger.d(result);
          return result;
        }

        // If we can't fetch more data, return done
        final result = StaleMateFetchMoreResult<T>.done(
          fetchMoreInitiatedAt: fetchMoreInitiatedAt,
          queryParams: queryParams,
          newData: newData,
          mergedData: mergedData,
        );
        _logger.i('No more data on server, done fetching more');
        _logger.d('Fetch more result: ');
        _logger.d(result);
        return result;
      } catch (error, stackTrace) {
        // Tell the base loader to handle the error appropritaly
        _onRemoteDataError(error);

        // Return failure
        final result = StaleMateFetchMoreResult<T>.failure(
          fetchMoreInitiatedAt: fetchMoreInitiatedAt,
          queryParams: queryParams,
          error: error,
        );
        _logger.e('Fetch more failed', error, stackTrace);
        _logger.d('Fetch more result: ');
        _logger.d(result);
        return result;
      } finally {
        // Set is fetching more to false so that we can call fetch more again
        isFetchingMore = false;
      }
    } else {
      _logger.i('Fetch more called, but no more data available');
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
