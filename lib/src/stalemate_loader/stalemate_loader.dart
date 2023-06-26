import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/subjects.dart';
import '../exceptions/no_local_data_exception.dart';
import '../exceptions/not_supported_exception.dart';
import '../logging/stalemate_log_level.dart';
import '../logging/tagged_logging_printer.dart';
import '../stalemate_paginated_loader/stale_mate_paginated_handler_mixin.dart';
import '../stalemate_refresher/stalemate_refresh_result.dart';
import '../stalemate_paginated_loader/stale_mate_fetch_more_result.dart';
import '../stalemate_refresher/stalemate_refresh_config.dart';
import '../stalemate_refresher/stalemate_refresher.dart';
import '../stalemate_registry/stalemate_registry.dart';
import '../stalemate_paginated_loader/stalemate_pagination_config.dart';
import 'stalemate_handler.dart';
import 'stalemate_loader_state.dart';
import 'stalemate_state_manager.dart';

export '../logging/stalemate_log_level.dart';
export 'stalemate_loader_state.dart';
export 'stalemate_handler.dart';
export '../stalemate_paginated_loader/stale_mate_paginated_handler_mixin.dart';

part '../stalemate_paginated_loader/stalemate_paginated_loader.dart';

/// A loader that loads data from its [StaleMateHandler] and streams it through a [BehaviorSubject]
///
/// The data loader registers itself in the [StaleMateRegistry] when it is created
/// and unregisters itself when it is cleared.
///
/// The loader supports manual refresh and automatic refresh.
///
/// To enable automatic refresh, provide a [StaleMateRefreshConfig] to the loader.
class StaleMateLoader<T, HandlerType extends StaleMateHandler<T>> {
  /// The handler that will be used to handle the data
  final HandlerType _handler;

  /// Logger instance to be used by the data loader
  late Logger _logger;

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

  /// Used to manage the state of the loader
  late final StaleMateStateManager _stateManager;

  /// Creates a new data loader
  ///
  /// The data loader registers itself in the [StaleMateRegistry] when it is created
  /// and unregisters itself when it is cleared.
  ///
  /// Arguments:
  /// - [updateOnInit] : Whether or not the data should be updated from remote when the data loader is initialized
  ///    - Defaults to true
  ///    - Has no effect if the handler is [LocalOnlyStaleMateHandler] or [RemoteOnlyStaleMateHandler]
  /// - [showLocalDataOnError] : Whether or not the local data should be shown when an error occurs
  ///   - Defaults to true
  ///   - Has no effect if the handler is [LocalOnlyStaleMateHandler] or [RemoteOnlyStaleMateHandler]
  /// - [refreshConfig] : The refresh config that will be used to automatically refresh the data
  ///     - If this is not provided, the data will not be refreshed automatically
  ///     - Manual refresh is always supported by calling [refresh]
  /// - [logLevel] : Log level that will be used for this data loader
  ///    - Defaults to [StaleMateLogLevel.none]
  StaleMateLoader({
    required HandlerType handler,
    this.updateOnInit = true,
    this.showLocalDataOnError = true,
    StaleMateRefreshConfig? refreshConfig,
    StaleMateLogLevel? logLevel,
  }) : _handler = handler {
    // Initialize the logger
    setLogLevel(logLevel ?? StaleMateRegistry.instance.defaultLogLevel);

    // Initialize the state manager
    _stateManager = StaleMateStateManager(
      logger: _logger,
    );

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
  /// If the data is not available yet, the [StaleMateHandler.emptyValue] will be returned.
  T get value => _subject.valueOrNull ?? _handler.emptyValue;

  /// Whether the data stream is currently empty
  ///
  /// This returns true if the data stream is empty or if the data stream is not available yet.
  bool get isEmpty {
    final emptyValue = _handler.emptyValue;
    if (emptyValue is List) {
      return listEquals(value as List, emptyValue);
    }

    if (emptyValue is Map) {
      return mapEquals(value as Map, emptyValue);
    }

    if (emptyValue is Set) {
      return setEquals(value as Set, emptyValue);
    }

    return value == _handler.emptyValue;
  }

  /// Indicates what the current state of the data loader is
  StaleMateLoaderState get state => _stateManager.state;

  /// Adds a state listener to the data loader
  ///
  /// The state listener will be called whenever the state of the data loader changes
  ///
  /// Arguments:
  /// - [listener] : The listener that will be called when the state changes
  void addStateListener(StateListener listener) {
    _stateManager.addListener(listener);
  }

  /// Removes a state listener from the data loader
  ///
  /// The state listener will no longer be called when the state of the data loader changes
  ///
  /// Arguments:
  /// - [listener] : The listener that will be removed
  void removeStateListener(StateListener listener) {
    _stateManager.removeListener(listener);
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
    _logger.d('Adding data to stream...');
    _logger.d(data);
    _subject.add(data);
    try {
      await _handler.storeLocalData(data);
      _logger.d('Local data stored successfully');
    } catch (error, stackTrace) {
      if (error is NotSupportedException) {
        _logger.d('Local storage not supported, skipping storing local data');
      } else {
        _logger.e('Failed to store local data', error, stackTrace);
      }
    }
  }

  /// Handles errors from loading remote data
  ///
  /// - If [showLocalDataOnError] is true, the error will only be added to the stream if there is no local data available
  /// - If [showLocalDataOnError] is false, the error will always be added to the stream
  void _onRemoteDataError(Object error, StackTrace stackTrace) {
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
  Future<T> _loadLocalData() async {
    _logger.i('Loading local data...');
    final localData = await _handler.getLocalData();

    if (localData == _handler.emptyValue) {
      throw NoLocalDataException('Retrieved local data is empty');
    }

    _subject.add(localData);
    return localData;
  }

  /// Loads remote data and adds it to the stream
  ///
  /// Throws an error if loading remote data fails
  ///
  /// Returns the loaded data
  Future<T> _loadRemoteData() async {
    try {
      _logger.i('Loading remote data...');
      final remoteData = await _handler.getRemoteData();
      _logger.d('Remote data loaded');
      _logger.d(remoteData);
      await addData(remoteData);
      return remoteData;
    } catch (error, stackTrace) {
      if (error is NotSupportedException) {
        _logger.i('Remote data not supported, skipping remote data load');
        _stateManager.setRemoteState(
          StaleMateStatus.idle,
        );
      } else {
        _logger.e('Failed to load remote data', error, stackTrace);

        _onRemoteDataError(error, stackTrace);

        _stateManager.setRemoteState(
          StaleMateStatus.error,
          error: error,
        );
      }

      rethrow;
    }
  }

  /// Initializes the loader
  ///
  /// - Loads local data
  /// - If [updateOnInit] is true or there is no local data available, loads remote data
  Future<void> initialize() async {
    _logger.i('Initializing loader...');
    _stateManager.setLocalState(StaleMateStatus.loading);

    try {
      final localData = await _loadLocalData();

      _stateManager.setLocalState(StaleMateStatus.loaded);

      _logger.d('Local data loaded');
      _logger.d(localData);
    } catch (error, stackTrace) {
      if (error is NotSupportedException) {
        _logger.i('Local storage not supported, skipping local data load');
        _stateManager.setLocalState(
          StaleMateStatus.idle,
        );
      } else {
        _stateManager.setLocalState(
          StaleMateStatus.error,
          error: error,
        );

        _logger.e(
          'Failed to load local data',
          error,
          stackTrace,
        );
      }
    }

    // Load remote data if there is no local data available or updateOnInit is true
    if (updateOnInit || isEmpty) {
      if (isEmpty) {
        _logger
            .i('No local data available after initialization, refreshing data');
      } else {
        _logger.i(
          'Local data available after initialization, but updateOnInit is true, refreshing data',
        );
      }

      _stateManager.setRemoteState(
        StaleMateStatus.loading,
        fetchReason: StaleMateFetchReason.initial,
      );

      // Loads the remote data
      final refreshResult = await _refresher.refresh();

      // Successful load sets the state to loaded with remote data
      if (refreshResult.isSuccess) {
        _stateManager.setRemoteState(
          StaleMateStatus.loaded,
          fetchReason: StaleMateFetchReason.initial,
        );
      }
      // Failed load sets the state to error
      else if (refreshResult.isFailure) {
        _logger.e(
          'Failed to get remote data after initialization',
          refreshResult.error,
          StackTrace.current,
        );

        _stateManager.setRemoteState(
          StaleMateStatus.error,
          fetchReason: StaleMateFetchReason.initial,
          error: refreshResult.error,
        );
      }
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
    // Only allow the refresh to be started if the loader is not already loading data
    // If the loader is fetching more, allow the refresh to be started, the fetch more will be cancelled
    if (state.loading && state.fetchReason != StaleMateFetchReason.fetchMore) {
      _logger.i('Already loading data data, not refreshing');
      return StaleMateRefreshResult.alreadyRefreshing(
        refreshInitiatedAt: DateTime.now(),
        refreshFinishedAt: DateTime.now(),
      );
    }

    _stateManager.setRemoteState(
      StaleMateStatus.loading,
      fetchReason: StaleMateFetchReason.refresh,
    );

    final refreshResult = await _refresher.refresh();
    if (refreshResult.isFailure) {
      _stateManager.setRemoteState(
        StaleMateStatus.error,
        fetchReason: StaleMateFetchReason.refresh,
        error: refreshResult.error,
      );

      _logger.e(
        'Failed to refresh data',
        refreshResult.error,
        StackTrace.current,
      );
    } else {
      _stateManager.setRemoteState(
        StaleMateStatus.loaded,
        fetchReason: StaleMateFetchReason.refresh,
      );
    }
    _logger.d(refreshResult);

    return refreshResult;
  }

  /// Resets the loader
  ///
  /// - Removes local data if supported by handler
  /// - Adds empty value to stream
  Future<void> reset() async {
    _logger.i('Resetting data...');
    try {
      await _handler.removeLocalData();
    } catch (error, stackTrace) {
      if (error is NotSupportedException) {
        _logger.i('Local storage not supported, skipping local data reset');
      } else {
        _logger.e('Failed to reset local data', error, stackTrace);
      }
    }
    _subject.add(_handler.emptyValue);
    _stateManager.reset();
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
        // Use the runtime type of the handler as the tag
        tag: _handler.runtimeType.toString(),
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
    _logger.i('Closing loader');
    _subject.close();
    _refresher.dispose();
    _logger.d('Unregistering from registry');
    StaleMateRegistry.instance.unregister(this);
  }
}
