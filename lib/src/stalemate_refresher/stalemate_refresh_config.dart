import 'package:flutter/material.dart';
import 'package:stalemate/src/clock/clock.dart';

/// This class is used to determine when to refresh data in the [DataRefresher].
/// Implement [getNextRefreshDelay] to return the amount of time to wait before refreshing data.
abstract class StaleMateRefreshConfig {
  Duration getNextRefreshDelay(DateTime lastRefreshTime);
  bool isStale(DateTime lastRefreshTime) =>
      getNextRefreshDelay(lastRefreshTime).isNegative;
}

/// Stale period refresh config that will refresh data after the stale period has passed
class StalePeriodRefreshConfig extends StaleMateRefreshConfig {
  /// The duration after which data is considered stale
  final Duration stalePeriod;

  /// The clock used to determine the current time
  /// Defaults to [SystemClock], but can be overridden for testing
  final Clock _clock;

  StalePeriodRefreshConfig({required this.stalePeriod, Clock? clock})
      : _clock = clock ?? SystemClock();

  @override
  Duration getNextRefreshDelay(DateTime lastRefreshTime) {
    return stalePeriod - _clock.now().difference(lastRefreshTime);
  }
}

/// Time of day refresh config that will refresh data at the specified time of day
class TimeOfDayRefreshConfig extends StaleMateRefreshConfig {
  /// The time of day when the data should be refreshed
  final TimeOfDay refreshTime;

  /// The clock used to determine the current time
  /// Defaults to [SystemClock], but can be overridden for testing
  final Clock _clock;

  TimeOfDayRefreshConfig({required this.refreshTime, Clock? clock})
      : _clock = clock ?? SystemClock();

  @override
  Duration getNextRefreshDelay(DateTime lastRefreshTime) {
    final now = _clock.now();
    var nextRefreshTime = DateTime(
      now.year,
      now.month,
      now.day,
      refreshTime.hour,
      refreshTime.minute,
    );

    if (lastRefreshTime.isAfter(nextRefreshTime)) {
      // We have already refreshed after the refresh time today, schedule for next day
      nextRefreshTime = nextRefreshTime.add(const Duration(days: 1));
    }

    return nextRefreshTime.difference(now);
  }
}
