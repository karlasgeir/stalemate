// This is just a remote datasource to simulate fetching data from a remote source
import 'dart:math';

class PaginatedExampleRemoteDatasource {
  /// This is a fake list of items that will be used to simulate the remote data
  static final List<String> remoteItems =
      List.generate(25, (index) => 'item ${index + 1}');

  /// This method simulates fetching paginated data from a remote source
  /// using page and pageSize
  /// The page is the index of the page to fetch
  /// The pageSize is the number of items to fetch per page
  Future<List<String>> getPagePaginatedItems(
    int page,
    int pageSize,
  ) async {
    int startIndex = (page - 1) * pageSize;
    final endIndex = min(startIndex + pageSize, remoteItems.length);
    return remoteItems.sublist(startIndex, endIndex);
  }

  /// This method simulates fetching paginated data from a remote source
  /// using offset and limit
  /// The offset is the index of the first item to fetch
  /// The limit is the number of items to fetch
  Future<List<String>> getOffsetLimitPaginatedItems(
    int offset,
    int limit,
  ) async {
    final startIndex = offset;
    final endIndex = min(startIndex + limit, remoteItems.length);
    return remoteItems.sublist(startIndex, endIndex);
  }

  /// This method simulates fetching paginated data from a remote source
  /// using cursor and limit
  /// The cursor is usually the id of the last item fetched or a timestamp
  /// In this test data we will use the item itself as the cursor
  /// The limit is the number of items to fetch
  /// The items fetched will be the items after the cursor
  /// The cursor itself will not be included in the fetched items
  /// If the cursor is null, the first items will be fetched
  Future<List<String>> getCursorPaginatedItems(
    String? cursor,
    int limit,
  ) async {
    final startIndex = cursor == null ? 0 : remoteItems.indexOf(cursor) + 1;
    final endIndex = min(startIndex + limit, remoteItems.length);
    return remoteItems.sublist(startIndex, endIndex);
  }
}
