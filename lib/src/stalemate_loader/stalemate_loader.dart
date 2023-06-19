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

export '../logging/stalemate_log_level.dart';

part '../stalemate_paginated_loader/stalemate_paginated_loader.dart';

/// Handles the loading and syncing of data from local and remote sources
///
/// This class is used to load data from local and remote sources.
/// It can be used to load data from a single source, or from both local and remote sources.
/// This data loader makes no assumptions about the data that is being loaded, nor the
/// sources that are being used.
///
/// The data loader registers itself in the [StaleMateRegistry] when it is created
/// and unregisters itself when it is cleared.
///
/// How to implement:
/// - Extend this class with the data type(<T>) that you want to load data for
/// - Override the methods that are needed for your use case.
/// - If you want to get remote data, override [getRemoteData]
///     - The method should return a [Future] that resolves to the data that was loaded remotely
///     - If the data could not be loaded, throw an exception, the loader will handle it
///       by keeping the old data or adding the error to the data stream, depending on if
///       the value of the [showLocalDataOnError].
/// - If you want to get local data, override [getLocalData]
///   - The method should return a [Future] that resolves to the data that was loaded locally
///   - If the data could not be loaded, throw an exception, the loader will ignore it and try
///     to load the data remotely.
/// - If you want to store local data, override [storeLocalData]
///     - The method receives the data that should be stored locally
///     - The method should return a [Future] that resolves when the data has been stored
/// - If you want to remove local data, override [removeLocalData]
///    - The method receives the data that should be removed locally
///    - The method should return a [Future] that resolves when the data has been removed
///
/// Usecases:
/// - Remote only: For data that is only loaded from remote sources and never stored locally
///     - Just implement [getRemoteData]
/// - Local only: For data that is only loaded from local sources and never stored remotely
///    - Usually implement [getLocalData], [storeLocalData] and [removeLocalData]
///    - You can use the [addData] method on the loader to add data to the data stream and it will be stored
///     locally automatically using the [storeLocalData] method
/// - Local and remote: For data that is loaded from remote sources, but also stored locally for offline use, faster startup etc.
///     - Usually implement [getRemoteData], [getLocalData], [storeLocalData] and [removeLocalData]
///
/// Example:
/// ```dart
/// class MyDataLoader extends StaleMateLoader<List<MyData>> {
///  final LocalDataSource _localDataSource;
///  final RemoteDataSource _remoteDataSource;
///
///  MyDataLoader({
///    required this.localDataSource,
///    required this.remoteDataSource,
///  }) : super(emptyValue: []);
///
///  @override
///  Future<List<MyData>> getRemoteData() async {
///    // Load the data from the remote data source
///    return _remoteDataSource.getData();
///  }
///
///  @override
///  Future<List<MyData>> getLocalData() async {
///    // Load the data from the local data source
///    return _localDataSource.getData();
///  }
///
///  @override
///  Future<void> storeLocalData(List<MyData> data) async {
///    // Store the data in the local data source
///    return _localDataSource.storeData(data);
///  }
///
///  @override
///  Future<void> removeLocalData(List<MyData> data) async {
///    // Remove the data from the local data source
///    return _localDataSource.removeData(data);
///  }
/// }
/// ```
abstract class StaleMateLoader<T> {
  /// Logger instance to be used by the data loader
  late Logger _logger;

  /// The empty value that will be used to seed the stream
  ///
  /// For arrays this is usually an empty array, for strings an empty string,
  /// for nullable types this is usually null, etc.
  final T emptyValue;

  /// Whether or not the data should be updated when the data loader is initialized
  ///
  /// Defaults to true
  final bool updateOnInit;

  /// Whether or not the local data should be shown when an error occurs
  ///
  /// Defaults to true
  final bool showLocalDataOnError;

  /// The behavior subject that will be used to stream the data
  late final BehaviorSubject<T> _subject;

  /// The refresher that will be used to refresh the data
  late final StaleMateRefresher<T> _refresher;

  /// Creates a new data loader
  ///
  /// The data loader registers itself in the [StaleMateRegistry] when it is created
  /// and unregisters itself when it is cleared.
  ///
  /// Arguments:
  /// - [emptyValue]: The empty value that will be used to determine if the data is empty
  ///     -  For arrays this is usually an empty array, for strings an empty string,
  ///       for nullable types this is usually null, etc.
  /// - [updateOnInit]: Whether or not the data should be updated when the data loader is initialized
  ///    - Defaults to true
  /// - [showLocalDataOnError]: Whether or not the local data should be shown when an error occurs
  ///   - Defaults to true
  /// - [refreshConfig]: The refresh config that will be used to automatically refresh the data
  ///     - If this is not provided, the data will not be refreshed automatically
  /// - [logLevel]: Log level that will be used for this data loader
  ///    - Defaults to [StaleMateLogLevel.none]
  StaleMateLoader({
    required this.emptyValue,
    this.updateOnInit = true,
    this.showLocalDataOnError = true,
    StaleMateRefreshConfig? refreshConfig,
    StaleMateLogLevel? logLevel,
  }) {
    // Initialize the logger
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
  ///
  /// This stream will emit the data that is loaded from the local or remote data source
  /// and will be updated automatically when the data is refreshed.
  Stream<T> get stream => _subject.stream;

  /// Returns the current value of the data
  ///
  /// This value will be updated automatically when the data is refreshed.
  /// If the data is not available yet, the [emptyValue] will be returned.
  T get value => _subject.valueOrNull ?? emptyValue;

  /// Whether the data stream is currently empty
  ///
  /// This returns true if the data stream is empty or if the data stream is not available yet.
  bool get isEmpty => value == emptyValue;

  /// Retrieves the data from the local source
  ///
  /// **Override this method to implement local data retrieval**
  ///
  /// This method will be called when local data is requested.
  ///
  /// How to implement:
  /// - Retrieve the data from wherever it is stored locally
  /// - Return the local data
  /// - If the local data is empty, return the [emptyValue]
  /// - If there is an error retrieving the local data, throw the error
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<List<MyData>> getLocalData() async {
  ///  // Load the data from the local data source
  ///  return _localDataSource.getData();
  /// }
  /// ```
  Future<T> getLocalData() async {
    return value;
  }

  /// Retrieves the data from the remote source
  ///
  /// **Override this method to implement remote data retrieval**
  ///
  /// This method will be called when remote data is requested.
  ///
  /// How to implement:
  /// - Retrieve the data from the remote source
  /// - Return the remote data
  /// - If the remote data is empty, return the [emptyValue]
  /// - If there is an error retrieving the remote data, throw the error
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<List<MyData>> getRemoteData() async {
  ///   // Load the data from the remote data source
  ///   return _remoteDataSource.getData();
  /// }
  /// ```
  Future<T> getRemoteData() async {
    return value;
  }

  /// Stores the data in the local source
  ///
  /// **Override this method to implement local data storage**
  ///
  /// This method will be called when the data should be stored locally.
  ///
  /// How to implement:
  /// - Store the data in the local data source
  /// - If there is an error storing the data, throw the error
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> storeLocalData(List<MyData> data) async {
  ///   // Store the data in the local data source
  ///   await _localDataSource.storeData(data);
  /// }
  /// ```
  Future<void> storeLocalData(T data) async {
    // Do nothing
  }

  /// Removes the data from the local source
  ///
  /// **Override this method to implement local data removal**
  ///
  /// This method will be called when the data should be removed from the local source.
  ///
  /// How to implement:
  /// - Remove the data from the local data source
  /// - If there is an error removing the data, throw the error
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> removeLocalData() async {
  ///   // Remove the data from the local data source
  ///   await _localDataSource.removeData();
  /// }
  /// ```
  Future<void> removeLocalData() async {
    // Do nothing
  }

  /// Adds an error to the data stream
  ///
  /// **This will add the error to the data stream, removing any previous data.**
  ///
  /// This should only be used when you want to show an error instead of any previous data.
  ///
  /// Can be useful if there are any errors that are external to the loader, but should be shown
  /// to the user through reacting to the data stream.
  _addError(Object error) {
    _logger.d('Added error to stream', error, StackTrace.current);
    _subject.addError(error);
  }

  /// Adds the data to the data stream
  ///
  /// If local storage is implemented, the data will be stored locally.
  ///
  /// Useful when you want to add data to the stream manually.
  ///
  /// Usecases:
  /// - The only way to add data to loaders that are local only
  /// - If you are creating an item on the server and want to add it to the stream
  ///   after it has been created, without having to refresh the whole data
  ///
  /// Example:
  /// ```dart
  /// // Create the item on the server
  /// final item = await _itemRepository.createItem();
  /// // Get the current items
  /// final items = _itemLoader.value;
  /// // Add the item to the list
  /// items.add(item);
  /// // Add the item to the stream
  /// _itemLoader.addData(items);
  ///  // New data available in the stream
  /// ```
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

  /// Handles errors from loading remote data
  ///
  /// - If [showLocalDataOnError] is true, the error will only be added to the stream if there is no local data available
  /// - If [showLocalDataOnError] is false, the error will always be added to the stream
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
  ///
  /// Ignores any errors that occur
  ///
  /// Returns true if local data was loaded, false if not
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
  ///
  /// Throws an error if loading remote data fails
  ///
  /// Returns the loaded data
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

  /// Initializes the loader
  ///
  /// - Loads local data
  /// - If [updateOnInit] is true or there is no local data available, loads remote data
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

  /// Refreshes the data
  ///
  /// Returns the [StaleMateRefreshResult] of the refresh
  /// The status of the [StaleMateRefreshResult] indicates if the refresh was successful or not
  /// - [StaleMateRefreshStatus.success] if the refresh was successful
  /// - [StaleMateRefreshStatus.failure] if the refresh failed
  /// - [StaleMateRefreshStatus.alreadyRefreshing] if the refresh was already in progress
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

  /// Resets the loader
  ///
  /// - If [removeLocalData] is implemented, removes local data
  /// - Adds empty value to stream
  Future<void> reset() async {
    _logger.i('Resetting data...');
    await removeLocalData();
    _logger.d('Local data removed');
    _logger.d('Adding empty value to stream');
    _subject.add(emptyValue);
  }

  /// Sets the log level of the loader
  ///
  /// - [logLevel] the log level to set
  /// Available log levels:
  /// - [StaleMateLogLevel.debug] : Logs everything
  /// - [StaleMateLogLevel.info] : Logs info, warnings and errors
  /// - [StaleMateLogLevel.warning] : Logs warnings and errors
  /// - [StaleMateLogLevel.error] : Logs errors
  /// - [StaleMateLogLevel.none] : Logs nothing
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

  /// Closes the loader
  ///
  /// - Closes the stream
  /// - Disposes the refresher
  /// - Unregisters the loader from the registry
  close() {
    _logger.d('Closing stream');
    _subject.close();
    _refresher.dispose();
    _logger.d('Unregistering from registry');
    StaleMateRegistry.instance.unregister(this);
  }
}
