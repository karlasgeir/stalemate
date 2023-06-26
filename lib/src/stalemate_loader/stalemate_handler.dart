import '../exceptions/not_supported_exception.dart';
import '../stalemate_loader/stalemate_loader.dart';

/// A handler to retrieve and store data for [StaleMateLoader]s
///
/// This class is abstract and should be extended to implement the data retrieval
/// and storage for a [StaleMateLoader]
///
/// This class is intended to be used for data that is stored locally and remotely
/// Other usecases:
/// - [LocalOnlyStaleMateHandler] for data that is only stored locally
/// - [RemoteOnlyStaleMateHandler] for data that is only stored remotely
///
/// Implementation instructions:
/// - Override the [emptyValue] getter to provide the empty value for the data type
/// - Override the [getLocalData] method to provide the local data retrieval
/// - Override the [getRemoteData] method to provide the remote data retrieval
/// - Override the [storeLocalData] method to provide the local data storage
/// - Override the [removeLocalData] method to provide the local data removal
///
/// To add pagination support, use the [PaginatedHandlerMixin] mixin
///
/// Example:
/// ```dart
/// class MyStaleMateHandler extends StaleMateHandler<List<MyData>> {
///   @override
///   List<MyData> get emptyValue => [];
///
///   @override
///   Future<List<MyData>> getLocalData() async {
///     // Load the data from the local data source
///     return _localDataSource.getData();
///   }
///
///   @override
///   Future<List<MyData>> getRemoteData() async {
///     // Load the data from the remote data source
///     return _remoteDataSource.getData();
///   }
///
///   @override
///   Future<void> storeLocalData(List<MyData> data) async {
///     // Store the data in the local data source
///     await _localDataSource.storeData(data);
///   }
///
///   @override
///   Future<void> removeLocalData() async {
///     // Remove the data from the local data source
///     await _localDataSource.removeData();
///   }
///
/// }
/// ```
abstract class StaleMateHandler<T> {
  /// The empty value for this handler
  ///
  /// This is used to determine when the data is empty
  /// Usually an empty represenation of the data type
  ///
  /// Due to the nature of Dart, this cannot be provided properly by the library
  /// It would be possible to provide a default value for some types, but not types
  /// with custom classes or enums.
  ///
  /// In most cases I suspect this library will be used with custom classes or enums
  /// and providing a default value for a subset of types could be confusing.
  ///
  /// Examples:
  /// - `''` for [String]
  /// - `null` for any nullable type
  /// - `-1` for [int]
  /// - `-1.0` for [double]
  /// - `[]` for [List]
  /// - `{}` for [Map]
  /// - `State.initial`for a custom State enum
  T get emptyValue;

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
  Future<T> getLocalData();

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
  Future<T> getRemoteData();

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
  Future<void> storeLocalData(T data);

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
  Future<void> removeLocalData();
}

/// A handler to retrieve and store local for [StaleMateLoader]s
///
/// This class is abstract and should be extended to implement the local data retrieval
/// and storage for a [StaleMateLoader]
///
/// This class is intended to be used for data that is only stored locally
/// - [StaleMateHandler] for data that is stored locally and remotely
/// - [RemoteOnlyStaleMateHandler] for data that is only stored remotely
///
/// Implementation instructions:
/// - Override the [emptyValue] getter to provide the empty value for the data type
/// - Override the [getLocalData] method to provide the local data retrieval
/// - Override the [storeLocalData] method to provide the local data storage
/// - Override the [removeLocalData] method to provide the local data removal
///
/// Example:
/// ```dart
/// class MyStaleMateHandler extends StaleMateHandler<List<MyData>> {
///   @override
///   List<MyData> get emptyValue => [];
///
///   @override
///   Future<List<MyData>> getLocalData() async {
///     // Load the data from the local data source
///     return _localDataSource.getData();
///   }
///
///
///   @override
///   Future<void> storeLocalData(List<MyData> data) async {
///     // Store the data in the local data source
///     await _localDataSource.storeData(data);
///   }
///
///   @override
///   Future<void> removeLocalData() async {
///     // Remove the data from the local data source
///     await _localDataSource.removeData();
///   }
///
/// }
/// ```
abstract class LocalOnlyStaleMateHandler<T> extends StaleMateHandler<T> {
  @override
  Future<T> getRemoteData() {
    throw NotSupportedException(
      'Remote data is not supported in LocalOnlyStaleMateHandler',
    );
  }

  @override
  Future<T> getLocalData();

  @override
  Future<void> storeLocalData(T data);

  @override
  Future<void> removeLocalData();
}

/// A handler to retrieve and store remote data for [StaleMateLoader]s
///
/// This class is abstract and should be extended to implement the data retrieval
/// and storage for a [StaleMateLoader]
///
/// This class is intended to be used for data that is only stored remotely
/// Other usecases:
/// - [StaleMateHandler] for data that is stored locally and remotely
/// - [LocalOnlyStaleMateHandler] for data that is only stored locally
///
/// Implementation instructions:
/// - Override the [emptyValue] getter to provide the empty value for the data type
/// - Override the [getRemoteData] method to provide the remote data retrieval
///
/// To add pagination support, use the [PaginatedHandlerMixin] mixin
///
/// Example:
/// ```dart
/// class MyStaleMateHandler extends StaleMateHandler<List<MyData>> {
///   @override
///   List<MyData> get emptyValue => [];
///
///   @override
///   Future<List<MyData>> getLocalData() async {
///     // Load the data from the local data source
///     return _localDataSource.getData();
///   }
///
///   @override
///   Future<List<MyData>> getRemoteData() async {
///     // Load the data from the remote data source
///     return _remoteDataSource.getData();
///   }
///
///   @override
///   Future<void> storeLocalData(List<MyData> data) async {
///     // Store the data in the local data source
///     await _localDataSource.storeData(data);
///   }
///
///   @override
///   Future<void> removeLocalData() async {
///     // Remove the data from the local data source
///     await _localDataSource.removeData();
///   }
///
/// }
/// ```
abstract class RemoteOnlyStaleMateHandler<T> extends StaleMateHandler<T> {
  @override
  Future<T> getRemoteData();

  @override
  Future<T> getLocalData() {
    throw NotSupportedException(
      'Local data is not supported in RemoteOnlyStaleMateHandler',
    );
  }

  @override
  Future<void> storeLocalData(T data) {
    throw NotSupportedException(
      'Local data is not supported in RemoteOnlyStaleMateHandler',
    );
  }

  @override
  Future<void> removeLocalData() {
    throw NotSupportedException(
      'Local data is not supported in RemoteOnlyStaleMateHandler',
    );
  }
}
