/// StalematePaginationConfig is used to configure pagionation for [StaleMatePaginatedLoader]
/// The [getQueryParams] method is used to get the query parameters that can be used to
/// fetch the next page of data
/// The [getQueryParams] method takes the number of items that have already been loaded
/// and the last item that was loaded
/// The [getQueryParams] method returns a map of query parameters that can be used to
/// fetch the next page of data
/// The [onReceivedData] method is used to merge the new data with the old data
/// The [onReceivedData] method takes the new data and the old data
/// The [onReceivedData] method returns the merged data
/// The [canFetchMore] property is used to check if there is more data to fetch
/// The [canFetchMore] property should be set to false when there is no more data to fetch
/// You can implement your own pagination config by extending [StaleMatePaginationConfig]
/// and overriding the [getQueryParams] method
/// You can use the [StaleMatePagePagination], [StaleMateOffsetLimitPagination] and
/// [StaleMateCursorPagination] classes to implement page, offset and cursor based
/// pagination respectively
abstract class StaleMatePaginationConfig<T> {
  bool canFetchMore = true;

  /// Returns the query parameters that can be used to fetch the next page of data
  /// The [numberOfItems] is the number of items that have already been loaded
  /// The [lastItem] is the last item that was loaded
  Map<String, dynamic> getQueryParams(int numberOfItems, T? lastItem);

  /// Resets the pagination
  void reset() {
    canFetchMore = true;
  }

  /// Merges the new data with the old data by default
  /// The [newData] is the new data that was received
  /// The [oldData] is the old data that was already loaded
  /// The [onReceivedData] method returns the merged data by default
  /// Override this method to implement your own merging logic
  /// For example, you can use this method to remove duplicates from the data
  /// or to sort the data
  /// You can also use this method to set [canFetchMore] to false depending on the data
  /// that was received
  List<T> onReceivedData(List<T> newData, List<T> oldData) =>
      [...oldData, ...newData];
}

/// Concrete implementation of [StaleMatePaginationConfig] for page-based pagination.
/// The [pageSize] defines the number of items per page.
/// The [zeroBasedIndexing] indicates whether the page numbering should start from 0.
/// If this is true, the page number of the first page will be 0.
/// If this is false, the page number of the first page will be 1 (default).
/// The [getQueryParams] method returns the page number and page size.
/// The page number is derived from the total number of items loaded so far divided by page size.
/// The page size is the number of items to load on each request.
class StaleMatePagePagination<T> extends StaleMatePaginationConfig<T> {
  /// The number of items per page
  final int pageSize;
  // Whether the page numbering should be zero-based.
  /// If this is true, the page number of the first page will be 0.
  /// If this is false (default), the page number of the first page will be 1.
  final bool zeroBasedIndexing;

  StaleMatePagePagination({
    required this.pageSize,
    this.zeroBasedIndexing = false,
  });

  @override
  Map<String, dynamic> getQueryParams(int numberOfItems, T? lastItem) {
    return {
      // The page number is derived from the total number of items loaded so far divided by page size.
      'page': (numberOfItems / pageSize).ceil() + (zeroBasedIndexing ? 0 : 1),
      'pageSize': pageSize,
    };
  }

  @override
  List<T> onReceivedData(List<T> newData, List<T> oldData) {
    // If the number of items received is less than the page size,
    // there are no more items to fetch.
    canFetchMore = newData.length == pageSize;
    return super.onReceivedData(newData, oldData);
  }
}

/// Concrete implementation of [StaleMatePaginationConfig] for offset based pagination
/// The [limit] is the number of items per request
/// The [getQueryParams] method returns the offset and limit
/// The offset is the number of items that have already been loaded
/// The limit is the number of items to load on each request
/// The [onReceivedData] method sets [canFetchMore] to false if the number of items
/// received is less than the limit
class StaleMateOffsetLimitPagination<T> extends StaleMatePaginationConfig<T> {
  /// The number of items per request
  final int limit;

  StaleMateOffsetLimitPagination({
    required this.limit,
  });

  @override
  Map<String, dynamic> getQueryParams(int numberOfItems, T? lastItem) {
    return {
      // The offset is the number of items that have already been loaded
      'offset': numberOfItems,
      'limit': limit,
    };
  }

  @override
  List<T> onReceivedData(List<T> newData, List<T> oldData) {
    // If the number of items received is less than the limit,
    canFetchMore = newData.length == limit;
    return super.onReceivedData(newData, oldData);
  }
}

/// Concrete implementation of [StaleMatePaginationConfig] for cursor based pagination
/// The [limit] is the number of items per page
/// The [getCursor] method returns the cursor for the next page
/// The cursor is a string that can be used to fetch the next page of data,
/// it is usually an id or a timestamp
/// The [getQueryParams] method returns the cursor and limit
/// The cursor is the cursor for the next page
/// The limit is the number of items to load on each request
/// The [onReceivedData] method sets [canFetchMore] to false if the number of items
/// received is less than the limit
class StaleMateCursorPagination<T> extends StaleMatePaginationConfig<T> {
  /// The number of items per page
  final int limit;

  /// The function to get the cursor for the next page
  /// The cursor is a string that can be used to fetch the next page of data,
  /// it is usually an id or a timestamp
  final String Function(T lastItem) getCursor;

  StaleMateCursorPagination({
    required this.limit,
    required this.getCursor,
  });

  @override
  Map<String, dynamic> getQueryParams(int numberOfItems, T? lastItem) {
    return {
      // Retrieve the cursor for the next page
      // This needs to be implemented by the user since
      // the cursor is usually an id or a timestamp, depending on the data
      'cursor': lastItem != null ? getCursor(lastItem) : null,
      'limit': limit,
    };
  }

  @override
  List<T> onReceivedData(List<T> newData, List<T> oldData) {
    // If the number of items received is less than the limit,
    // there are no more items to fetch.
    canFetchMore = newData.length == limit;
    return super.onReceivedData(newData, oldData);
  }
}
