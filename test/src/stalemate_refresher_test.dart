import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stalemate/src/stalemate_loader/stalemate_loader.dart';
import 'package:stalemate/src/stalemate_refresher/stalemate_refresh_config.dart';
import 'package:stalemate/src/stalemate_refresher/stalemate_refresher.dart';

import '../mocks/mock_clock.dart';
import 'stalemate_refresher_test.mocks.dart';

@GenerateMocks([StaleMateRefreshConfig, StaleMateLoader])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStaleMateLoader mockDataLoader;
  late StalePeriodRefreshConfig refreshConfig;
  late MockClock clock;

  setUp(() {
    mockDataLoader = MockStaleMateLoader();
    clock = MockClock();
    refreshConfig = StalePeriodRefreshConfig(
        stalePeriod: const Duration(minutes: 5), clock: clock);
  });

  test('refresher refresh calls refresh', () {
    when(mockDataLoader.refresh()).thenAnswer((_) async => true);
    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    refresher.refresh();
    verify(mockDataLoader.refresh()).called(1);
    verifyNoMoreInteractions(mockDataLoader);
  });

  test('refresher refresh call works without refresh config', () {
    when(mockDataLoader.refresh()).thenAnswer((_) async => true);
    final refresher = StaleMateRefresher(onRefresh: mockDataLoader.refresh);
    refresher.refresh();
    verify(mockDataLoader.refresh()).called(1);
    verifyNoMoreInteractions(mockDataLoader);
  });

  test('refresher does not call refresh before stale period', () async {
    when(mockDataLoader.refresh()).thenAnswer((_) async => true);
    refreshConfig = StalePeriodRefreshConfig(
        stalePeriod: const Duration(milliseconds: 100));
    StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    verifyNever(mockDataLoader.refresh());
    verifyNoMoreInteractions(mockDataLoader);
  });

  test('refresher calls refresh after stale period', () async {
    when(mockDataLoader.refresh()).thenAnswer((_) async => true);
    refreshConfig = StalePeriodRefreshConfig(
        stalePeriod: const Duration(milliseconds: 100));
    StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    await Future<void>.delayed(const Duration(milliseconds: 110));
    verify(mockDataLoader.refresh()).called(1);
    verifyNoMoreInteractions(mockDataLoader);
  });

  test('refresher does not call refresh when app is paused', () {
    when(mockDataLoader.refresh()).thenAnswer((_) async => true);

    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    refresher.didChangeAppLifecycleState(AppLifecycleState.paused);
    clock.advance(const Duration(minutes: 6));
    verifyNever(mockDataLoader.refresh());
  });

  test('refresher calls refresh when app is resumed', () async {
    when(mockDataLoader.refresh()).thenAnswer((_) async => true);

    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
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
    when(mockDataLoader.refresh()).thenAnswer((_) async => true);

    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    refresher.didChangeAppLifecycleState(AppLifecycleState.paused);
    clock.advance(const Duration(minutes: 4));
    refresher.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    verifyNever(mockDataLoader.refresh());
  });

  test(
      'refresher does not auto update on app resume when no refresh config is set',
      () {
    when(mockDataLoader.refresh()).thenAnswer((_) async => true);

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
      return true;
    });

    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    refresher.refresh();
    refresher.refresh();
    await Future<void>.delayed(const Duration(milliseconds: 110));

    verify(mockDataLoader.refresh()).called(1);
  });

  test('refresher dispose method stops timer', () async {
    when(mockDataLoader.refresh()).thenAnswer((_) async => true);
    refreshConfig = StalePeriodRefreshConfig(
        stalePeriod: const Duration(milliseconds: 100));

    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    refresher.dispose();
    await Future.delayed(const Duration(milliseconds: 110));
    verifyNever(mockDataLoader.refresh());
  });

  test('refresher schedules next refresh even if refresh fails', () async {
    when(mockDataLoader.refresh()).thenAnswer((_) async => false);
    refreshConfig = StalePeriodRefreshConfig(
        stalePeriod: const Duration(milliseconds: 100));

    final refresher = StaleMateRefresher(
        refreshConfig: refreshConfig, onRefresh: mockDataLoader.refresh);
    await refresher.refresh();
    when(mockDataLoader.refresh()).thenAnswer((_) async => true);
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
    when(mockDataLoader.refresh()).thenAnswer((_) async => true);
    await Future.delayed(const Duration(milliseconds: 110));

    verify(mockDataLoader.refresh()).called(2);
  });
}
