import 'package:dartz/dartz.dart';

/// Executes a list of futures concurrently and returns a list of [Either]s containing either the result of the future or an exception.
Future<List<Either<Object, T>>> executeConcurrently<T>(List<Future<T>> futures) async {
  return Future.wait(
    futures.map(
      (future) async {
        try {
          final result = await future;
          return Right(result);
        } catch (exception) {
          return Left(exception);
        }
      },
    ),
  );
}