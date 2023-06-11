import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stalemate/stalemate.dart';

class StringLoader extends StaleMateLoader<String> {
  String _localData = 'initial local data';
  bool shouldThrowError = false;
  int timesUpdatedFromRemote = 0;

  StringLoader({
    bool updateOnInit = true,
  }) : super(
          emptyValue: '',
          updateOnInit: updateOnInit,
        );

  @override
  Future<String> getLocalData() async {
    return _localData;
  }

  @override
  Future<String> getRemoteData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldThrowError) {
      throw Exception('Failed to fetch remote data');
    }
    return 'remote data ${++timesUpdatedFromRemote}';
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

void main() {
  testWidgets('StaleMateBuilder test', (WidgetTester tester) async {
    // Create a StaleMateLoader instance
    StringLoader loader = StringLoader();

    await tester.pumpWidget(
      MaterialApp(
        home: StaleMateBuilder<String>(
          loader: loader,
          builder: (context, data) {
            if (data.isLoading) {
              return const Text('Loading');
            } else if (data.isLoaded) {
              return Text(data.requireData);
            } else if (data.isError) {
              return const Text('Error');
            }
            return const Text('Empty');
          },
        ),
      ),
    );

    // Should be loading at start
    expect(find.text('Loading'), findsOneWidget);

    loader.initialize();
    await tester.pump(const Duration(milliseconds: 10));

    // Should be initial data right after initialization
    expect(find.text('initial local data'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('remote data 1'), findsOneWidget);

    loader.reset();

    // Simulate an error
    loader.shouldThrowError = true;

    await tester.pump(const Duration(milliseconds: 10));
    // Trigger a refresh
    loader.refresh();

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Error'), findsOneWidget);
  });
}
