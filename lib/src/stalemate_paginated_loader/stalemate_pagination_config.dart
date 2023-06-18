/// Configures pagination for [StaleMatePaginatedLoader]
///
/// Implement this class to create custom pagination configs
///
/// How to implement:
/// - Override [getQueryParams] to return the query parameters that can be used to fetch the next page of data
/// - If you want the loader to automatically stop fetching more data, you will need to override [onReceivedData]
///   and set the [canFetchMore] property to false when there is no more data to fetch
/// - If you override [onReceivedData], you can implement your own logic to merge the new data with the old data
///     - The default implementation of [onReceivedData] will append the new data to the old data
///
/// Implementations:
/// - [StaleMatePagePagination]: Page-based pagination
/// - [StaleMateOffsetLimitPagination]: Offset-based pagination
/// - [StaleMateCursorPagination]: Cursor-based pagination
///
/// Example:
/// ```dart
/// class MyPaginationConfig extends StaleMatePaginationConfig {
///   @override
///   Map<String, dynamic> getQueryParams(int numberOfItems, T? lastItem) {
///     // Return the query parameters that can be used to fetch the next page of data
///     // In this example, we will use page-based pagination
///     // The query parameters will be the page number and the page size
///     return {
///       'page': numberOfItems ~/ pageSize + 1,
///       'pageSize': pageSize,
///     };
///   }
/// }
/// ```
///
abstract class StaleMatePaginationConfig<T> {
  /// Whether the loader can fetch more data
  ///
  /// The loader will stop fetching more data when this is false
  bool canFetchMore = true;

  /// Returns the query parameters that can be used to fetch the next page of data
  ///
  /// Override this method to implement your own pagination logic
  ///
  /// The [numberOfItems] is the total number of items loaded so far
  /// The [lastItem] is the last item that was loaded, or null if no items were loaded yet
  Map<String, dynamic> getQueryParams(int numberOfItems, T? lastItem);

  /// Resets the pagination
  ///
  /// This method is called when the loader is refreshed or reset
  void reset() {
    canFetchMore = true;
  }

  /// Merge the new data with the old data
  ///
  /// The [newData] is the new data that was received
  /// The [oldData] is the old data that was already loaded
  ///
  /// The default implementation of this method will append the new data to the old data
  ///
  /// Override this method to implement your own merging logic
  /// If you want the loader to automatically stop fetching more data, you will need to override this method
  /// and set the [canFetchMore] property to false when there is no more data to fetch
  ///
  /// Usecases:
  /// - Required if you want to set the [canFetchMore] property to false when there is no more data to fetch
  /// - Sort data
  /// - Remove duplicates
  /// - etc.
  List<T> onReceivedData(List<T> newData, List<T> oldData) =>
      [...oldData, ...newData];
}

/// Concrete implementation of [StaleMatePaginationConfig] for page-based pagination.
///
/// Use this class if the API supports page-based pagination.
///
/// - [pageSize] is the number of items per page.
/// - [zeroBasedIndexing] is whether the page numbering should be zero-based.
///     - true: the page number of the first page will be 0.
///     - false (default), the page number of the first page will be 1.
/// - [getQueryParams] method returns the page number and page size.
///     - Example query parameters: {page: 1, pageSize: 10}
///
/// See also:
/// - [StaleMateOffsetLimitPagination]
/// - [StaleMateCursorPagination]
///
/// Example:
/// ```dart
/// StaleMatePagePagination(
///   pageSize: 10,
///   zeroBasedIndexing: false,
/// )
/// ```
class StaleMatePagePagination<T> extends StaleMatePaginationConfig<T> {
  /// The number of items per page
  final int pageSize;

  /// Whether the page numbering should be zero-based
  ///
  ///- **true:** the page number of the first page will be 0.
  ///- **false (default):** the page number of the first page will be 1.
  ///
  final bool zeroBasedIndexing;

  /// Creates a new [StaleMatePagePagination] instance
  ///
  /// Arguments:
  /// - **pageSize:** The number of items per page
  /// - **zeroBasedIndexing:** Whether the page numbering should be zero-based
  ///
  /// Example:
  /// ```dart
  /// StaleMatePagePagination(
  ///   pageSize: 10,
  ///   zeroBasedIndexing: false,
  /// )
  /// ```
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

/// Concrete implementation of [StaleMatePaginationConfig] for offset-based pagination.
///
/// Use this class if the API supports offset-based pagination.
///
/// - [limit] is the number of items per request.
/// - [getQueryParams] method returns the offset and limit.
///    - Example query parameters: {offset: 0, limit: 10}
///
/// See also:
/// - [StaleMatePagePagination]
/// - [StaleMateCursorPagination]
///
/// Example:
/// ```dart
/// StaleMateOffsetLimitPagination(
///  limit: 10,
/// )
/// ```
class StaleMateOffsetLimitPagination<T> extends StaleMatePaginationConfig<T> {
  /// The number of items per request
  final int limit;

  /// Creates a new [StaleMateOffsetLimitPagination] instance
  ///
  /// Arguments:
  /// - **limit:** The number of items per request
  ///
  /// Example:
  /// ```dart
  /// StaleMateOffsetLimitPagination(
  ///   limit: 10,
  ///  )
  /// ```
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

/// Concrete implementation of [StaleMatePaginationConfig] for cursor-based pagination.
///
/// Use this class if the API supports cursor-based pagination.
///
/// - [limit] is the number of items per request.
/// - [getCursor] is the function to get the cursor for the next page.
///    - The cursor is a string that can be used to fetch the next page of data,
///      it is usually an id or a timestamp.
/// - [getQueryParams] method returns the cursor and limit.
///   - Example query parameters: {cursor: "123", limit: 10}
///
/// See also:
/// - [StaleMatePagePagination]
/// - [StaleMateOffsetLimitPagination]
///
/// Example:
/// ```dart
/// StaleMateCursorPagination(
///  limit: 10,
///  getCursor: (lastItem) => lastItem.id,
/// )
/// ```
class StaleMateCursorPagination<T> extends StaleMatePaginationConfig<T> {
  /// The number of items per page
  final int limit;

  /// Callback to get the cursor for the next page
  ///
  /// The cursor is a string that can be used to fetch the next page of data,
  /// it is usually an id or a timestamp.
  final String Function(T lastItem) getCursor;

  /// Creates a new [StaleMateCursorPagination] instance
  ///
  /// Arguments:
  /// - **limit:** The number of items per request
  /// - **getCursor:** Callback to get the cursor for the next page
  ///
  /// Example:
  /// ```dart
  /// StaleMateCursorPagination(
  ///  limit: 10,
  ///  getCursor: (lastItem) => lastItem.id,
  /// )
  /// ```
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
