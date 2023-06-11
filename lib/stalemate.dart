library stalemate;

import 'package:stalemate/src/stalemate_refresher/stalemate_refresh_result.dart';

import 'src/stalemate_loader/stalemate_loader.dart';
import 'src/stalemate_registry/stalemate_registry.dart';

export 'src/stalemate_loader/stalemate_loader.dart';
export 'src/stalemate_refresher/stalemate_refresh_config.dart';
export 'src/stalemate_builder/stalemate_builder.dart';

/// Public API for StaleMate.
/// This class is used to perform operations on all loaders or loaders of a specific type
/// There is no need to use this class directly, but depending on the structure of your application it might be useful.
/// If you keep control of the loaders yourself and choose to manually reset them or perform operations on their instances directly
/// you don't need to use this class.
/// If you want to reset all loaders at once, refresh all loaders at once, or get a loader of a specific type, this class can be useful.
/// An example use case for this could be to reset all loaders when the user logs out of the application.
class StaleMate {
  /// The number of loaders registered with StaleMate.
  static int numberOfLoaders() => StaleMateRegistry.instance.numberOfLoaders;

  /// Returns all loaders registered with StaleMate.
  static List<StaleMateLoader> getAllLoaders() =>
      StaleMateRegistry.instance.getAllLoaders();

  /// Refreshes all loaders registered with StaleMate.
  /// Returns a list of [StaleMateRefreshResult]s for each loader, indicating whether the loader was refreshed successfully.
  /// Even though the loaders are refreshed in parallel, the results are returned in the order of the loaders.
  /// Even though the [StaleMateRefreshResult] contains the refreshed data, there is no need to use it unless you want to.
  /// The refreshed data will be available automatically through the [StaleMateLoader.stream] stream.
  /// The errors for each loader will be addded to the [StaleMateLoader.stream] stream, depending on the [StaleMateLoader.showLocalDataOnError] parameter
  /// If you want to refresh all loaders of a specific type, use [refreshLoaders].
  /// If you want to refresh the first loader of a specific type, use [refreshFirstLoader].
  static Future<List<StaleMateRefreshResult>> refreshAllLoaders() =>
      StaleMateRegistry.instance.refreshAllLoaders();

  /// Resets all loaders registered with StaleMate.
  /// This will clear all data from the loaders and call their [StaleMateLoader.removeLocalData] method.
  /// The loaders will be reset to their empty value.
  static Future<void> resetAllLoaders() =>
      StaleMateRegistry.instance.resetAllLoaders();

  /// Returns all loaders of the given type registered with StaleMate.
  /// Returns an empty list if no loaders are found.
  /// If you only want the first loader, use [getFirstLoader].
  static List<StaleMateLoader> getLoaders<T extends StaleMateLoader>() =>
      StaleMateRegistry.instance.getLoaders<T>();

  /// Refreshes all loaders of the given type registered with StaleMate.
  /// Returns a list of [StaleMateRefreshResult]s for each loader, indicating whether the loader was refreshed successfully.
  /// Even though the loaders are refreshed in parallel, the results are returned in the order of the loaders.
  /// Even though the [StaleMateRefreshResult] contains the refreshed data, there is no need to use it unless you want to.
  /// The refreshed data will be available automatically through the [StaleMateLoader.stream] stream.
  /// The errors for each loader will be addded to the [StaleMateLoader.stream] stream, depending on the [StaleMateLoader.showLocalDataOnError] parameter
  /// If you only want to refresh the first loader, use [refreshFirstLoader].
  static Future<List<StaleMateRefreshResult>>
      refreshLoaders<T extends StaleMateLoader>() =>
          StaleMateRegistry.instance.refreshLoaders<T>();

  /// Resets all loaders of the given type registered with StaleMate.
  /// This will clear all data from the loaders and call their [StaleMateLoader.removeLocalData] method.
  /// The loaders will be reset to their empty value.
  /// If you only want to reset the first loader, use [resetFirstLoader].
  static Future<void> resetLoaders<T extends StaleMateLoader>() =>
      StaleMateRegistry.instance.resetLoaders<T>();

  /// Whether a [StaleMateLoader] for the given type exists in the registry.
  /// Returns true if a loader is found.
  /// Returns false if no loader is found.
  /// If multiple loaders are found, true is returned.
  static bool hasLoader<T extends StaleMateLoader>() =>
      StaleMateRegistry.instance.hasLoader<T>();

  /// Gets a [StaleMateLoader] from the registry.
  /// Returns null if no loader is found.
  /// If multiple loaders are found, the first one is returned.
  static StaleMateLoader? getFirstLoader<T extends StaleMateLoader>() =>
      StaleMateRegistry.instance.getFirstLoader<T>();

  /// Refreshes a [StaleMateLoader] from the registry.
  /// Returns a [StaleMateRefreshResult] indicating whether the loader was refreshed successfully.
  /// Even though the [StaleMateRefreshResult] contains the refreshed data, there is no need to use it unless you want to.
  /// The refreshed data will be available automatically through the [StaleMateLoader.stream] stream.
  /// The error will be addded to the [StaleMateLoader.stream] stream, depending on the [StaleMateLoader.showLocalDataOnError] parameter
  /// Throws an assertion error if no loader is found. Use [hasLoader] to check if a loader exists.
  /// If you want to refresh all loaders, use [refreshAllLoaders].
  /// If you want to refresh all loaders of a specific type, use [refreshLoaders].
  /// If you want to refresh a specific loader, use [StaleMateLoader.refresh] on the loader instance.
  static Future<StaleMateRefreshResult>
      refreshFirstLoader<T extends StaleMateLoader>() =>
          StaleMateRegistry.instance.refreshFirstLoader<T>();

  /// Resets a [StaleMateLoader] from the registry.
  /// This will clear all data from the loader and call its [StaleMateLoader.removeLocalData] method.
  /// The loader will be reset to its empty value.
  /// Returns false if no loader is found.
  /// If multiple loaders are found, the first one is reset.
  /// If you want to reset all loaders, use [resetAllLoaders].
  /// If you want to reset all loaders of a specific type, use [resetLoaders].
  /// If you want to reset a specific loader, use [StaleMateLoader.reset] on the loader instance.
  static Future<void> resetFirstLoader<T extends StaleMateLoader>() =>
      StaleMateRegistry.instance.resetFirstLoader<T>();
}
