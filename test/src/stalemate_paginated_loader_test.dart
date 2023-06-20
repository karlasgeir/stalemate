import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:stalemate/stalemate.dart';

class MockStaleMatePaginatedLoader extends StaleMatePaginatedLoader<String> {
  bool shouldThrowError = false;
  static final List<String> remoteItems =
      List.generate(25, (index) => 'item ${index + 1}');

  MockStaleMatePaginatedLoader({
    required super.paginationConfig,
  });

  @override
  Future<List<String>> getRemotePaginatedData(
      Map<String, dynamic> paginationParams) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldThrowError) {
      throw Exception('Failed to fetch remote data');
    }
    if (paginationConfig is StaleMatePagePagination) {
      final page = paginationParams['page'] as int;
      final pageSize = paginationParams['pageSize'] as int;
      int startIndex;
      if ((paginationConfig as StaleMatePagePagination).zeroBasedIndexing) {
        startIndex = page * pageSize;
      } else {
        startIndex = (page - 1) * pageSize;
      }
      final endIndex = min(startIndex + pageSize, remoteItems.length);
      return remoteItems.sublist(startIndex, endIndex);
    } else if (paginationConfig is StaleMateOffsetLimitPagination) {
      final offset = paginationParams['offset'] as int;
      final limit = paginationParams['limit'] as int;
      final startIndex = offset;
      final endIndex = min(startIndex + limit, remoteItems.length);
      return remoteItems.sublist(startIndex, endIndex);
    } else if (paginationConfig is StaleMateCursorPagination) {
      final cursor = paginationParams['cursor'] as String?;
      final limit = paginationParams['limit'] as int;
      final startIndex = cursor == null ? 0 : remoteItems.indexOf(cursor) + 1;
      final endIndex = min(startIndex + limit, remoteItems.length);
      return remoteItems.sublist(startIndex, endIndex);
    } else {
      throw Exception('Unknown pagination config type');
    }
  }
}

void main() {
  group('Paginated Loader basics', () {
    late MockStaleMatePaginatedLoader paginatedLoader;
    setUp(() {
      // We use the pagination config for this tests
      // other pagination config will be tested in their own test tests
      paginatedLoader = MockStaleMatePaginatedLoader(
        paginationConfig: StaleMatePagePagination(
          pageSize: 10,
        ),
      );
    });

    test('should initialize with first page of data', () async {
      await paginatedLoader.initialize();
      expect(paginatedLoader.value,
          equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 10)));
    });

    test('successful fetch more with more data to come', () async {
      await paginatedLoader.initialize();

      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 10)),
      );

      final fetchMoreResults = await paginatedLoader.fetchMore();

      // Things that should be set when successfully fetching more
      expect(
          fetchMoreResults.status, StaleMateFetchMoreStatus.moreDataAvailable);
      expect(fetchMoreResults.moreDataAvailable, true);
      expect(fetchMoreResults.hasData, true);
      expect(fetchMoreResults.fetchMoreInitiatedAt, isNotNull);
      expect(fetchMoreResults.requireFetchMoreInitiatedAt, isNotNull);
      expect(fetchMoreResults.fetchMoreFinishedAt, isNotNull);
      expect(fetchMoreResults.requireFetchMoreFinishedAt, isNotNull);
      expect(fetchMoreResults.fetchMoreDuration, isNotNull);
      expect(fetchMoreResults.requireFetchMoreDuration, isNotNull);
      expect(fetchMoreResults.newData,
          MockStaleMatePaginatedLoader.remoteItems.sublist(10, 20));
      expect(fetchMoreResults.mergedData,
          MockStaleMatePaginatedLoader.remoteItems.sublist(0, 20));
      expect(
        fetchMoreResults.requireNewData,
        MockStaleMatePaginatedLoader.remoteItems.sublist(10, 20),
      );
      expect(
        fetchMoreResults.requireMergedData,
        MockStaleMatePaginatedLoader.remoteItems.sublist(0, 20),
      );
      expect(fetchMoreResults.fetchMoreParameters, {'page': 2, 'pageSize': 10});

      // Things that should not be set when successfully fetching more
      expect(fetchMoreResults.isFailure, false);
      expect(fetchMoreResults.isDone, false);
      expect(fetchMoreResults.isAlreadyFetching, false);
      expect(fetchMoreResults.error, null);
      expect(
          () => fetchMoreResults.requireError, throwsA(isA<AssertionError>()));

      // The loader should have the new data
      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 20)),
      );
    });

    test(
        'should return already fetching more if fetch more is called while initializing',
        () async {
      final intializeFuture = paginatedLoader.initialize();
      final fetchMoreResult = await paginatedLoader.fetchMore();

      await intializeFuture;

      // Should be set
      expect(
        fetchMoreResult.status,
        StaleMateFetchMoreStatus.alreadyFetching,
      );
      expect(fetchMoreResult.isAlreadyFetching, true);

      // Should not be set
      expect(fetchMoreResult.isFailure, false);
      expect(fetchMoreResult.isDone, false);
      expect(fetchMoreResult.hasData, false);
      expect(fetchMoreResult.moreDataAvailable, false);
      expect(fetchMoreResult.error, null);
      expect(
          () => fetchMoreResult.requireError, throwsA(isA<AssertionError>()));
      expect(fetchMoreResult.fetchMoreInitiatedAt, isNull);
      expect(() => fetchMoreResult.requireFetchMoreInitiatedAt,
          throwsA(isA<AssertionError>()));
      expect(fetchMoreResult.fetchMoreFinishedAt, isNull);
      expect(() => fetchMoreResult.requireFetchMoreFinishedAt,
          throwsA(isA<AssertionError>()));
      expect(fetchMoreResult.fetchMoreDuration, isNull);
      expect(() => fetchMoreResult.requireFetchMoreDuration,
          throwsA(isA<AssertionError>()));
      expect(fetchMoreResult.newData, null);
      expect(
          () => fetchMoreResult.requireNewData, throwsA(isA<AssertionError>()));
      expect(fetchMoreResult.mergedData, null);
      expect(() => fetchMoreResult.requireMergedData,
          throwsA(isA<AssertionError>()));
      expect(fetchMoreResult.fetchMoreParameters, null);

      // The loader should only have the data fromt he initialization
      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 10)),
      );

      // next paginated query params should be the second page, since the first call
      // to fetch more was ignored
      expect(
        paginatedLoader.paginationConfig.getQueryParams(
          paginatedLoader.value.length,
          paginatedLoader.value.last,
        ),
        {
          'page': 2,
          'pageSize': 10,
        },
      );
    });

    test('should return already fetching while fetching more', () async {
      await paginatedLoader.initialize();
      final paginatedLoaderFuture = paginatedLoader.fetchMore();
      final otherfetchMoreResult = await paginatedLoader.fetchMore();
      await paginatedLoaderFuture;

      // Should be set
      expect(
        otherfetchMoreResult.status,
        StaleMateFetchMoreStatus.alreadyFetching,
      );
      expect(otherfetchMoreResult.isAlreadyFetching, true);

      // Should not be set
      expect(otherfetchMoreResult.isFailure, false);
      expect(otherfetchMoreResult.isDone, false);
      expect(otherfetchMoreResult.hasData, false);
      expect(otherfetchMoreResult.moreDataAvailable, false);
      expect(otherfetchMoreResult.error, null);
      expect(() => otherfetchMoreResult.requireError,
          throwsA(isA<AssertionError>()));
      expect(otherfetchMoreResult.fetchMoreInitiatedAt, isNull);
      expect(() => otherfetchMoreResult.requireFetchMoreInitiatedAt,
          throwsA(isA<AssertionError>()));
      expect(otherfetchMoreResult.fetchMoreFinishedAt, isNull);
      expect(() => otherfetchMoreResult.requireFetchMoreFinishedAt,
          throwsA(isA<AssertionError>()));
      expect(otherfetchMoreResult.fetchMoreDuration, isNull);
      expect(() => otherfetchMoreResult.requireFetchMoreDuration,
          throwsA(isA<AssertionError>()));
      expect(otherfetchMoreResult.newData, null);
      expect(() => otherfetchMoreResult.requireNewData,
          throwsA(isA<AssertionError>()));
      expect(otherfetchMoreResult.mergedData, null);
      expect(() => otherfetchMoreResult.requireMergedData,
          throwsA(isA<AssertionError>()));
      expect(otherfetchMoreResult.fetchMoreParameters, null);

      // The loader should have the new data from the first fetch more and not the second
      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 20)),
      );

      // next paginated query params should be the third page, since the second call
      // to fetch more was ignored
      expect(
        paginatedLoader.paginationConfig.getQueryParams(
          paginatedLoader.value.length,
          paginatedLoader.value.last,
        ),
        {
          'page': 3,
          'pageSize': 10,
        },
      );
    });

    test('should cancel fetch more if refresh is called while fetching more',
        () async {
      await paginatedLoader.initialize();
      final fetchMoreFuture = paginatedLoader.fetchMore();
      final refreshResult = await paginatedLoader.refresh();

      final fetchMoreResult = await fetchMoreFuture;

      expect(fetchMoreResult.status, StaleMateFetchMoreStatus.cancelled);
      expect(refreshResult.status, StaleMateRefreshStatus.success);

      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 10)),
      );
    });

    test('should cancel fetch more when reset', () async {
      await paginatedLoader.initialize();
      final fetchMoreFuture = paginatedLoader.fetchMore();
      await paginatedLoader.reset();

      final fetchMoreResult = await fetchMoreFuture;

      expect(fetchMoreResult.status, StaleMateFetchMoreStatus.cancelled);

      expect(paginatedLoader.value, isEmpty);
    });

    test('should cancel fetch-more if re-initialized', () async {
      await paginatedLoader.initialize();
      final fetchMoreFuture = paginatedLoader.fetchMore();
      await paginatedLoader.initialize();

      final fetchMoreResult = await fetchMoreFuture;

      expect(fetchMoreResult.status, StaleMateFetchMoreStatus.cancelled);

      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 10)),
      );
    });

    test('successful fetch more with no more data', () async {
      await paginatedLoader.initialize();

      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 10)),
      );

      final fetchMoreResults = await paginatedLoader.fetchMore();

      expect(fetchMoreResults.moreDataAvailable, true);
      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 20)),
      );

      final fetchMoreResults2 = await paginatedLoader.fetchMore();

      // Should be set
      expect(fetchMoreResults2.status, StaleMateFetchMoreStatus.done);
      expect(fetchMoreResults2.moreDataAvailable, false);
      expect(fetchMoreResults2.hasData, true);
      expect(fetchMoreResults2.isDone, true);
      expect(fetchMoreResults2.fetchMoreInitiatedAt, isNotNull);
      expect(fetchMoreResults2.requireFetchMoreInitiatedAt, isNotNull);
      expect(fetchMoreResults2.fetchMoreFinishedAt, isNotNull);
      expect(fetchMoreResults2.requireFetchMoreFinishedAt, isNotNull);
      expect(fetchMoreResults2.fetchMoreDuration, isNotNull);
      expect(fetchMoreResults2.requireFetchMoreDuration, isNotNull);
      expect(fetchMoreResults2.newData,
          MockStaleMatePaginatedLoader.remoteItems.sublist(20, 25));
      expect(fetchMoreResults2.mergedData,
          MockStaleMatePaginatedLoader.remoteItems.sublist(0, 25));
      expect(
          fetchMoreResults2.fetchMoreParameters, {'page': 3, 'pageSize': 10});

      // Should not be set
      expect(fetchMoreResults2.isFailure, false);
      expect(fetchMoreResults2.isAlreadyFetching, false);
      expect(fetchMoreResults2.error, null);
      expect(
          () => fetchMoreResults2.requireError, throwsA(isA<AssertionError>()));

      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 25)),
      );

      // If we try to fetch more, we should return done immediately
      final fetchMoreResults3 = await paginatedLoader.fetchMore();

      // Should be set
      expect(fetchMoreResults3.status, StaleMateFetchMoreStatus.done);
      expect(fetchMoreResults3.moreDataAvailable, false);
      expect(fetchMoreResults3.hasData, true);
      expect(fetchMoreResults3.isDone, true);
      expect(fetchMoreResults3.fetchMoreInitiatedAt, isNotNull);
      expect(fetchMoreResults3.requireFetchMoreInitiatedAt, isNotNull);
      expect(fetchMoreResults3.fetchMoreFinishedAt, isNotNull);
      expect(fetchMoreResults3.requireFetchMoreFinishedAt, isNotNull);
      expect(fetchMoreResults3.fetchMoreDuration, isNotNull);
      expect(fetchMoreResults3.requireFetchMoreDuration, isNotNull);
      expect(fetchMoreResults3.newData, []);
      expect(fetchMoreResults3.mergedData,
          MockStaleMatePaginatedLoader.remoteItems.sublist(0, 25));
      expect(
          fetchMoreResults3.fetchMoreParameters, {'page': 4, 'pageSize': 10});

      // Should not be set
      expect(fetchMoreResults3.isFailure, false);
      expect(fetchMoreResults3.isAlreadyFetching, false);
      expect(fetchMoreResults3.error, null);
      expect(
          () => fetchMoreResults3.requireError, throwsA(isA<AssertionError>()));

      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 25)),
      );
    });

    test('fetch more with failure', () async {
      await paginatedLoader.initialize();

      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 10)),
      );

      paginatedLoader.shouldThrowError = true;

      final fetchMoreResult = await paginatedLoader.fetchMore();

      paginatedLoader.shouldThrowError = false;

      // Should be set
      expect(fetchMoreResult.status, StaleMateFetchMoreStatus.failure);
      expect(fetchMoreResult.moreDataAvailable, false);
      expect(fetchMoreResult.hasData, false);
      expect(fetchMoreResult.isDone, false);
      expect(fetchMoreResult.isFailure, true);
      expect(fetchMoreResult.isAlreadyFetching, false);
      expect(fetchMoreResult.error, isNotNull);
      expect(fetchMoreResult.requireError, isNotNull);
      expect(fetchMoreResult.fetchMoreInitiatedAt, isNotNull);
      expect(fetchMoreResult.requireFetchMoreInitiatedAt, isNotNull);
      expect(fetchMoreResult.fetchMoreFinishedAt, isNotNull);
      expect(fetchMoreResult.requireFetchMoreFinishedAt, isNotNull);
      expect(fetchMoreResult.fetchMoreDuration, isNotNull);
      expect(fetchMoreResult.requireFetchMoreDuration, isNotNull);
      expect(fetchMoreResult.fetchMoreParameters, {'page': 2, 'pageSize': 10});

      // Should not be set
      expect(fetchMoreResult.newData, null);
      expect(
          () => fetchMoreResult.requireNewData, throwsA(isA<AssertionError>()));
      expect(fetchMoreResult.mergedData, null);
      expect(() => fetchMoreResult.requireMergedData,
          throwsA(isA<AssertionError>()));

      // Check that data is still in the loader
      expect(paginatedLoader.value,
          equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 10)));

      // Verify that another successful fetch more works as expected
      final fetchMoreSubsequentSuccess = await paginatedLoader.fetchMore();

      expect(fetchMoreSubsequentSuccess.moreDataAvailable, true);
      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 20)),
      );
      expect(fetchMoreSubsequentSuccess.newData,
          MockStaleMatePaginatedLoader.remoteItems.sublist(10, 20));
      expect(fetchMoreSubsequentSuccess.mergedData,
          MockStaleMatePaginatedLoader.remoteItems.sublist(0, 20));
    });

    test('Loader starts from scratch when refreshed', () async {
      await paginatedLoader.initialize();
      await paginatedLoader.fetchMore();

      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 20)),
      );

      await paginatedLoader.refresh();

      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 10)),
      );
    });
  });

  group('Paginated loader configurations', () {
    verifyLoaderWithConfiguration(
        MockStaleMatePaginatedLoader paginatedLoader) async {
      // Verify that the correct page size is loaded at start
      await paginatedLoader.initialize();
      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 10)),
      );

      // Verify that the correct page size is loaded when fetching more
      final fetchMorefirstResult = await paginatedLoader.fetchMore();
      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 20)),
      );

      // Verify that we can still fetch more
      expect(fetchMorefirstResult.moreDataAvailable, true);

      final fetchMoreResult2 = await paginatedLoader.fetchMore();
      expect(
        paginatedLoader.value,
        equals(MockStaleMatePaginatedLoader.remoteItems.sublist(0, 25)),
      );

      // Verify that we can't fetch more
      expect(fetchMoreResult2.moreDataAvailable, false);
    }

    test('Page Pagination config', () async {
      final paginatedLoader = MockStaleMatePaginatedLoader(
        paginationConfig: StaleMatePagePagination(
          pageSize: 10,
        ),
      );

      await verifyLoaderWithConfiguration(paginatedLoader);
    });

    test('Page Pagination config zero indexed', () async {
      final paginatedLoader = MockStaleMatePaginatedLoader(
        paginationConfig: StaleMatePagePagination(
          pageSize: 10,
          zeroBasedIndexing: true,
        ),
      );

      await verifyLoaderWithConfiguration(paginatedLoader);
    });

    test('Offset Pagination config', () async {
      final paginatedLoader = MockStaleMatePaginatedLoader(
        paginationConfig: StaleMateOffsetLimitPagination(
          limit: 10,
        ),
      );

      await verifyLoaderWithConfiguration(paginatedLoader);
    });

    test('Cursor pagination config', () async {
      final paginatedLoader = MockStaleMatePaginatedLoader(
        paginationConfig: StaleMateCursorPagination(
          limit: 10,
          // In this case the cursor is the item itself since it is a string
          getCursor: (item) => item,
        ),
      );

      await verifyLoaderWithConfiguration(paginatedLoader);
    });
  });

  group('test state of loader', () {
    test('state progression while fetching more', () async {
      final paginatedLoader = MockStaleMatePaginatedLoader(
        paginationConfig: StaleMatePagePagination(
          pageSize: 10,
        ),
      );

      expect(paginatedLoader.state.localStatus, StaleMateStatus.idle);
      expect(paginatedLoader.state.remoteStatus, StaleMateStatus.idle);

      await paginatedLoader.initialize();

      expect(paginatedLoader.state.localStatus, StaleMateStatus.error);
      expect(paginatedLoader.state.remoteStatus, StaleMateStatus.loaded);

      final fetchMoreFuture = paginatedLoader.fetchMore();
      expect(paginatedLoader.state.remoteStatus, StaleMateStatus.loading);
      expect(paginatedLoader.state.fetchReason, StaleMateFetchReason.fetchMore);

      await fetchMoreFuture;

      expect(paginatedLoader.state.remoteStatus, StaleMateStatus.loaded);
      expect(paginatedLoader.state.fetchReason, StaleMateFetchReason.fetchMore);
    });
  });
}
