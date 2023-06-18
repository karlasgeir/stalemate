import 'package:stalemate/stalemate.dart';

import '../datasources/paginated_example_remote_datasource.dart';

/// This is a simple example of a [StaleMatePaginatedLoader] that loads
/// paginated data from a fake remote source.
/// The [StaleMatePaginatedLoader] is initialized with a [StaleMatePaginationConfig]
/// an handles the pagination like it was the server that was doing the pagination
class PaginatedExampleLoader extends StaleMatePaginatedLoader<String> {
  final PaginatedExampleRemoteDatasource _remoteDatasource =
      PaginatedExampleRemoteDatasource();
  // This flag is used to simulate an error when fetching remote data
  // If it is set to true, the [getRemotePaginatedData] method will throw an error
  bool shouldThrowError = false;

  PaginatedExampleLoader({
    required super.paginationConfig,
    super.logLevel,
  });

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

    // Normally you would just know what type of pagination config you are using
    // but this example loader is used for all types of pagination configs
    // so we need to check the type of the pagination config and use the correct
    // method on the remote datasource
    // In a normal application you would just use the pagination params to call the
    // remote datasource
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
