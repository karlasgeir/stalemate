import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stalemate/src/stalemate_loader/stalemate_loader.dart';
import 'package:stalemate/src/stalemate_refresher/stalemate_refresh_config.dart';
import 'package:stalemate/src/stalemate_refresher/stalemate_refresh_result.dart';
import 'package:stalemate/src/stalemate_refresher/stalemate_refresher.dart';

import '../mocks/mock_clock.dart';
import 'stalemate_refresher_test.mocks.dart';

@GenerateMocks([StaleMateRefreshConfig, StaleMateLoader])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStaleMateLoader<bool> mockDataLoader;
  late StalePeriodRefreshConfig refreshConfig;
  late MockClock clock;
  final mockRefreshSuccessResult = StaleMateRefreshResult.success(
    data: true,
    refreshInitiatedAt: DateTime.now(),
    refreshFinishedAt: DateTime.now().add(const Duration(milliseconds: 100)),
  );

  final mockRefreshFailureResult = StaleMateRefreshResult.failure(
    error: Exception('Refresh failed'),
    refreshInitiatedAt: DateTime.now(),
    refreshFinishedAt: DateTime.now().add(const Duration(milliseconds: 100)),
  );

  setUp(() {
    mockDataLoader = MockStaleMateLoader<bool>();
    clock = MockClock();
    refreshConfig = StalePeriodRefreshConfig(
      stalePeriod: const Duration(minutes: 5),
      clock: clock,
    );
  });

  test('refresher refresh calls refresh', () async {
    when(mockDataLoader.refresh())
        .thenAnswer((_) async => mockRefreshSuccessResult);
    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    final refreshResult = await refresher.refresh();

    expect(refreshResult.status, equals(mockRefreshSuccessResult.status));

    verify(mockDataLoader.refresh()).called(1);
    verifyNoMoreInteractions(mockDataLoader);
  });

  test('refresher refresh call works without refresh config', () async {
    when(mockDataLoader.refresh())
        .thenAnswer((_) async => mockRefreshSuccessResult);
    final refresher = StaleMateRefresher(onRefresh: mockDataLoader.refresh);
    final refreshResult = await refresher.refresh();

    expect(refreshResult.status, equals(mockRefreshSuccessResult.status));

    verify(mockDataLoader.refresh()).called(1);
    verifyNoMoreInteractions(mockDataLoader);
  });

  test('refresher does not call refresh before stale period', () async {
    when(mockDataLoader.refresh())
        .thenAnswer((_) async => mockRefreshSuccessResult);

    refreshConfig = StalePeriodRefreshConfig(
      stalePeriod: const Duration(milliseconds: 100),
    );

    StaleMateRefresher(
      refreshConfig: refreshConfig,
      onRefresh: mockDataLoader.refresh,
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    verifyNever(mockDataLoader.refresh());
    verifyNoMoreInteractions(mockDataLoader);
  });

  test('refresher calls refresh after stale period', () async {
    when(mockDataLoader.refresh()).thenAnswer(
      (_) async => mockRefreshSuccessResult,
    );

    refreshConfig = StalePeriodRefreshConfig(
      stalePeriod: const Duration(milliseconds: 100),
    );

    StaleMateRefresher(
      refreshConfig: refreshConfig,
      onRefresh: mockDataLoader.refresh,
    );

    await Future<void>.delayed(const Duration(milliseconds: 110));

    verify(mockDataLoader.refresh()).called(1);
    verifyNoMoreInteractions(mockDataLoader);
  });

  test('refresher does not call refresh when app is paused', () async {
    when(mockDataLoader.refresh()).thenAnswer(
      (_) async => mockRefreshSuccessResult,
    );

    refreshConfig = StalePeriodRefreshConfig(
      stalePeriod: const Duration(milliseconds: 100),
    );

    final refresher = StaleMateRefresher(
      refreshConfig: refreshConfig,
      onRefresh: mockDataLoader.refresh,
    );

    refresher.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 110));
    verifyNever(mockDataLoader.refresh());
  });

  test('refresher calls refresh when app is resumed', () async {
    when(mockDataLoader.refresh())
        .thenAnswer((_) async => mockRefreshSuccessResult);

    final refresher = StaleMateRefresher(
      refreshConfig: refreshConfig,
      onRefresh: mockDataLoader.refresh,
    );
    refresher.didChangeAppLifecycleState(AppLifecycleState.paused);
    clock.advance(const Duration(minutes: 6));
    refresher.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    verify(mockDataLoader.refresh()).called(1);
    verifyNoMoreInteractions(mockDataLoader);
  });

  test(
      'refresher does not call refresh when app is resumed but data is not stale',
      () async {
    when(mockDataLoader.refresh()).thenAnswer(
      (_) async => mockRefreshSuccessResult,
    );

    final refresher = StaleMateRefresher(
      refreshConfig: refreshConfig,
      onRefresh: mockDataLoader.refresh,
    );

    refresher.didChangeAppLifecycleState(AppLifecycleState.paused);
    clock.advance(const Duration(minutes: 4));
    refresher.didChangeAppLifecycleState(AppLifecycleState.resumed);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    verifyNever(mockDataLoader.refresh());
  });

  test(
      'refresher does not auto update on app resume when no refresh config is set',
      () {
    when(mockDataLoader.refresh()).thenAnswer(
      (_) async => mockRefreshSuccessResult,
    );

    final refresher = StaleMateRefresher(onRefresh: mockDataLoader.refresh);
    refresher.didChangeAppLifecycleState(AppLifecycleState.paused);
    clock.advance(const Duration(minutes: 6));
    refresher.didChangeAppLifecycleState(AppLifecycleState.resumed);
    verifyNever(mockDataLoader.refresh());
  });

  test('refresher does not schedule another refresh while refreshing',
      () async {
    when(mockDataLoader.refresh()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return mockRefreshSuccessResult;
    });

    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    refresher.refresh();
    final secondRefreshResult = await refresher.refresh();

    expect(secondRefreshResult.status,
        equals(StaleMateRefreshStatus.alreadyRefreshing));

    await Future<void>.delayed(const Duration(milliseconds: 110));

    verify(mockDataLoader.refresh()).called(1);
  });

  test('refresher dispose method stops timer', () async {
    when(mockDataLoader.refresh()).thenAnswer(
      (_) async => mockRefreshSuccessResult,
    );
    refreshConfig = StalePeriodRefreshConfig(
      stalePeriod: const Duration(milliseconds: 100),
    );

    final refresher = StaleMateRefresher(
      refreshConfig: refreshConfig,
      onRefresh: mockDataLoader.refresh,
    );
    refresher.dispose();
    await Future.delayed(const Duration(milliseconds: 110));
    verifyNever(mockDataLoader.refresh());
  });

  test('refresher schedules next refresh even if refresh fails', () async {
    when(mockDataLoader.refresh())
        .thenAnswer((_) async => mockRefreshFailureResult);
    refreshConfig = StalePeriodRefreshConfig(
        stalePeriod: const Duration(milliseconds: 100));

    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    await refresher.refresh();
    when(mockDataLoader.refresh())
        .thenAnswer((_) async => mockRefreshSuccessResult);
    await Future.delayed(const Duration(milliseconds: 110));

    verify(mockDataLoader.refresh()).called(2);
  });

  test('refresher schedules next refresh even if refresh throws', () async {
    when(mockDataLoader.refresh()).thenThrow(Exception());
    refreshConfig = StalePeriodRefreshConfig(
        stalePeriod: const Duration(milliseconds: 100));

    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    await refresher.refresh();
    when(mockDataLoader.refresh())
        .thenAnswer((_) async => mockRefreshSuccessResult);
    await Future.delayed(const Duration(milliseconds: 110));

    verify(mockDataLoader.refresh()).called(2);
  });

  test('refresher does not schedule next refresh if disposed', () async {
    when(mockDataLoader.refresh())
        .thenAnswer((_) async => mockRefreshSuccessResult);
    refreshConfig = StalePeriodRefreshConfig(
        stalePeriod: const Duration(milliseconds: 100));

    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    refresher.dispose();
    await Future.delayed(const Duration(milliseconds: 110));

    verifyNever(mockDataLoader.refresh());
  });
}
