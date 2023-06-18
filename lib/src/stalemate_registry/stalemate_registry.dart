import 'package:collection/collection.dart';
import 'package:stalemate/src/stalemate_refresher/stalemate_refresh_result.dart';

import '../stalemate_loader/stalemate_loader.dart';

/// A registry for [StaleMateLoader]s.
/// This registry should not be used directly, but rather through the repository using the [StaleMateLoader]s.
/// This registry is used to hold an instance of all [StaleMateLoader]s to be able to clear them all once the user logs out.
class StaleMateRegistry {
  StaleMateLogLevel defaultLogLevel = StaleMateLogLevel.none;

  /// The list of [StaleMateLoader]s
  final List<StaleMateLoader> _loaders = [];

  /// The number of [StaleMateLoader]s in the registry
  int get numberOfLoaders => _loaders.length;

  /// Private constructor for the registry to prevent accidental instantiation
  StaleMateRegistry._();

  /// The singleton instance of the registry
  static final StaleMateRegistry _instance = StaleMateRegistry._();

  /// Getter for the instance of the registry
  static StaleMateRegistry get instance => _instance;

  /// Registers a [StaleMateLoader] in the registry
  void register(StaleMateLoader loader) {
    if (!_loaders.contains(loader)) {
      _loaders.add(loader);
    }
  }

  /// Unregisters a [StaleMateLoader] from the registry
  void unregister(StaleMateLoader loader) {
    if (_loaders.contains(loader)) {
      _loaders.remove(loader);
    }
  }

  /// Unregisters all [StaleMateLoader]s from the registry
  void unregisterAll() {
    _loaders.clear();
  }

  /// Gets all [StaleMateLoader]s from the registry
  List<StaleMateLoader> getAllLoaders() {
    return _loaders;
  }

  /// Refreshes all [StaleMateLoader]s in the registry
  /// Returns whether all loaders were refreshed successfully
  /// The errors for each loader will be addded to the [StaleMateLoader.stream] stream
  Future<List<StaleMateRefreshResult>> refreshAllLoaders() async {
    final refreshRequests = _loaders.map((loader) => loader.refresh()).toList();
    return Future.wait(refreshRequests);
  }

  /// Resets all [StaleMateLoader]s in the registry
  /// This will clear the local data of each loader and
  /// reset the data to its empty value
  Future<void> resetAllLoaders() {
    final restRequests = _loaders.map((loader) => loader.reset()).toList();
    return Future.wait(restRequests);
  }

  /// Gets all [StaleMateLoader]s of type [T] from the registry
  List<T> getLoaders<T extends StaleMateLoader>() {
    return _loaders.whereType<T>().toList();
  }

  int numberOfLoadersOfType<T extends StaleMateLoader>() {
    return getLoaders<T>().length;
  }

  /// Refreshes all [StaleMateLoader]s of type [T] in the registry
  Future<List<StaleMateRefreshResult>>
      refreshLoaders<T extends StaleMateLoader>() async {
    final loaders = getLoaders<T>();
    final refreshRequests = loaders.map((loader) => loader.refresh()).toList();
    return Future.wait(refreshRequests);
  }

  /// Resets all [StaleMateLoader]s of type [T] in the registry
  /// This will clear the local data of each loader and
  /// reset the data to its empty value
  Future<void> resetLoaders<T extends StaleMateLoader>() {
    final resetLoadersRequest =
        getLoaders<T>().map((loader) => loader.reset()).toList();
    return Future.wait(resetLoadersRequest);
  }

  /// Gets the first [StaleMateLoader] of type [T] from the registry
  StaleMateLoader? getFirstLoader<T extends StaleMateLoader>() {
    return getLoaders<T>().firstOrNull;
  }

  /// Whether a [StaleMateLoader] of type [T] exists in the registry
  bool hasLoader<T extends StaleMateLoader>() {
    return getFirstLoader<T>() != null;
  }

  Future<StaleMateRefreshResult>
      refreshFirstLoader<T extends StaleMateLoader>() async {
    final loader = getFirstLoader<T>();
    assert(loader != null, 'No loader of type $T found in registry');
    return loader!.refresh();
  }

  /// Resets the first [StaleMateLoader] of type [T] in the registry
  /// This will clear the local data of the loader and
  /// reset the data to its empty value
  Future<void> resetFirstLoader<T extends StaleMateLoader>() {
    final loader = getFirstLoader<T>();
    assert(loader != null, 'No loader of type $T found in registry');

    return loader!.reset();
  }

  /// Sets the global log level for all StaleMate loaders in the registry.
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
