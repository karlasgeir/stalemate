import 'package:flutter_test/flutter_test.dart';

import 'package:stalemate/stalemate.dart';

class StringLoader extends StaleMateLoader<String?> {
  String? _localData;
  bool shouldThrowLocalError = false;
  bool shouldThrowRemoteError = false;
  bool shouldThrowWhileStoring = false;
  bool shouldThrowWhileRemoving = false;
  int timesUpdatedFromRemote = 0;

  StringLoader({
    String? initialLocalData = 'initial local data',
    bool updateOnInit = true,
  })  : _localData = initialLocalData,
        super(
          emptyValue: null,
          updateOnInit: updateOnInit,
        );

  @override
  Future<String?> getLocalData() async {
    if (shouldThrowLocalError) {
      throw Exception('Failed to fetch local data');
    }
    return _localData;
  }

  @override
  Future<String?> getRemoteData() async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldThrowRemoteError) {
      throw Exception('Failed to fetch remote data');
    }
    return 'remote data ${++timesUpdatedFromRemote}';
  }

  @override
  Future<void> storeLocalData(String? data) async {
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
    _localData = null;
  }
}

void main() {
  group('StringLoader', () {
    late StringLoader stringLoader;

    setUp(() {
      stringLoader = StringLoader();
    });

    test('value should be initial local data right after initialization',
        () async {
      stringLoader.initialize();
      await Future.delayed(const Duration(milliseconds: 5));
      expect(stringLoader.value, equals('initial local data'));
    });

    test(
        'value should be remote data after initialization is complete if updateOnInit is true',
        () async {
      await stringLoader.initialize();
      expect(stringLoader.value, equals('remote data 1'));
    });

    test(
        'value should be remote data after initialization is complete if local data is null',
        () async {
      stringLoader = StringLoader(initialLocalData: null);
      await stringLoader.initialize();
      expect(stringLoader.value, equals('remote data 1'));
    });

    test(
        'value should be remote data after initialization is complete if local data is null and updateOnInit is false',
        () async {
      stringLoader = StringLoader(
        initialLocalData: null,
        updateOnInit: false,
      );
      await stringLoader.initialize();
      expect(stringLoader.value, equals('remote data 1'));
    });

    test(
        'value should be local data after initialization is complete if updateOnInit is false',
        () async {
      stringLoader = StringLoader(updateOnInit: false);
      await stringLoader.initialize();
      expect(stringLoader.value, equals('initial local data'));
    });

    test('value should be remote data after refresh', () async {
      await stringLoader.initialize();
      await stringLoader.refresh();
      expect(stringLoader.value, equals('remote data 2'));
    });

    test('value should get new remote data after refresh', () async {
      await stringLoader.initialize();
      expect(stringLoader.value, equals('remote data 1'));
      await stringLoader.refresh();
      expect(stringLoader.value, equals('remote data 2'));
      await Future.delayed(const Duration(milliseconds: 5));
      await stringLoader.refresh();
      expect(stringLoader.value, equals('remote data 3'));
    });

    test('value should be null after clear', () async {
      await stringLoader.initialize();
      await stringLoader.reset();
      expect(stringLoader.value, equals(null));
    });

    test('local data should be remote data after refresh', () async {
      await stringLoader.initialize();
      await stringLoader.refresh();
      final localData = await stringLoader.getLocalData();
      expect(localData, equals('remote data 2'));
    });

    test('local data should be null after clear', () async {
      await stringLoader.initialize();
      await stringLoader.reset();
      final localData = await stringLoader.getLocalData();
      expect(localData, equals(null));
    });

    test('value should be local data after error', () async {
      stringLoader.shouldThrowRemoteError = true;
      await stringLoader.initialize();
      expect(stringLoader.value, equals('initial local data'));
    });

    test('value should be local data after error and refresh', () async {
      stringLoader.shouldThrowRemoteError = true;
      await stringLoader.initialize();
      await stringLoader.refresh();
      expect(stringLoader.value, equals('initial local data'));
    });

    test('value should be remote data after error and refresh', () async {
      await stringLoader.initialize();
      stringLoader.shouldThrowRemoteError = true;
      await stringLoader.refresh();
      expect(stringLoader.value, equals('remote data 1'));
    });
  });

  group('Stalemate loader state', () {
    test('state should be idle after creation', () async {
      final stringLoader = StringLoader();
      expect(stringLoader.state.localStatus, equals(StaleMateStatus.idle));
      expect(stringLoader.state.remoteStatus, equals(StaleMateStatus.idle));
    });

    test('state progress during initialization', () async {
      final stringLoader = StringLoader();
      stringLoader.initialize();
      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.loading),
      );
      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.idle),
      );
      await Future.delayed(const Duration(milliseconds: 5));

      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.loaded),
      );

      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loading),
      );

      expect(
        stringLoader.state.requireFetchReason,
        equals(StaleMateFetchReason.initial),
      );

      await Future.delayed(const Duration(milliseconds: 15));

      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loaded),
      );
      expect(
        stringLoader.state.requireFetchReason,
        equals(StaleMateFetchReason.initial),
      );
    });

    test('state progress during refresh', () async {
      final stringLoader = StringLoader();
      await stringLoader.initialize();
      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loaded),
      );
      expect(
        stringLoader.state.requireFetchReason,
        equals(StaleMateFetchReason.initial),
      );

      stringLoader.refresh();
      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loading),
      );
      expect(
        stringLoader.state.requireFetchReason,
        equals(StaleMateFetchReason.refresh),
      );

      await Future.delayed(const Duration(milliseconds: 15));

      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loaded),
      );
      expect(
        stringLoader.state.requireFetchReason,
        equals(StaleMateFetchReason.refresh),
      );
    });

    test('state progress during reset', () async {
      final stringLoader = StringLoader();
      await stringLoader.initialize();
      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.loaded),
      );
      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loaded),
      );
      expect(
        stringLoader.state.requireFetchReason,
        equals(StaleMateFetchReason.initial),
      );

      await stringLoader.reset();

      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.idle),
      );
      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.idle),
      );
    });

    test('state progress during local initial loading error', () async {
      final stringLoader = StringLoader();
      stringLoader.shouldThrowLocalError = true;
      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.idle),
      );

      stringLoader.initialize();

      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.loading),
      );

      await Future.delayed(const Duration(milliseconds: 5));

      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.error),
      );

      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loading),
      );

      await Future.delayed(const Duration(milliseconds: 15));

      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loaded),
      );
    });

    test('state progress during initial remote', () async {
      final stringLoader = StringLoader();
      stringLoader.shouldThrowRemoteError = true;
      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.idle),
      );

      stringLoader.initialize();

      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.loading),
      );

      await Future.delayed(const Duration(milliseconds: 5));

      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.loaded),
      );

      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loading),
      );

      await Future.delayed(const Duration(milliseconds: 15));

      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.error),
      );
    });

    test(
        'state progress during initialization with error in both local and remote',
        () async {
      final stringLoader = StringLoader();
      stringLoader.shouldThrowRemoteError = true;
      stringLoader.shouldThrowLocalError = true;

      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.idle),
      );

      stringLoader.initialize();

      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.loading),
      );

      await Future.delayed(const Duration(milliseconds: 5));

      expect(
        stringLoader.state.localStatus,
        equals(StaleMateStatus.error),
      );

      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loading),
      );

      await Future.delayed(const Duration(milliseconds: 15));

      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.error),
      );
    });

    test('state progress during refresh error', () async {
      final stringLoader = StringLoader();
      await stringLoader.initialize();
      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loaded),
      );
      expect(
        stringLoader.state.requireFetchReason,
        equals(StaleMateFetchReason.initial),
      );

      stringLoader.shouldThrowRemoteError = true;
      stringLoader.refresh();
      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loading),
      );
      expect(
        stringLoader.state.requireFetchReason,
        equals(StaleMateFetchReason.refresh),
      );

      await Future.delayed(const Duration(milliseconds: 15));

      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.error),
      );
      expect(
        stringLoader.state.requireFetchReason,
        equals(StaleMateFetchReason.refresh),
      );
    });
  });

  group('state listeners', () {
    test('test add state listener', () async {
      final stringLoader = StringLoader();
      final List<StaleMateLoaderState> states = [];
      final List<StaleMateLoaderState> prevStates = [];
      listener(newState, prevState) {
        states.add(newState);
        prevStates.add(prevState);
      }

      stringLoader.addStateListener(listener);
      await stringLoader.initialize();

      // During initialize, the state listener is called 4 times
      // 1. Initial state to loading local
      // 2. Local loading to local loaded
      // 3. Local loaded to loading remote as well
      // 4. Remote loaded

      expect(states.length, equals(4));
      expect(states[0].localStatus, equals(StaleMateStatus.loading));
      expect(states[1].localStatus, equals(StaleMateStatus.loaded));
      expect(states[2].remoteStatus, equals(StaleMateStatus.loading));
      expect(states[3].remoteStatus, equals(StaleMateStatus.loaded));

      expect(prevStates.length, equals(4));
      expect(prevStates[0].localStatus, equals(StaleMateStatus.idle));
      expect(prevStates[1].localStatus, equals(StaleMateStatus.loading));
      expect(prevStates[2].localStatus, equals(StaleMateStatus.loaded));
      expect(prevStates[3].remoteStatus, equals(StaleMateStatus.loading));
    });

    test('test remove state listener', () async {
      final stringLoader = StringLoader();
      final List<StaleMateLoaderState> states = [];
      listener(newState, prevState) => states.add(newState);

      stringLoader.addStateListener(listener);
      await stringLoader.initialize();

      expect(states.length, equals(4));
      expect(states[0].localStatus, equals(StaleMateStatus.loading));
      expect(states[1].localStatus, equals(StaleMateStatus.loaded));
      expect(states[2].remoteStatus, equals(StaleMateStatus.loading));
      expect(states[3].remoteStatus, equals(StaleMateStatus.loaded));

      stringLoader.removeStateListener(listener);
      await stringLoader.refresh();

      expect(states.length, equals(4));
      expect(states[0].localStatus, equals(StaleMateStatus.loading));
      expect(states[1].localStatus, equals(StaleMateStatus.loaded));
      expect(states[2].remoteStatus, equals(StaleMateStatus.loading));
      expect(states[3].remoteStatus, equals(StaleMateStatus.loaded));
    });
  });
}
