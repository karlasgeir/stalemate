import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stalemate/src/stalemate_refresher/stalemate_refresh_config.dart';

import '../mocks/mock_clock.dart';

void main() {
  group('StalePeriodRefreshConfig', () {
    late StalePeriodRefreshConfig refreshConfig;
    late MockClock clock;
    const stalePeriod = Duration(minutes: 5);

    setUp(() {
      clock = MockClock();
      refreshConfig =
          StalePeriodRefreshConfig(stalePeriod: stalePeriod, clock: clock);
    });

    test(
        'getNextRefreshDelay should return remaining duration from last refresh time',
        () {
      final lastRefreshTime = clock.now();
      clock.advance(const Duration(minutes: 1));
      final nextRefreshDelay =
          refreshConfig.getNextRefreshDelay(lastRefreshTime);
      expect(
          nextRefreshDelay, equals(stalePeriod - const Duration(minutes: 1)));
    });

    test(
        'getNextRefreshDelay should return negative duration if the current time is after the stale period',
        () {
      final lastRefreshTime = clock.now();
      clock.advance(const Duration(minutes: 6));
      final nextRefreshDelay =
          refreshConfig.getNextRefreshDelay(lastRefreshTime);
      expect(nextRefreshDelay, equals(const Duration(minutes: -1)));
    });

    test(
        'isStale should return false if the current time is before the stale period',
        () {
      final lastRefreshTime = clock.now();
      clock.advance(const Duration(minutes: 1));
      expect(refreshConfig.isStale(lastRefreshTime), false);
    });

    test(
        'isStale should return true if the current time is after the stale period',
        () {
      final lastRefreshTime = clock.now();
      clock.advance(const Duration(minutes: 6));
      expect(refreshConfig.isStale(lastRefreshTime), true);
    });

    test(
        'isStale should return false if the current time is equal to the stale period',
        () {
      final lastRefreshTime = clock.now();
      clock.advance(const Duration(minutes: 5));
      expect(refreshConfig.isStale(lastRefreshTime), false);
    });
  });

  group('TimeOfDayRefreshConfig', () {
    late TimeOfDayRefreshConfig refreshConfig;
    late MockClock clock;
    const refreshTime = TimeOfDay(hour: 12, minute: 0);

    setUp(() {
      clock = MockClock();
      refreshConfig =
          TimeOfDayRefreshConfig(refreshTime: refreshTime, clock: clock);
    });

    test(
        'getNextRefreshelay should return remaining duration from last refresh time',
        () {
      clock.setNow(DateTime(2021, 1, 1, 00, 00));
      final lastRefreshTime = clock.now();
      clock.advance(const Duration(minutes: 1));
      final nextRefreshDelay =
          refreshConfig.getNextRefreshDelay(lastRefreshTime);
      expect(nextRefreshDelay, equals(const Duration(hours: 11, minutes: 59)));
    });

    test(
        'getNextRefreshDelay should return negative duration if the current time is after the refresh time',
        () {
      final lastRefreshTime = DateTime(2021, 1, 1, 0, 0);
      clock.setNow(DateTime(2021, 1, 1, 12, 1));
      final nextRefreshDelay =
          refreshConfig.getNextRefreshDelay(lastRefreshTime);
      expect(nextRefreshDelay, equals(const Duration(minutes: -1)));
    });

    test(
        'getNextRefreshDelay should return zero duration if the current time is equal to the refresh time',
        () {
      final lastRefreshTime = DateTime(2021, 1, 1, 0, 0);
      clock.setNow(DateTime(2021, 1, 1, 12, 0));
      final nextRefreshDelay =
          refreshConfig.getNextRefreshDelay(lastRefreshTime);
      expect(nextRefreshDelay, equals(const Duration()));
    });

    test(
        'isStale should return false if the current time is before the refresh time',
        () {
      final lastRefreshTime = DateTime(2021, 1, 1, 0, 0);
      clock.setNow(DateTime(2021, 1, 1, 11, 59));
      expect(refreshConfig.isStale(lastRefreshTime), false);
    });

    test(
        'isStale should return true if the current time is after the refresh time',
        () {
      final lastRefreshTime = DateTime(2021, 1, 1, 0, 0);
      clock.setNow(DateTime(2021, 1, 1, 12, 1));
      expect(refreshConfig.isStale(lastRefreshTime), true);
    });

    test(
        'isStale should return false if the current time is equal to the refresh time',
        () {
      final lastRefreshTime = DateTime(2021, 1, 1, 0, 0);
      clock.setNow(DateTime(2021, 1, 1, 12, 0));
      expect(refreshConfig.isStale(lastRefreshTime), false);
    });
  });
}
