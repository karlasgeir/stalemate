import 'package:flutter_test/flutter_test.dart';

import 'package:stalemate/stalemate.dart';

class StringLoader extends StaleMateLoader<String?> {
  String? _localData;
  bool shouldThrowError = false;
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
    return _localData;
  }

  @override
  Future<String?> getRemoteData() async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (shouldThrowError) {
      throw Exception('Failed to fetch remote data');
    }
    return 'remote data ${++timesUpdatedFromRemote}';
  }

  @override
  Future<void> storeLocalData(String? data) async {
    _localData = data;
  }

  @override
  Future<void> removeLocalData() async {
    shouldThrowError = false;
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
      stringLoader.shouldThrowError = true;
      await stringLoader.initialize();
      expect(stringLoader.value, equals('initial local data'));
    });

    test('value should be local data after error and refresh', () async {
      stringLoader.shouldThrowError = true;
      await stringLoader.initialize();
      await stringLoader.refresh();
      expect(stringLoader.value, equals('initial local data'));
    });

    test('value should be remote data after error and refresh', () async {
      await stringLoader.initialize();
      stringLoader.shouldThrowError = true;
      await stringLoader.refresh();
      expect(stringLoader.value, equals('remote data 1'));
    });
  });
}
