import 'package:dartz/dartz.dart';

import '../errors/failures.dart';

/// Base class for all use cases
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<T> {
  Future<Either<Failure, T>> call();
}

/// Use case with stream return
abstract class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}

final class NoParams {}
