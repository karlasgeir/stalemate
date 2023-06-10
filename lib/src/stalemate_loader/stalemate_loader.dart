import 'package:rxdart/subjects.dart';

import '../stalemate_refresher/stalemate_refresh_config.dart';
import '../stalemate_refresher/stalemate_refresher.dart';
import '../stalemate_registry/stalemate_registry.dart';

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
  final T _emptyValue;

  /// Whether or not the data should be updated when the data loader is initialized
  /// Defaults to true
  final bool _updateOnInit;

  /// The subject that will be used to stream the data
  late final BehaviorSubject<T> _subject;

  /// The refresher that will be used to refresh the data
  late final StaleMateRefresher _refresher;

  /// Default constructor
  StaleMateLoader({
    required T emptyValue,
    bool updateOnInit = true,
    StaleMateRefreshConfig? refreshConfig,
  })  : _emptyValue = emptyValue,
        _updateOnInit = updateOnInit {
    _subject = BehaviorSubject.seeded(_emptyValue);
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
  T get value => _subject.value;

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

  /// Loads local data and adds it to the stream
  Future<bool> _loadLocalData() async {
    try {
      final localData = await getLocalData();
      _subject.add(localData);
      return true;
    } catch (e) {
      return false;
      // Do nothing, we'll try to get remote data
    }
  }

  /// Loads remote data and adds it to the stream
  Future<bool> _loadRemoteData() async {
    try {
      final remoteData = await getRemoteData();
      await addData(remoteData);
      return true;
    } catch (error) {
      if (value == null || value == _emptyValue) {
        _addError(error);
      }
      return false;
    }
  }

  /// Loads local data first, then remote data
  Future<void> initialize() async {
    await _loadLocalData();
    if (_updateOnInit) {
      await _refresher.refresh();
    }
  }

  /// Updates the data by loading remote data
  Future<bool> refresh() async {
    return _refresher.refresh();
  }

  /// Resets the data to the empty value and removes local data
  Future<void> reset() async {
    await removeLocalData();
    _subject.add(_emptyValue);
  }

  /// Closes the stream
  close() {
    _subject.close();
    _refresher.dispose();
    StaleMateRegistry.instance.unregister(this);
  }
}
