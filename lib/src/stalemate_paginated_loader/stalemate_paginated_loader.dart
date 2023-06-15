part of '../stalemate_loader/stalemate_loader.dart';

abstract class StaleMatePaginatedLoader<T> extends StaleMateLoader<List<T>> {
  /// The pagination config that will be used to load the data
  /// The [StaleMatePaginationConfig] is used to provide the params for the next page of data
  /// The params will be received in the [getRemotePaginatedData] method
  final StaleMatePaginationConfig<T> paginationConfig;
  bool isFetchingMore = false;

  StaleMatePaginatedLoader({
    required this.paginationConfig,
    super.updateOnInit,
    super.showLocalDataOnError,
    super.refreshConfig,
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

    // The data returned from the server is passed through the [onReceivedData] method
    // which handles merging the data and setting the [canFetchMore] flag
    final data = await getRemotePaginatedData(queryParams);
    return paginationConfig.onReceivedData(data, []);
  }

  /// Call this method to fetch more data from the server
  /// This method will return a [StaleMateFetchMoreResult] with the status of the fetch more
  /// The [StaleMateFetchMoreResult] will contain the new data and the merged data if fetch more is sucessful
  /// The [StaleMateFetchMoreResult] will contain the error if fetch more fails
  /// There is no need to use the data returned from this method, the data will be added to the stream automatically
  /// The data is there for your convinience if you want to do something with it, show how many items were added etc
  Future<StaleMateFetchMoreResult> fetchMore() async {
    if (paginationConfig.canFetchMore) {
      // If fetch more is already in progress, return already refreshing
      if (isFetchingMore) {
        return StaleMateFetchMoreResult.alreadyFetching();
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

        // The pagination config handles setting the can fetch more flag
        // reflect it in the status
        final status = paginationConfig.canFetchMore
            ? StaleMateFetchMoreStatus.moreDataAvailable
            : StaleMateFetchMoreStatus.done;

        return StaleMateFetchMoreResult(
          status: status,
          fetchMoreInitiatedAt: fetchMoreInitiatedAt,
          fetchMoreFinishedAt: DateTime.now(),
          fetchMoreParameters: queryParams,
          newData: newData,
          mergedData: mergedData,
        );
      } catch (error) {
        // Tell the base loader to handle the error appropritaly
        _onRemoteDataError(error);

        return StaleMateFetchMoreResult(
          status: StaleMateFetchMoreStatus.failure,
          fetchMoreInitiatedAt: fetchMoreInitiatedAt,
          fetchMoreFinishedAt: DateTime.now(),
          fetchMoreParameters: queryParams,
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
      return StaleMateFetchMoreResult(
        status: StaleMateFetchMoreStatus.done,
        fetchMoreInitiatedAt: DateTime.now(),
        fetchMoreFinishedAt: DateTime.now(),
        fetchMoreParameters: paginationConfig.getQueryParams(
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
