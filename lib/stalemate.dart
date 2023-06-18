library stalemate;

import 'package:stalemate/src/stalemate_refresher/stalemate_refresh_result.dart';

import 'src/stalemate_loader/stalemate_loader.dart';
import 'src/stalemate_registry/stalemate_registry.dart';

export 'src/stalemate_loader/stalemate_loader.dart';
export 'src/stalemate_refresher/stalemate_refresh_config.dart';
export 'src/stalemate_refresher/stalemate_refresh_result.dart';
export 'src/stalemate_builder/stalemate_builder.dart';
export 'src/stalemate_paginated_loader/stalemate_pagination_config.dart';
export 'src/stalemate_paginated_loader/stale_mate_fetch_more_result.dart';

/// Public API for the StaleMate package.
///
/// This class is used to perform global operations on loders registered with StaleMate.
///
/// There is no need to use this class directly,
/// but depending on the structure of your application it might be useful.
///
/// Example usecases include:
/// - Resetting all loaders when the user logs out of the application
/// - Refreshing all loaders when the user logs in to the application
/// - Getting a value from a loader globally
/// - Changing the log level of all loaders
///
/// Example usage:
/// ```dart
///   import `package:stalemate/stalemate.dart`;
///
///   StaleMate.refreshAllLoaders();
///   StaleMate.resetAllLoaders();
///   StaleMate.getAllLoaders();
///   ...
/// ```
class StaleMate {
  /// The number of [StaleMateLoader]s in the registry
  static int numberOfLoaders() => StaleMateRegistry.instance.numberOfLoaders;

  /// Returns all registered [StaleMateLoader]s.
  /// Returns an empty list if no loaders are found.
  ///
  /// If you want to:
  /// - Get all loaders of a specific type, use [getLoaders].
  /// - Get the first loader of a specific type, use [getFirstLoader].
  static List<StaleMateLoader> getAllLoaders() =>
      StaleMateRegistry.instance.getAllLoaders();

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
  static Future<List<StaleMateRefreshResult>> refreshAllLoaders() =>
      StaleMateRegistry.instance.refreshAllLoaders();

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
  static Future<void> resetAllLoaders() =>
      StaleMateRegistry.instance.resetAllLoaders();

  /// Returns all registered loaders of the given type.
  ///
  /// Returns an empty list if no loaders are found.
  ///
  /// If you want to:
  /// - Get all loaders, use [getAllLoaders].
  /// - Get the first loader of a specific type, use [getFirstLoader].
  static List<StaleMateLoader> getLoaders<T extends StaleMateLoader>() =>
      StaleMateRegistry.instance.getLoaders<T>();

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
  static Future<List<StaleMateRefreshResult>>
      refreshLoaders<T extends StaleMateLoader>() =>
          StaleMateRegistry.instance.refreshLoaders<T>();

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
  static Future<void> resetLoaders<T extends StaleMateLoader>() =>
      StaleMateRegistry.instance.resetLoaders<T>();

  /// Whether a loader of the given type is registered.
  ///
  /// Returns true if one or more loaders are registered.
  /// Returns false if no loaders are registered.
  ///
  /// If multiple loaders are found, true is returned.
  static bool hasLoader<T extends StaleMateLoader>() =>
      StaleMateRegistry.instance.hasLoader<T>();

  /// Returns the first registered loader of the given type.
  /// Returns null if no loaders are found.
  ///
  /// If you want to:
  /// - Get all loaders, use [getAllLoaders].
  /// - Get all loaders of a specific type, use [getLoaders].
  static StaleMateLoader? getFirstLoader<T extends StaleMateLoader>() =>
      StaleMateRegistry.instance.getFirstLoader<T>();

  /// Refreshes the first registered loader of the given type.
  ///
  /// This will call the loader's [StaleMateLoader.refresh] method.
  ///
  /// Returns the [StaleMateRefreshResult] for the loader,
  /// indicating whether the loader was refreshed successfully.
  ///
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
  static Future<StaleMateRefreshResult>
      refreshFirstLoader<T extends StaleMateLoader>() =>
          StaleMateRegistry.instance.refreshFirstLoader<T>();

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
  static Future<void> resetFirstLoader<T extends StaleMateLoader>() =>
      StaleMateRegistry.instance.resetFirstLoader<T>();

  /// Sets the global log level for all registered StaleMate loaders.
  ///
  /// This method affects the logging level in two ways:
  /// 1. It immediately updates the log level of all registered loaders,
  ///    even those that have had their log level individually set via [StaleMateLoader.setLogLevel].
  /// 2. It sets a default log level for any loaders registered in the future,
  ///    unless a specific log level is set for them.
  ///
  /// The default log level is [StaleMateLogLevel.none].
  static void setLogLevel(StaleMateLogLevel logLevel) {
    StaleMateRegistry.instance.setLogLevel(logLevel);
  }
}
