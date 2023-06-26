import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stalemate/stalemate.dart';

import '../mocks/mock_string_loader.dart';

void main() {
  testWidgets('StaleMateBuilder test', (WidgetTester tester) async {
    // Create a StaleMateLoader instance
    StringLoader loader = StringLoader(
      handler: MockStringHandler(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StaleMateBuilder<String, MockStringHandler>(
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
    await tester.pump(const Duration(milliseconds: 5));

    // Should be initial data right after initialization
    expect(find.text('initial local data'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('remote data 1'), findsOneWidget);

    await loader.reset();

    // Simulate an error
    loader.setShouldThrowRemoteError(true);

    await tester.pump(const Duration(milliseconds: 10));
    // Trigger a refresh
    loader.refresh();

    await tester.pump(const Duration(milliseconds: 15));
    expect(find.text('Error'), findsOneWidget);
  });
}
