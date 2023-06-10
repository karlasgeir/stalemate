import 'package:flutter_test/flutter_test.dart';

import 'package:stalemate/stalemate.dart';

class StringLoader extends StaleMateLoader<String?> {
  String? _localData = 'intial local data';

  StringLoader({
    bool updateOnInit = true,
  }) : super(
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
    return 'remote data';
  }

  @override
  Future<void> storeLocalData(String? data) async {
    _localData = data;
  }

  @override
  Future<void> removeLocalData() async {
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
      expect(stringLoader.value, equals('intial local data'));
    });

    test(
        'value should be remote data after initialization is complete if updateOnInit is true',
        () async {
      await stringLoader.initialize();
      expect(stringLoader.value, equals('remote data'));
    });

    test(
        'value should be local data after initialization is complete if updateOnInit is false',
        () async {
      stringLoader = StringLoader(updateOnInit: false);
      await stringLoader.initialize();
      expect(stringLoader.value, equals('intial local data'));
    });

    test('value should be remote data after refresh', () async {
      await stringLoader.initialize();
      await stringLoader.refresh();
      expect(stringLoader.value, equals('remote data'));
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
      expect(localData, equals('remote data'));
    });
  });
}
