import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stalemate/src/utils/future_utils.dart';

void main() {
  test('executeConcurrently handles successful futures', () async {
    final futures = [
      Future.value(1),
      Future.value(2),
      Future.value(3),
    ];

    final results = await executeConcurrently<int>(futures);

    expect(results, [
      const Right(1),
      const Right(2),
      const Right(3),
    ]);
  });

  test('executeConcurrently handles failed futures', () async {
    final futures = [
      Future.value(1),
      Future<int>.error(Exception('Test exception')),
      Future.value(3),
    ];

    final results = await executeConcurrently<int>(futures);

    expect(results[0], const Right(1));
    expect(results[1], isA<Left>());
    expect(results[2], const Right(3));
  });
}