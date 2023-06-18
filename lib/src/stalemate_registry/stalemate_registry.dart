import 'package:collection/collection.dart';

import '../stalemate_refresher/stalemate_refresh_result.dart';
import '../stalemate_loader/stalemate_loader.dart';

/// A registry for [StaleMateLoader]s.
///
/// The registry is a singleton and can be accessed via [StaleMateRegistry.instance].
/// It provides methods to register, unregister, and perform operations on loaders.
/// It is used internally by StaleMate to manage loaders.
///
/// To use the registry, see the corresponding methods in [StaleMate].
class StaleMateRegistry {
  /// The default log level for all loaders
  StaleMateLogLevel defaultLogLevel = StaleMateLogLevel.none;

  /// Holds all registered loaders
  final List<StaleMateLoader> _loaders = [];

  /// The number of [StaleMateLoader]s in the registry
  int get numberOfLoaders => _loaders.length;

  /// Private constructor for the registry to prevent accidental instantiation
  StaleMateRegistry._();

  /// The singleton instance of the registry
  static final StaleMateRegistry _instance = StaleMateRegistry._();

  /// Getter for the instance of the registry
  static StaleMateRegistry get instance => _instance;

  /// Registers a loader in the registry
  void register(StaleMateLoader loader) {
    if (!_loaders.contains(loader)) {
      _loaders.add(loader);
    }
  }

  /// Unregisters a loader from the registry
  void unregister(StaleMateLoader loader) {
    if (_loaders.contains(loader)) {
      _loaders.remove(loader);
    }
  }

  /// Unregisters all [StaleMateLoader]s from the registry
  void unregisterAll() {
    _loaders.clear();
  }

  /// Returns all registered [StaleMateLoader]s.
  /// Returns an empty list if no loaders are found.
  ///
  /// If you want to:
  /// - Get all loaders of a specific type, use [getLoaders].
  /// - Get the first loader of a specific type, use [getFirstLoader].
  List<StaleMateLoader> getAllLoaders() {
    return _loaders;
  }

  /// Refreshes all registered loaders
  ///
  /// This will loop through all loaders and call their [StaleMateLoader.refresh] method.
  ///
  /// Returns a list of [StaleMateRefreshResult]s for each loader,
  /// indicating whether the loader was refreshed successfully.
  /// Results are returned in the order of when the loaders were registered.
  ///
  /// If you want to:
  /// - Refresh all loaders of a specific type, use [refreshLoaders].
  /// - Refresh the first loader of a specific type, use [refreshFirstLoader].
  /// - Refresh an individual loader, use [StaleMateLoader.refresh].
  ///
  /// See also:
  /// - [StaleMateRefreshResult] for more information about the result of a refresh
  /// - [StaleMateLoader.refresh] for more information about refreshing a loader
  Future<List<StaleMateRefreshResult>> refreshAllLoaders() async {
    final refreshRequests = _loaders.map((loader) => loader.refresh()).toList();
    return Future.wait(refreshRequests);
  }

  /// Resets all loaders registered with StaleMate.
  ///
  /// This will clear all data from the loaders
  /// and call their [StaleMateLoader.removeLocalData] method.
  ///
  /// The loaders will be reset to their empty value.
  ///
  /// If you want to:
  /// - Reset all loaders of a specific type, use [resetLoaders].
  /// - Reset the first loader of a specific type, use [resetFirstLoader].
  /// - Reset an individual loader, use [StaleMateLoader.reset].
  Future<void> resetAllLoaders() {
    final restRequests = _loaders.map((loader) => loader.reset()).toList();
    return Future.wait(restRequests);
  }

  /// Returns all registered loaders of the given type.
  ///
  /// Returns an empty list if no loaders are found.
  ///
  /// If you want to:
  /// - Get all loaders, use [getAllLoaders].
  /// - Get the first loader of a specific type, use [getFirstLoader].
  List<T> getLoaders<T extends StaleMateLoader>() {
    return _loaders.whereType<T>().toList();
  }

  /// Returns the number of registered loaders of the given type.
  ///
  /// If you want to:
  /// - Get the number of all loaders, use [numberOfLoaders].
  /// - Know if there are any loaders of a specific type, use [hasLoader].
  int numberOfLoadersOfType<T extends StaleMateLoader>() {
    return getLoaders<T>().length;
  }

  /// Refreshes all registered loaders of the given type.
  ///
  /// This will loop through the loaders and call their [StaleMateLoader.refresh] method.
  ///
  /// Returns a list of [StaleMateRefreshResult]s for each loader,
  /// indicating whether the loader was refreshed successfully.
  /// Results are returned in the order of when the loaders were registered.
  ///
  /// If you want to:
  /// - Refresh all loaders, use [refreshAllLoaders].
  /// - Refresh the first loader of a specific type, use [refreshFirstLoader].
  /// - Refresh an individual loader, use [StaleMateLoader.refresh].
  ///
  /// See also:
  /// - [StaleMateRefreshResult] for more information about the result of a refresh
  /// - [StaleMateLoader.refresh] for more information about refreshing a loader
  Future<List<StaleMateRefreshResult>>
      refreshLoaders<T extends StaleMateLoader>() async {
    final loaders = getLoaders<T>();
    final refreshRequests = loaders.map((loader) => loader.refresh()).toList();
    return Future.wait(refreshRequests);
  }

  /// Resets all loaders registered of the given type.
  ///
  /// This will clear all data from the loaders
  /// and call their [StaleMateLoader.removeLocalData] method.
  ///
  /// The loaders will be reset to their empty value.
  ///
  /// If you want to:
  /// - Reset all loaders, use [resetAllLoaders].
  /// - Reset the first loader of a specific type, use [resetFirstLoader].
  /// - Reset an individual loader, use [StaleMateLoader.reset].
  Future<void> resetLoaders<T extends StaleMateLoader>() {
    final resetLoadersRequest =
        getLoaders<T>().map((loader) => loader.reset()).toList();
    return Future.wait(resetLoadersRequest);
  }

  /// Returns the first registered loader of the given type.
  /// Returns null if no loaders are found.
  ///
  /// If you want to:
  /// - Get all loaders, use [getAllLoaders].
  /// - Get all loaders of a specific type, use [getLoaders].
  StaleMateLoader? getFirstLoader<T extends StaleMateLoader>() {
    return getLoaders<T>().firstOrNull;
  }

  /// Whether a loader of the given type is registered.
  ///
  /// Returns true if one or more loaders are registered.
  /// Returns false if no loaders are registered.
  ///
  /// If multiple loaders are found, true is returned.
  bool hasLoader<T extends StaleMateLoader>() {
    return getFirstLoader<T>() != null;
  }

  /// Refreshes the first registered loader of the given type.
  ///
  /// This will call the loader's [StaleMateLoader.refresh] method.
  ///
  /// Returns the [StaleMateRefreshResult] for the loader,
  /// indicating whether the loader was refreshed successfully.
  /// Will throw an assertion error if no loader is found,
  /// please use [hasLoader] to check if a loader is registered
  /// before calling this method.
  ///
  /// If you want to:
  /// - Refresh all loaders, use [refreshAllLoaders].
  /// - Refresh all loaders of a specific type, use [refreshLoaders].
  /// - Refresh an individual loader, use [StaleMateLoader.refresh].
  ///
  /// See also:
  /// - [StaleMateRefreshResult] for more information about the result of a refresh
  /// - [StaleMateLoader.refresh] for more information about refreshing a loader
  Future<StaleMateRefreshResult>
      refreshFirstLoader<T extends StaleMateLoader>() async {
    final loader = getFirstLoader<T>();
    assert(loader != null, 'No loader of type $T found in registry');
    return loader!.refresh();
  }

  /// Resets the first registered loader of the given type.
  ///
  /// This will clear all data from the loader
  /// and call the [StaleMateLoader.removeLocalData] method.
  ///
  /// The loader will be reset to its empty value.
  ///
  /// Will throw an assertion error if no loader is found,
  /// please use [hasLoader] to check if a loader is registered
  ///
  /// If you want to:
  /// - Reset all loaders, use [resetAllLoaders].
  /// - Reset all loaders of a specific type, use [resetLoaders].
  /// - Reset an individual loader, use [StaleMateLoader.reset].
  Future<void> resetFirstLoader<T extends StaleMateLoader>() {
    final loader = getFirstLoader<T>();
    assert(loader != null, 'No loader of type $T found in registry');

    return loader!.reset();
  }

  /// Sets the global log level for all registered StaleMate loaders.
  ///
  /// This method affects the logging level in two ways:
  /// 1. It immediately updates the log level of all registered loaders,
  ///    even those that have had their log level individually set via [StaleMateLoader.setLogLevel].
  /// 2. It sets a default log level for any loaders registered in the future,
  ///    unless a specific log level is set for them.
  ///
  /// The default log level is [StaleMateLogLevel.none].
  void setLogLevel(StaleMateLogLevel logLevel) {
    defaultLogLevel = logLevel;
    for (var loader in _loaders) {
      loader.setLogLevel(logLevel);
    }
  }
}
