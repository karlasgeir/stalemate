import 'package:stalemate/stalemate.dart';

/// This is a simple [StaleMateLoader] that uses a [String] as the data type.
///
/// It has fake data flow that simulates a local and remote data source.
/// - The local data is initialized to 'initial local data'.
/// - Every time [getRemoteData] is called, the counter [timesUpdatedFromRemote]
///   is incremented.
/// - If [shouldThrowError] is set to true, [getRemoteData] will throw an error
///   to simulate an error when fetching remote data.
class SimpleStaleMateLoader extends StaleMateLoader<String> {
  String _localData = 'initial local data';
  bool shouldThrowError = false;
  int timesUpdatedFromRemote = 0;

  /// Creates a [SimpleStaleMateLoader] with the given parameters.
  ///
  /// Arguments:
  /// - [logLevel] - The [StaleMateLogLevel] to use, defaults to [StaleMateLogLevel.none].
  /// - [updateOnInit] - Whether to update the data on initialization, defaults to true.
  /// - [showLocalDataOnError] - Whether to show the local data when an error, defaults to true.
  SimpleStaleMateLoader({
    super.logLevel,
    super.updateOnInit,
    super.showLocalDataOnError,
  }) : super(
          // The empty value is used to determine if the data is empty.
          // In this case, the empty value is an empty string, but if the type
          // was a list, it would be an empty list, etc.
          emptyValue: '',
        );

  /// This is the method that is called to get the local data.
  ///
  /// Usually this would be used to call a local database or cache.
  ///
  /// In this case, it just simulates a local data source by returning
  /// the [_localData] property.
  @override
  Future<String> getLocalData() async {
    return _localData;
  }

  /// This is the method that is called to get the remote data.
  ///
  /// Usually this would be used to call an API.
  ///
  /// In this case, it just simulates a remote data source by returning
  /// a string after a 5 second delay.
  ///
  /// If [shouldThrowError] is set to true, it will throw an error to simulate
  /// an error when fetching remote data.
  @override
  Future<String> getRemoteData() async {
    await Future.delayed(const Duration(seconds: 5));
    if (shouldThrowError) {
      throw 'Failed to fetch remote data';
    }
    if (timesUpdatedFromRemote == 0) {
      return 'Remote data after ${++timesUpdatedFromRemote} update';
    }
    return 'Remote data after ${++timesUpdatedFromRemote} updates';
  }

  /// This is the method that is called to store the local data.
  ///
  /// Usually this would be used to store the data in a local database or cache.
  ///
  /// In this case, it just simulates a local data source by setting
  /// the [_localData] property.
  @override
  Future<void> storeLocalData(String data) async {
    _localData = data;
  }

  /// This is the method that is called to remove the local data.
  ///
  /// Usually this would be used to remove the data from a local database or cache.
  ///
  /// In this case, it just simulates a local data source by setting
  /// the [_localData] property to an empty string.
  @override
  Future<void> removeLocalData() async {
    shouldThrowError = false;
    timesUpdatedFromRemote = 0;
    _localData = '';
  }
}
