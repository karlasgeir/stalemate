import 'dart:async';

import 'package:flutter/widgets.dart';
import '../clock/clock.dart';
import 'stalemate_refresh_config.dart';

/// This class handles refreshing data for [DataLoader]s.
/// If a stale period is set, the data will be refreshed
/// after the stale period has passed.
/// The class uses the [WidgetsBindingObserver] to listen for app lifecycle changes.
/// If the app is resumed, the data will be refreshed when the stale period has passed.
/// If the app is backgrounded, the refresh timer will be suspended
class StaleMateRefresher extends WidgetsBindingObserver {
  /// The clock that will be used to determine the current time
  /// This is exposed for testing purposes and defaults to [SystemClock]
  late final Clock _clock;

  /// The data loader that will be used to refresh the data
  final Future<bool> Function() _onRefresh;

  /// The refresh config that decides when the data should be refreshed
  /// If this is null, the data will not be refreshed automatically
  final StaleMateRefreshConfig? _refreshConfig;

  /// The time when the data was last refreshed
  late DateTime _lastRefresh;

  /// The timer that will be used to refresh the data
  Timer? _refreshTimer;

  /// Whether the data is currently being refreshed
  bool isRefreshing = false;

  StaleMateRefresher({
    required Future<bool> Function() onRefresh,
    StaleMateRefreshConfig? refreshConfig,
    Clock? clock,
  })  : _refreshConfig = refreshConfig,
        _onRefresh = onRefresh {
    _clock = clock ?? SystemClock();
    _lastRefresh = _clock.now();
    if (_refreshConfig != null) {
      _scheduleNextRefresh();
      WidgetsBinding.instance.addObserver(this);
    }
  }

  /// Whether the data loader supports auto refresh
  bool get supportsAutoRefresh => _refreshConfig != null;

  /// Whether the data is stale
  bool get isStale =>
      supportsAutoRefresh && _refreshConfig!.isStale(_lastRefresh);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (isStale) {
        refresh();
      } else {
        _scheduleNextRefresh();
      }
    } else if (state == AppLifecycleState.paused) {
      _stopRefreshTimer();
    }
  }

  /// Refreshes the data
  Future<bool> refresh() async {
    // Guard against multiple simultaneous refreshes
    if (isRefreshing) {
      return true;
    }

    isRefreshing = true;

    var refreshed = false;
    try {
      refreshed = await _onRefresh();
    } catch (error) {
      // Refresh failed
    }

    // Since the refresh timer will be scheduled based on the last refresh time,
    // we need to update the last refresh time before scheduling the next refresh
    // even if the refresh failed
    _lastRefresh = _clock.now();
    _scheduleNextRefresh();
    isRefreshing = false;

    return refreshed;
  }

  /// Schedules the next refresh
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
