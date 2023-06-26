import 'package:stalemate/stalemate.dart';

class MockStringHandler extends StaleMateHandler<String> {
  String _localData = 'initial local data';

  bool shouldThrowLocalError = false;
  bool shouldThrowRemoteError = false;
  bool shouldThrowWhileStoring = false;
  bool shouldThrowWhileRemoving = false;
  int timesUpdatedFromRemote = 0;

  @override
  String get emptyValue => '';

  @override
  Future<String> getLocalData() async {
    if (shouldThrowLocalError) {
      throw Exception('Failed to fetch local data');
    }
    return _localData;
  }

  @override
  Future<String> getRemoteData() async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldThrowRemoteError) {
      throw Exception('Failed to fetch remote data');
    }
    return 'remote data ${++timesUpdatedFromRemote}';
  }

  @override
  Future<void> storeLocalData(String data) async {
    if (shouldThrowWhileStoring) {
      throw Exception('Failed to store local data');
    }
    _localData = data;
  }

  @override
  Future<void> removeLocalData() async {
    if (shouldThrowWhileRemoving) {
      throw Exception('Failed to remove local data');
    }
    timesUpdatedFromRemote = 0;
    _localData = '';
  }
}

class StringLoader extends StaleMateLoader<String, MockStringHandler> {
  final MockStringHandler handler;

  clearLocalData() {
    handler._localData = '';
  }

  setShouldThrowLocalError(bool shouldThrow) {
    handler.shouldThrowLocalError = shouldThrow;
  }

  setShouldThrowRemoteError(bool shouldThrow) {
    handler.shouldThrowRemoteError = shouldThrow;
  }

  setShouldThrowWhileStoring(bool shouldThrow) {
    handler.shouldThrowWhileStoring = shouldThrow;
  }

  setShouldThrowWhileRemoving(bool shouldThrow) {
    handler.shouldThrowWhileRemoving = shouldThrow;
  }

  StringLoader({
    required this.handler,
    bool updateOnInit = true,
  }) : super(
          handler: handler,
          updateOnInit: updateOnInit,
        );
}
