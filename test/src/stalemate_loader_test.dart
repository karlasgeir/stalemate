import 'package:flutter_test/flutter_test.dart';

import 'package:stalemate/stalemate.dart';

import '../mocks/mock_empty_value_handlers.dart';
import '../mocks/mock_string_loader.dart';

void main() {
  group('StringLoader', () {
    late StringLoader stringLoader;

    setUp(() {
      stringLoader = StringLoader(
        handler: MockStringHandler(),
      );
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
      stringLoader = StringLoader(
        handler: MockStringHandler(),
      );
      stringLoader.clearLocalData();

      await stringLoader.initialize();

      expect(stringLoader.value, equals('remote data 1'));
    });

    test(
        'value should be remote data after initialization is complete if local data is null and updateOnInit is false',
        () async {
      stringLoader = StringLoader(
        updateOnInit: false,
        handler: MockStringHandler(),
      );

      stringLoader.clearLocalData();
      await stringLoader.initialize();
      expect(stringLoader.value, equals('remote data 1'));
    });

    test(
        'value should be local data after initialization is complete if updateOnInit is false',
        () async {
      stringLoader = StringLoader(
        updateOnInit: false,
        handler: MockStringHandler(),
      );
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

    test('value should be empty after clear', () async {
      await stringLoader.initialize();
      await stringLoader.reset();
      expect(stringLoader.value, equals(''));
    });

    test('local data should be remote data after refresh', () async {
      await stringLoader.initialize();
      await stringLoader.refresh();
      final localData = await stringLoader.handler.getLocalData();
      expect(localData, equals('remote data 2'));
    });

    test('local data should be empty after clear', () async {
      await stringLoader.initialize();
      await stringLoader.reset();
      final localData = await stringLoader.handler.getLocalData();
      expect(localData, equals(''));
    });

    test('value should be local data after error', () async {
      stringLoader.setShouldThrowRemoteError(true);
      await stringLoader.initialize();
      expect(stringLoader.value, equals('initial local data'));
    });

    test('value should be local data after error and refresh', () async {
      stringLoader.setShouldThrowRemoteError(true);
      await stringLoader.initialize();
      await stringLoader.refresh();
      expect(stringLoader.value, equals('initial local data'));
    });

    test('value should be remote data after error and refresh', () async {
      await stringLoader.initialize();
      stringLoader.setShouldThrowRemoteError(true);
      await stringLoader.refresh();
      expect(stringLoader.value, equals('remote data 1'));
    });
  });

  group('Stalemate loader state', () {
    late StringLoader stringLoader;

    setUp(() {
      stringLoader = StringLoader(
        handler: MockStringHandler(),
      );
    });

    test('state should be idle after creation', () async {
      expect(stringLoader.state.localStatus, equals(StaleMateStatus.idle));
      expect(stringLoader.state.remoteStatus, equals(StaleMateStatus.idle));
    });

    test('state progress during initialization', () async {
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
      stringLoader.setShouldThrowLocalError(true);
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
      stringLoader.setShouldThrowRemoteError(true);
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
      stringLoader.setShouldThrowLocalError(true);
      stringLoader.setShouldThrowRemoteError(true);

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
      await stringLoader.initialize();
      expect(
        stringLoader.state.remoteStatus,
        equals(StaleMateStatus.loaded),
      );
      expect(
        stringLoader.state.requireFetchReason,
        equals(StaleMateFetchReason.initial),
      );

      stringLoader.setShouldThrowRemoteError(true);
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
    late StringLoader stringLoader;

    setUp(() {
      stringLoader = StringLoader(
        handler: MockStringHandler(),
      );
    });

    test('test add state listener', () async {
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

  group('Test empty values', () {
    test('test string emty value', () async {
      final loader = StaleMateLoader(handler: StringEmptyValueHandler());
      expect(loader.isEmpty, true);

      await loader.initialize();
      expect(loader.isEmpty, false);

      await loader.reset();
      expect(loader.isEmpty, true);
    });

    test('test int empty value', () async {
      final loader = StaleMateLoader(handler: IntEmptyValueHandler());
      expect(loader.isEmpty, true);

      await loader.initialize();
      expect(loader.isEmpty, false);

      await loader.reset();
      expect(loader.isEmpty, true);
    });

    test('test double empty value', () async {
      final loader = StaleMateLoader(handler: DoubleEmptyValueHandler());
      expect(loader.isEmpty, true);

      await loader.initialize();
      expect(loader.isEmpty, false);

      await loader.reset();
      expect(loader.isEmpty, true);
    });

    test('test bool empty value', () async {
      final loader = StaleMateLoader(handler: BoolEmptyValueHandler());
      expect(loader.isEmpty, true);

      await loader.initialize();
      expect(loader.isEmpty, false);

      await loader.reset();
      expect(loader.isEmpty, true);
    });

    test('test list empty value', () async {
      final loader = StaleMateLoader(handler: ListEmptyValueHandler());
      expect(loader.isEmpty, true);

      await loader.initialize();
      expect(loader.isEmpty, false);

      await loader.reset();
      expect(loader.isEmpty, true);
    });

    test('test map empty value', () async {
      final loader = StaleMateLoader(handler: MapEmptyValueHandler());
      expect(loader.isEmpty, true);

      await loader.initialize();
      expect(loader.isEmpty, false);

      await loader.reset();
      expect(loader.isEmpty, true);
    });

    test('test set empty value', () async {
      final loader = StaleMateLoader(handler: SetEmptyValueHandler());
      expect(loader.isEmpty, true);

      await loader.initialize();
      expect(loader.isEmpty, false);

      await loader.reset();
      expect(loader.isEmpty, true);
    });

    test('test nullable empty value', () async {
      final loader = StaleMateLoader(handler: NullableEmptyValueHandler());
      expect(loader.isEmpty, true);

      await loader.initialize();
      expect(loader.isEmpty, false);

      await loader.reset();
      expect(loader.isEmpty, true);
    });

    test('test enum empty value', () async {
      final loader = StaleMateLoader(handler: EnumEmptyValueHandler());
      expect(loader.isEmpty, true);

      await loader.initialize();
      expect(loader.isEmpty, false);

      await loader.reset();
      expect(loader.isEmpty, true);
    });

    test('test custom class empty value', () async {
      final loader = StaleMateLoader(handler: CustomClassEmptyValueHandler());
      expect(loader.isEmpty, true);

      await loader.initialize();
      expect(loader.isEmpty, false);

      await loader.reset();
      expect(loader.isEmpty, true);
    });
  });
}
