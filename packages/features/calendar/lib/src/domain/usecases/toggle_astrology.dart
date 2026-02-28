import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';

import '../repositories/calendar_repository.dart';

/// Use case to toggle astrology card expansion
class ToggleAstrology {
  final CalendarRepository repository;

  ToggleAstrology(this.repository);

  Future<Either<Failure, bool>> call() async {
    final currentState = await repository.isAstrologyExpanded();

    return await currentState.fold((failure) => Left(failure), (
      isExpanded,
    ) async {
      final newState = !isExpanded;
      await repository.toggleAstrologyExpansion(newState);
      return Right(newState);
    });
  }

  Future<Either<Failure, bool>> set(bool isExpanded) async {
    await repository.toggleAstrologyExpansion(isExpanded);
    return Right(isExpanded);
  }

  Future<Either<Failure, bool>> get() async {
    return await repository.isAstrologyExpanded();
  }
}
