export '../logging/stalemate_log_level.dart';

import 'package:logger/logger.dart';
import 'package:rxdart/subjects.dart';
import '../logging/stalemate_log_level.dart';
import '../logging/tagged_logging_printer.dart';
import '../stalemate_refresher/stalemate_refresh_result.dart';

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
  /// A logger that will be used to log errors and debug messages
  late Logger _logger;

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
    /// The empty value that will be used to seed the stream
    /// For arrays this is usually an empty array, for strings an empty string,
    /// for nullable types this is usually null, etc.
    required this.emptyValue,

    /// Whether or not the data should be updated when the data loader is initialized
    this.updateOnInit = true,

    /// Whether or not the local data should be shown when an error occurs
    this.showLocalDataOnError = true,

    /// The refresh config that will be used to refresh the data
    StaleMateRefreshConfig? refreshConfig,

    /// Log level that will be used for this data loader
    /// Defaults to [StaleMateLogLevel.none]
    StaleMateLogLevel? logLevel,
  }) {
    setLogLevel(logLevel ?? StaleMateRegistry.instance.defaultLogLevel);

    // Initialize the subject and the refresher
    _subject = BehaviorSubject();
    // Initialize the refresher
    _refresher = StaleMateRefresher(
      refreshConfig: refreshConfig,
      onRefresh: _loadRemoteData,
    );

    _logger.d('Registered in registry');
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
  _addError(Object error) {
    _logger.d('Added error to stream', error, StackTrace.current);
    _subject.addError(error);
  }

  /// Adds data to the stream and stores it locally
  Future<void> addData(T data) async {
    _logger.d('Added data of type ${data.runtimeType} to stream');
    _subject.add(data);
    try {
      _logger.i('Storing local data of type ${data.runtimeType}...');
      _logger.d('Local data to store:');
      _logger.d(data);
      await storeLocalData(data);
      _logger.d('Local data stored successfully');
    } catch (error, stackTrace) {
      _logger.e('Failed to store local data', error, stackTrace);
    }
  }

  void _onRemoteDataError(Object error) {
    _logger.e('Failed to load remote data', error, StackTrace.current);
    if (!showLocalDataOnError) {
      _logger.d('showLocalDataOnError is true, adding error to stream');
      _addError(error);
    } else if (isEmpty) {
      _logger.d('No local data available, adding error to stream');
      _addError(error);
    } else {
      _logger.d('Local data available, keeping local data in stream');
    }
  }

  /// Loads local data and adds it to the stream
  Future<bool> _loadLocalData() async {
    try {
      _logger.d('Loading local data...');
      final localData = await getLocalData();
      if (localData != emptyValue) {
        _subject.add(localData);
        _logger.i(
          'Local data loaded and added to stream',
        );
        _logger.d('Local data loaded:');
        _logger.d(localData);
        return true;
      }
      _logger.i('No local data was empty');
      return false;
    } catch (e, stackTrace) {
      _logger.e('Failed to load local data', e, stackTrace);
      return false;
    }
  }

  /// Loads remote data and adds it to the stream
  Future<T> _loadRemoteData() async {
    try {
      _logger.i('Loading remote data...');
      final remoteData = await getRemoteData();
      _logger.d('Remote data loaded');
      _logger.d(remoteData);
      await addData(remoteData);
      return remoteData;
    } catch (error, stackTrace) {
      _logger.e('Failed to load remote data', error, stackTrace);
      _onRemoteDataError(error);

      rethrow;
    }
  }

  /// Loads local data first, then remote data
  Future<void> initialize() async {
    _logger.d('Initializing...');
    await _loadLocalData();
    if (updateOnInit || isEmpty) {
      if (isEmpty) {
        _logger
            .i('No local data available after initialization, refreshing data');
      } else {
        _logger.i(
          'Local data available after initialization, but updateOnInit is true, refreshing data',
        );
      }
      await _refresher.refresh();
    } else {
      _logger.i(
        'Local data available after initialization, updateOnInit is false, not refreshing data',
      );
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
    _logger.i('Refreshing data...');
    final refreshResult = await _refresher.refresh();
    if (refreshResult.isFailure) {
      _logger.e(
        'Failed to refresh data',
        refreshResult.error,
        StackTrace.current,
      );
    } else {
      _logger.i('Data refreshed successfully');
    }
    _logger.d(refreshResult);

    return refreshResult;
  }

  /// Resets the data to the empty value and removes local data
  Future<void> reset() async {
    _logger.i('Resetting data...');
    await removeLocalData();
    _logger.d('Local data removed');
    _logger.d('Adding empty value to stream');
    _subject.add(emptyValue);
  }

  void setLogLevel(StaleMateLogLevel logLevel) {
    // Initialize the logger
    _logger = Logger(
      level: staleMateLogLevelToLevel(logLevel),
      printer: TaggedLoggingPrinter(
        tag: runtimeType.toString(),
        methodCount: logLevel == StaleMateLogLevel.debug ? 2 : 0,
        printTime: logLevel == StaleMateLogLevel.debug,
        colors: false,
      ),
    );
    _logger.d('Setting log level to $logLevel');
  }

  /// Closes the stream
  close() {
    _logger.d('Closing stream');
    _subject.close();
    _refresher.dispose();
    _logger.d('Unregistering from registry');
    StaleMateRegistry.instance.unregister(this);
  }
}
