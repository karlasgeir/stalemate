import 'package:stalemate/stalemate.dart';

/// Just a simple [StaleMateLoader] that uses a [String] as the data type.
/// It has a local data that is initialized to 'initial local data' and
/// a remote data that incriments the counter depending on how often
/// [getRemoteData] is called.
/// It has a [shouldThrowError] property that can be set to true to
/// simulate an error when fetching remote data.
class SimpleStaleMateLoader extends StaleMateLoader<String> {
  String _localData = 'initial local data';
  bool shouldThrowError = false;
  int timesUpdatedFromRemote = 0;

  SimpleStaleMateLoader({
    super.logLevel,
    super.updateOnInit,
    super.showLocalDataOnError,
  }) : super(
          emptyValue: '',
        );

  @override
  Future<String> getLocalData() async {
    return _localData;
  }

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

  @override
  Future<void> storeLocalData(String data) async {
    _localData = data;
  }

  @override
  Future<void> removeLocalData() async {
    shouldThrowError = false;
    timesUpdatedFromRemote = 0;
    _localData = '';
  }
}
