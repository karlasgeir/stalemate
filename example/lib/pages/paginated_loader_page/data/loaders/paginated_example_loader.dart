import 'package:stalemate/stalemate.dart';

import '../datasources/paginated_example_remote_datasource.dart';

/// An example of a [StaleMatePaginatedLoader] that loads paginated data
///
/// The data is loaded from a fake remote source ([PaginatedExampleRemoteDatasource])
/// and the pagination is handled by the [StaleMatePaginatedLoader]
///
/// See also:
/// - [StaleMatePaginatedLoader]
/// - [PaginatedExampleRemoteDatasource]
/// - [StaleMatePaginationConfig]
/// - [StaleMatePagePagination]
/// - [StaleMateOffsetLimitPagination]
/// - [StaleMateCursorPagination]
class PaginatedExampleLoader extends StaleMatePaginatedLoader<String> {
  final PaginatedExampleRemoteDatasource _remoteDatasource =
      PaginatedExampleRemoteDatasource();

  /// A flag that can be used to simulate an error when fetching remote data
  ///
  /// If this flag is set to true, the [getRemotePaginatedData] method will throw
  bool shouldThrowError = false;

  /// Creates a [PaginatedExampleLoader]
  ///
  /// Arguments:
  /// - **paginationConfig:** The pagination config that will be used to paginate the data
  ///     - [StaleMatePagePagination] : For page based pagination
  ///     - [StaleMateOffsetLimitPagination] : For offset limit based pagination
  ///     - [StaleMateCursorPagination] : For cursor based pagination
  /// - **logLevel:** The log level that will be used to log messages
  PaginatedExampleLoader({
    required super.paginationConfig,
    super.logLevel,
  });

  /// This method is called when the [StaleMatePaginatedLoader] needs to fetch remote data
  ///
  /// This is where you would normally call your remote datasource to fetch data
  /// paginated with the pagination params
  ///
  /// Normally you would just know what type of pagination config you are using and not need the if statement
  /// but this example loader is used for all types of pagination configs
  ///
  /// Arguments:
  /// - **paginationParams:** The pagination params that will be used to fetch the data
  ///
  /// Returns:
  /// - **List<String>:** The paginated data
  ///
  /// Throws:
  /// - **Exception:** If the [shouldThrowError] flag is set to true
  @override
  Future<List<String>> getRemotePaginatedData(
    Map<String, dynamic> paginationParams,
  ) async {
    // This is just to simulate a delay when fetching remote data
    await Future.delayed(const Duration(seconds: 3));

    // If the [shouldThrowError] flag is set to true, the [getRemotePaginatedData]
    // method will throw an error
    if (shouldThrowError) {
      throw Exception('Failed to fetch remote data');
    }

    if (paginationConfig is StaleMatePagePagination) {
      final page = paginationParams['page'] as int;
      final pageSize = paginationParams['pageSize'] as int;
      return _remoteDatasource.getPagePaginatedItems(page, pageSize);
    } else if (paginationConfig is StaleMateOffsetLimitPagination) {
      final offset = paginationParams['offset'] as int;
      final limit = paginationParams['limit'] as int;
      return _remoteDatasource.getOffsetLimitPaginatedItems(offset, limit);
    } else if (paginationConfig is StaleMateCursorPagination) {
      final cursor = paginationParams['cursor'] as String?;
      final limit = paginationParams['limit'] as int;
      return _remoteDatasource.getCursorPaginatedItems(cursor, limit);
    } else {
      throw Exception('Unknown pagination config type');
    }
  }
}
