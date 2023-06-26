import 'dart:async';

import 'package:flutter/widgets.dart';

import '../clock/clock.dart';
import '../exceptions/not_supported_exception.dart';
import 'stalemate_refresh_result.dart';
import 'stalemate_refresh_config.dart';

/// Handles refreshing data
///
/// The class uses the [WidgetsBindingObserver] to listen for app lifecycle changes.
/// On lifecyle change:
/// - App resumed: If the data is stale, the data will be refreshed,
///   otherwise the refresh timer will be scheduled to
///   refresh the data when it becomes stale
/// - App backgrounded: The refresh timer will be suspended until the app is resumed
///
class StaleMateRefresher<T> extends WidgetsBindingObserver {
  /// A clock that can be used to determine the current time
  ///
  /// Defaults to [SystemClock], but can be overridden for testing
  final Clock _clock;

  /// The function that will be called to refresh the data
  ///
  /// This function should return the refreshed data
  final Future<T> Function() _onRefresh;

  /// The config that will be used to determine when to refresh the data
  ///
  /// If this is null, the data will not be refreshed automatically
  /// See also:
  /// - [StalePeriodRefreshConfig] : Refreshes the data after a specified stale period
  /// - [TimeOfDayRefreshConfig] : Refreshes the data at a specified time of day
  final StaleMateRefreshConfig? _refreshConfig;

  /// The time when the data was last refreshed
  ///
  /// This is used to determine if the data is stale
  late DateTime _lastRefresh;

  /// The timer that will be used to refresh the data
  ///
  /// Changes on app lifecycle changes:
  /// - App resumed: If data is not stale, the timer will be
  ///   scheduled to refresh the data when it becomes stale
  /// - App backgrounded: The timer will be suspended
  ///   until the app is resumed
  Timer? _refreshTimer;

  /// Whether the data is currently being refreshed
  bool isRefreshing = false;

  /// Creates a new [StaleMateRefresher]
  ///
  /// Arguments:
  /// - [onRefresh] : The function that will be called to refresh the data
  /// - [refreshConfig] : The config that will be used to determine when to refresh the data
  ///     - If this is null, the data will not be refreshed automatically
  /// - [clock] : A clock that can be used to determine the current time,
  ///     - Only used for testing
  ///     - Defaults to [SystemClock]
  StaleMateRefresher({
    required Future<T> Function() onRefresh,
    StaleMateRefreshConfig? refreshConfig,
    Clock? clock,
  })  : _refreshConfig = refreshConfig,
        _onRefresh = onRefresh,
        _clock = clock ?? SystemClock() {
    // Initialize the last refresh time to now
    _lastRefresh = _clock.now();

    // Schedule the next refresh if the config is not null
    if (_refreshConfig != null) {
      _scheduleNextRefresh();
      WidgetsBinding.instance.addObserver(this);
    }
  }

  /// Whether the data loader supports auto refresh
  bool get supportsAutoRefresh => _refreshConfig != null;

  /// Whether the data is stale
  ///
  /// Indicates that the data should be refreshed
  /// Always false if the data loader does not support auto refresh
  bool get isStale =>
      supportsAutoRefresh && _refreshConfig!.isStale(_lastRefresh);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (isStale) {
        // Refresh immediately if the data is stale when the app resumes
        refresh();
      } else {
        // Otherwise, schedule the next refresh
        _scheduleNextRefresh();
      }
    } else if (state == AppLifecycleState.paused) {
      // Stop the refresh timer when the app is backgrounded
      _stopRefreshTimer();
    }
  }

  /// Refresh the data
  ///
  /// This will call the [_onRefresh] function and return the result
  /// It doesn't matter if the data is stale or not,
  /// the loader will always support manual refresh
  ///
  /// Returns a [StaleMateRefreshResult] that indicates the result of the refresh
  /// Will never throw an error or return null, instead the error will be returned
  /// in the [StaleMateRefreshResult] object
  ///
  /// See also:
  /// - [StaleMateRefreshResult]
  Future<StaleMateRefreshResult<T>> refresh() async {
    final refreshInitiatedAt = _clock.now();

    // Guard against multiple simultaneous refreshes
    if (isRefreshing) {
      return StaleMateRefreshResult<T>.alreadyRefreshing(
        refreshInitiatedAt: refreshInitiatedAt,
        refreshFinishedAt: _clock.now(),
      );
    }

    isRefreshing = true;

    try {
      final refreshedData = await _onRefresh();

      _lastRefresh = _clock.now();

      // Schedule the next refresh
      _scheduleNextRefresh();

      isRefreshing = false;

      // We got the data, so return a success result
      return StaleMateRefreshResult<T>.success(
        data: refreshedData,
        refreshInitiatedAt: refreshInitiatedAt,
        refreshFinishedAt: _clock.now(),
      );
    } catch (error) {
      if (error is NotSupportedException) {
        // If the error is a NotSupportedException, we don't want to schedule the next refresh
        // because the data loader doesn't support any remote data
        _stopRefreshTimer();
      } else {
        // Since the refresh timer will be scheduled based on the last refresh time,
        // we need to update the last refresh time before scheduling the next refresh
        // even if the refresh failed
        _lastRefresh = _clock.now();
        _scheduleNextRefresh();
        isRefreshing = false;
      }

      return StaleMateRefreshResult<T>.failure(
        error: error,
        refreshInitiatedAt: refreshInitiatedAt,
        refreshFinishedAt: _clock.now(),
      );
    }
  }

  /// Schedules the next refresh
  ///
  /// This will cancel the current refresh timer and schedule a new one
  /// based on the current time and the refresh config
  ///
  /// If the data is already stale, this will refresh the data immediately
  ///
  /// If the data loader doesn't support auto refresh, this will do nothing
  ///
  /// See also:
  /// - [StaleMateRefreshConfig.getNextRefreshDelay]
  /// - [StaleMateRefreshConfig.isStale]
  _scheduleNextRefresh() {
    _stopRefreshTimer();

    // If the data loader shouldn't auto refresh, return
    if (!supportsAutoRefresh) {
      return;
    }

    // If the data is already stale, refresh immediately
    if (isStale) {
      refresh();
      return;
    }

    final nextRefreshDelay = _refreshConfig!.getNextRefreshDelay(_lastRefresh);
    // The next refresh delay should not be negative here since isStale would be true
    // but we check just in case
    if (!nextRefreshDelay.isNegative) {
      _refreshTimer = Timer(nextRefreshDelay, refresh);
    }
  }

  /// Stops the refresh timer
  _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Disposes the data refresher
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (supportsAutoRefresh) {
      WidgetsBinding.instance.removeObserver(this);
    }
  }
}
