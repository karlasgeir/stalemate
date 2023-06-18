import 'package:flutter/material.dart';

import 'stalemate_refresher.dart';
import '../clock/clock.dart';

/// Configures when the [StaleMateRefresher] should refresh data.
///
/// The [StaleMateRefresher] will schedule itself to
/// refresh data after [getNextRefreshDelay]
///
/// Implement this class to create custom refresh configs.
///
/// How to implement:
/// - Override [getNextRefreshDelay] to return the amount of time to wait before refreshing data.
/// - (optionally) Override [isStale] to return true if the data is stale
///   the default implementation of [isStale] will return true if the next refresh delay is negative
///   The default implementation is probably correct for most use cases, but can be overridden if needed
///
/// Implementations:
/// - [StalePeriodRefreshConfig]
/// - [TimeOfDayRefreshConfig]
///
/// Example:
/// ```dart
/// class MyRefreshConfig extends StaleMateRefreshConfig {
///  @override
///  Duration getNextRefreshDelay(DateTime lastRefreshTime) {
///   // Return the amount of time to wait before refreshing data
///   // In this example, we will refresh data after 5 minutes
///   return const Duration(minutes: 5);
///  }
/// ```
abstract class StaleMateRefreshConfig {
  Duration getNextRefreshDelay(DateTime lastRefreshTime);
  bool isStale(DateTime lastRefreshTime) =>
      getNextRefreshDelay(lastRefreshTime).isNegative;
}

/// Implementation of [StaleMateRefreshConfig] that will refresh data after a specified duration
///
/// Automatically schedules refresh after [stalePeriod]
/// has elapsed since the last refresh time
///
/// Example:
/// ```dart
/// StalePeriodRefreshConfig(
///  stalePeriod: const Duration(minutes: 5),
/// )
/// ```
class StalePeriodRefreshConfig extends StaleMateRefreshConfig {
  /// The duration after which data is considered stale
  ///
  /// The [StaleMateRefresher] will schedule itself to refresh data after
  /// [stalePeriod] has elapsed since the last refresh time
  final Duration stalePeriod;

  /// The clock used to determine the current time
  ///
  /// Defaults to [SystemClock], but can be overridden for testing
  final Clock _clock;

  /// Creates a [StalePeriodRefreshConfig] that will refresh data after [stalePeriod] has elapsed since the last refresh time
  ///
  /// Arguments:
  /// - **stalePeriod**: The duration after which data is considered stale
  /// - **clock**: (for testing purposes) Used to determine the current time,
  ///   defaults to [SystemClock], but can be overridden for testing
  StalePeriodRefreshConfig({
    required this.stalePeriod,
    Clock? clock,
  }) : _clock = clock ?? SystemClock();

  @override
  Duration getNextRefreshDelay(DateTime lastRefreshTime) {
    return stalePeriod - _clock.now().difference(lastRefreshTime);
  }
}

/// Implementation of [StaleMateRefreshConfig] that will refresh data at a specified time of day
///
/// Automatically schedules refresh at [refreshTime] every day
///
/// Example:
/// ```dart
/// TimeOfDayRefreshConfig(
///  refreshTime: const TimeOfDay(hour: 6, minute: 0),
/// )
/// ```
class TimeOfDayRefreshConfig extends StaleMateRefreshConfig {
  /// The time of day to refresh data
  ///
  /// The [StaleMateRefresher] will schedule itself to refresh data at [refreshTime] every day
  final TimeOfDay refreshTime;

  /// The clock used to determine the current time
  ///
  /// Defaults to [SystemClock], but can be overridden for testing
  final Clock _clock;

  /// Creates a [TimeOfDayRefreshConfig] that will refresh data at [refreshTime] every day
  ///
  /// Arguments:
  /// - **refreshTime**: The time of day to refresh data
  /// - **clock**: (for testing purposes) Used to determine the current time,
  ///   defaults to [SystemClock], but can be overridden for testing.
  TimeOfDayRefreshConfig({
    required this.refreshTime,
    Clock? clock,
  }) : _clock = clock ?? SystemClock();

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
