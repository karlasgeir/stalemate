import 'package:rxdart/subjects.dart';
import 'package:stalemate/src/stalemate_refresher/stalemate_refresh_result.dart';

import '../stalemate_paginated_loader/stale_mate_fetch_more_result.dart';
import '../stalemate_refresher/stalemate_refresh_config.dart';
import '../stalemate_refresher/stalemate_refresher.dart';
import '../stalemate_registry/stalemate_registry.dart';
import '../stalemate_paginated_loader/stalemate_pagination_config.dart';

part '../stalemate_paginated_loader/stalemate_paginated_loader.dart';

/// A class that handles the loading of data from local and remote sources
/// --------------------------------------------------------------------------------
/// The data loader registers itself in the [StaleMateRegistry] when it is created
/// and unregisters itself when it is cleared.
/// This is done to be able to clear all data loaders when the user logs out.
/// The data loader should not be used directly from the registry, but rather
/// through a repository using the data loader.
/// --------------------------------------------------------------------------------
/// If you want to use this class, you need to extend it and override the methods
/// that are needed for your use case.
/// If you want to get remote data, override [getRemoteData]
/// If you want to get local data, override [getLocalData]
/// If you want to store local data, override [storeLocalData]
/// If you want to remove local data, override [removeLocalData]
/// None of the methods are required to be overridden, but if you don't override
/// [getRemoteData] or [getLocalData], the data will not be loaded and the initial
/// data will be used instead.
/// This data loader can therefore be used to load data exclusively from local sources,
/// exclusively from remote sources, or from both sources depending on the use case.
/// ----------------------------------------------------------------------------------
/// The data is streamed using a [BehaviorSubject] to be able to get the current value
/// of the stream at any time.
/// ----------------------------------------------------------------------------------
///
abstract class StaleMateLoader<T> {
  /// The empty data that will be used to seed the stream
  /// For arrays this is usually an empty array, for strings an empty string,
  /// for nullable types this is usually null, etc.
  /// This value will also be used to reset the stream when [reset] is called.
  final T emptyValue;

  /// Whether or not the data should be updated when the data loader is initialized
  /// Defaults to true
  final bool updateOnInit;

  /// Whether or not the local data should be shown when an error occurs
  /// If this is set to false, the error will be shown instead even if local data is available
  /// This is useful if an error occurs while loading remote data, but you still want to show
  /// the local data if it is available.
  /// Defaults to true
  final bool showLocalDataOnError;

  /// The subject that will be used to stream the data
  late final BehaviorSubject<T> _subject;

  /// The refresher that will be used to refresh the data
  late final StaleMateRefresher<T> _refresher;

  /// Default constructor
  StaleMateLoader({
    required this.emptyValue,
    this.updateOnInit = true,
    this.showLocalDataOnError = true,
    StaleMateRefreshConfig? refreshConfig,
  }) {
    _subject = BehaviorSubject();
    _refresher = StaleMateRefresher(
      refreshConfig: refreshConfig,
      onRefresh: _loadRemoteData,
    );
    // Register this data loader in the registry
    StaleMateRegistry.instance.register(this);
  }

  /// Returns the stream of the data
  Stream<T> get stream => _subject.stream;

  /// Returns the current value of the stream
  /// If the stream is empty, the [emptyValue] will be returned
  T get value => _subject.valueOrNull ?? emptyValue;

  bool get isEmpty => value == emptyValue;

  /// Default implementation, override if local data is needed
  Future<T> getLocalData() async {
    return value;
  }

  /// Default implementation, override if remote data is needed
  Future<T> getRemoteData() async {
    return value;
  }

  /// Default implementation, override if local data should be stored
  Future<void> storeLocalData(T data) async {
    // Do nothing
  }

  /// Default implementation, override if local data should be removed
  Future<void> removeLocalData() async {
    // Do nothing
  }

  /// Adds an error to the stream
  _addError(Object error) => _subject.addError(error);

  /// Adds data to the stream and stores it locally
  Future<void> addData(T data) async {
    _subject.add(data);
    try {
      await storeLocalData(data);
    } catch (error) {
      // Do nothing, we don't want anything to break if we can't store the data in cache
    }
  }

  void _onRemoteDataError(Object error) {
    if (!showLocalDataOnError) {
      _addError(error);
    } else if (isEmpty) {
      _addError(error);
    }
  }

  /// Loads local data and adds it to the stream
  Future<bool> _loadLocalData() async {
    try {
      final localData = await getLocalData();
      if (localData != emptyValue) {
        _subject.add(localData);
        return true;
      }
      return false;
    } catch (e) {
      return false;
      // Do nothing, we'll try to get remote data
    }
  }

  /// Loads remote data and adds it to the stream
  Future<T> _loadRemoteData() async {
    try {
      final remoteData = await getRemoteData();
      await addData(remoteData);
      return remoteData;
    } catch (error) {
      _onRemoteDataError(error);

      rethrow;
    }
  }

  /// Loads local data first, then remote data
  Future<void> initialize() async {
    await _loadLocalData();
    if (updateOnInit || isEmpty) {
      await _refresher.refresh();
    }
  }

  /// Updates the data by loading remote data
  /// Returns the [StaleMateRefreshResult] of the refresh
  /// Note that you do not have to handle the refresh result if you don't want to
  /// If the refresh succeeds, the data will be added to the data stream automatically
  /// If the refresh fails, the error will be added to the data stream automatically
  /// depending on the configuration of the [showLocalDataOnError] property
  /// The refresh result is returned in case you want to handle it
  /// For example, to indicate to the user if the refresh succeeded or not
  /// or to show a message to the user if the refresh failed
  Future<StaleMateRefreshResult<T>> refresh() async {
    return _refresher.refresh();
  }

  /// Resets the data to the empty value and removes local data
  Future<void> reset() async {
    await removeLocalData();
    _subject.add(emptyValue);
  }

  /// Closes the stream
  close() {
    _subject.close();
    _refresher.dispose();
    StaleMateRegistry.instance.unregister(this);
  }
}
