import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stalemate/src/stalemate_loader/stalemate_loader.dart';
import 'package:stalemate/src/stalemate_registry/stalemate_registry.dart';

import 'stalemate_registry_test.mocks.dart';

class StaleMateLoaderImpl1 extends StaleMateLoader<String> {
  StaleMateLoaderImpl1() : super(emptyValue: "");
}

class StaleMateLoaderImpl2 extends StaleMateLoader<int> {
  StaleMateLoaderImpl2() : super(emptyValue: 0);
}

@GenerateMocks([StaleMateLoaderImpl1, StaleMateLoaderImpl2])
void main() {
  tearDown(() {
    StaleMateRegistry.instance.unregisterAll();
  });

  group('StaleMateRegistry registration', () {
    test('register and unregister loader', () {
      final loader = MockStaleMateLoaderImpl1();
      expect(StaleMateRegistry.instance.numberOfLoaders, 0);
      StaleMateRegistry.instance.register(loader);
      expect(StaleMateRegistry.instance.numberOfLoaders, 1);
      StaleMateRegistry.instance.unregister(loader);
      expect(StaleMateRegistry.instance.numberOfLoaders, 0);
    });

    test('register and unregister loader twice', () {
      final loader = MockStaleMateLoaderImpl1();
      expect(StaleMateRegistry.instance.numberOfLoaders, 0);
      StaleMateRegistry.instance.register(loader);
      expect(StaleMateRegistry.instance.numberOfLoaders, 1);
      StaleMateRegistry.instance.register(loader);
      expect(StaleMateRegistry.instance.numberOfLoaders, 1);
      StaleMateRegistry.instance.unregister(loader);
      expect(StaleMateRegistry.instance.numberOfLoaders, 0);
      StaleMateRegistry.instance.unregister(loader);
      expect(StaleMateRegistry.instance.numberOfLoaders, 0);
    });

    test('Unregister loader that was not registered', () {
      final loader1 = MockStaleMateLoaderImpl1();
      final loader2 = MockStaleMateLoaderImpl2();

      StaleMateRegistry.instance.register(loader1);

      expect(StaleMateRegistry.instance.numberOfLoaders, 1);
      StaleMateRegistry.instance.unregister(loader2);
      expect(StaleMateRegistry.instance.numberOfLoaders, 1);
    });
  });

  group('StaleMateRegistry all loaders', () {
    test('get all loaders', () async {
      final loader1 = MockStaleMateLoaderImpl1();
      final loader2 = MockStaleMateLoaderImpl1();
      final loader3 = MockStaleMateLoaderImpl2();

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);
      StaleMateRegistry.instance.register(loader3);

      expect(StaleMateRegistry.instance.getAllLoaders().length, 3);
    });

    test('refresh all loaders', () async {
      final loader1 = MockStaleMateLoaderImpl1();
      final loader2 = MockStaleMateLoaderImpl1();
      final loader3 = MockStaleMateLoaderImpl2();

      when(loader1.refresh()).thenAnswer((_) => Future.value(true));
      when(loader2.refresh()).thenAnswer((_) => Future.value(true));
      when(loader3.refresh()).thenAnswer((_) => Future.value(true));

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);
      StaleMateRegistry.instance.register(loader3);

      await StaleMateRegistry.instance.refreshAllLoaders();

      verify(loader1.refresh()).called(1);
      verify(loader2.refresh()).called(1);
      verify(loader3.refresh()).called(1);
    });

    test(
        'refresh all loaders returns false if one loader returns false on refresh',
        () async {
      final loader1 = MockStaleMateLoaderImpl1();
      final loader2 = MockStaleMateLoaderImpl1();
      final loader3 = MockStaleMateLoaderImpl2();

      when(loader1.refresh()).thenAnswer((_) => Future.value(true));
      when(loader2.refresh()).thenAnswer((_) => Future.value(false));
      when(loader3.refresh()).thenAnswer((_) => Future.value(true));

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);
      StaleMateRegistry.instance.register(loader3);

      final result = await StaleMateRegistry.instance.refreshAllLoaders();

      expect(result, false);

      verify(loader1.refresh()).called(1);
      verify(loader2.refresh()).called(1);
      verify(loader3.refresh()).called(1);
    });

    test(
        'refresh all loaders returns false if all loaders return false on refresh',
        () async {
      final loader1 = MockStaleMateLoaderImpl1();
      final loader2 = MockStaleMateLoaderImpl1();
      final loader3 = MockStaleMateLoaderImpl2();

      when(loader1.refresh()).thenAnswer((_) => Future.value(false));
      when(loader2.refresh()).thenAnswer((_) => Future.value(false));
      when(loader3.refresh()).thenAnswer((_) => Future.value(false));

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);
      StaleMateRegistry.instance.register(loader3);

      final result = await StaleMateRegistry.instance.refreshAllLoaders();

      expect(result, false);

      verify(loader1.refresh()).called(1);
      verify(loader2.refresh()).called(1);
      verify(loader3.refresh()).called(1);
    });

    test('clear all loaders', () async {
      final loader1 = MockStaleMateLoaderImpl1();
      final loader2 = MockStaleMateLoaderImpl1();
      final loader3 = MockStaleMateLoaderImpl2();

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);
      StaleMateRegistry.instance.register(loader3);

      await StaleMateRegistry.instance.resetAllLoaders();

      verify(loader1.reset()).called(1);
      verify(loader2.reset()).called(1);
      verify(loader3.reset()).called(1);
    });
  });

  group('StaleMateRegistry loaders of type', () {
    test('getLoaders of a specific type', () {
      final loader1 = MockStaleMateLoaderImpl1();
      final loader2 = MockStaleMateLoaderImpl1();
      final loader3 = MockStaleMateLoaderImpl2();

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);
      StaleMateRegistry.instance.register(loader3);

      final loaders =
          StaleMateRegistry.instance.getLoaders<MockStaleMateLoaderImpl1>();

      expect(loaders.length, 2);
      expect(
          // ignore: unnecessary_type_check
          loaders.every((loader) => loader is MockStaleMateLoaderImpl1),
          true);
    });

    test('refresh loaders of a specific type', () async {
      final loader1 = MockStaleMateLoaderImpl1();
      final loader2 = MockStaleMateLoaderImpl1();
      final loader3 = MockStaleMateLoaderImpl2();

      when(loader1.refresh()).thenAnswer((_) => Future.value(true));
      when(loader2.refresh()).thenAnswer((_) => Future.value(true));
      when(loader3.refresh()).thenAnswer((_) => Future.value(true));

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);
      StaleMateRegistry.instance.register(loader3);

      await StaleMateRegistry.instance
          .refreshLoaders<MockStaleMateLoaderImpl1>();

      verify(loader1.refresh()).called(1);
      verify(loader2.refresh()).called(1);
      verifyNever(loader3.refresh());
    });

    test('clear all loaders of a specific type', () async {
      final loader1 = MockStaleMateLoaderImpl1();
      final loader2 = MockStaleMateLoaderImpl1();
      final loader3 = MockStaleMateLoaderImpl2();

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);
      StaleMateRegistry.instance.register(loader3);

      await StaleMateRegistry.instance.resetLoaders<MockStaleMateLoaderImpl1>();

      verify(loader1.reset()).called(1);
      verify(loader2.reset()).called(1);
      verifyNever(loader3.reset());
    });
  });

  group('StaleMateRegistry first loaders of type', () {
    test('has loader of type returns true when it has the loader', () {
      final loader1 = MockStaleMateLoaderImpl1();
      final loader2 = MockStaleMateLoaderImpl1();
      final loader3 = MockStaleMateLoaderImpl2();

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);
      StaleMateRegistry.instance.register(loader3);

      expect(StaleMateRegistry.instance.hasLoader<MockStaleMateLoaderImpl1>(),
          true);
    });

    test('has loader of type returns false when it does not have the loader',
        () {
      final loader1 = MockStaleMateLoaderImpl1();
      final loader2 = MockStaleMateLoaderImpl1();

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);

      expect(StaleMateRegistry.instance.hasLoader<MockStaleMateLoaderImpl2>(),
          false);
    });

    test('get first loader of type returns the first loader of the type', () {
      final loader1 = MockStaleMateLoaderImpl2();
      final loader2 = MockStaleMateLoaderImpl1();
      final loader3 = MockStaleMateLoaderImpl1();
      final loader4 = MockStaleMateLoaderImpl2();

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);
      StaleMateRegistry.instance.register(loader3);
      StaleMateRegistry.instance.register(loader4);

      final loader =
          StaleMateRegistry.instance.getFirstLoader<MockStaleMateLoaderImpl1>();

      expect(loader, loader2);
    });

    test(
        'get first loader of type returns null when there is no loader of the type',
        () {
      final loader1 = MockStaleMateLoaderImpl2();
      final loader2 = MockStaleMateLoaderImpl2();

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);

      final loader =
          StaleMateRegistry.instance.getFirstLoader<MockStaleMateLoaderImpl1>();

      expect(loader, null);
    });

    test('refresh first loader of type refreshes the first loader of the type',
        () async {
      final loader1 = MockStaleMateLoaderImpl2();
      final loader2 = MockStaleMateLoaderImpl1();
      final loader3 = MockStaleMateLoaderImpl1();
      final loader4 = MockStaleMateLoaderImpl2();

      when(loader1.refresh()).thenAnswer((_) => Future.value(true));
      when(loader2.refresh()).thenAnswer((_) => Future.value(true));
      when(loader3.refresh()).thenAnswer((_) => Future.value(true));
      when(loader4.refresh()).thenAnswer((_) => Future.value(true));

      StaleMateRegistry.instance.register(loader1);
      StaleMateRegistry.instance.register(loader2);
      StaleMateRegistry.instance.register(loader3);
      StaleMateRegistry.instance.register(loader4);

      await StaleMateRegistry.instance
          .refreshFirstLoader<MockStaleMateLoaderImpl1>();

      verifyNever(loader1.refresh());
      verify(loader2.refresh()).called(1);
      verifyNever(loader3.refresh());
      verifyNever(loader4.refresh());
    });
  });

  test('clear first loader of type clears the first loader of the type',
      () async {
    final loader1 = MockStaleMateLoaderImpl2();
    final loader2 = MockStaleMateLoaderImpl1();
    final loader3 = MockStaleMateLoaderImpl1();
    final loader4 = MockStaleMateLoaderImpl2();

    StaleMateRegistry.instance.register(loader1);
    StaleMateRegistry.instance.register(loader2);
    StaleMateRegistry.instance.register(loader3);
    StaleMateRegistry.instance.register(loader4);

    await StaleMateRegistry.instance
        .resetFirstLoader<MockStaleMateLoaderImpl1>();

    verifyNever(loader1.reset());
    verify(loader2.reset()).called(1);
    verifyNever(loader3.reset());
    verifyNever(loader4.reset());
  });
}
