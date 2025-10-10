import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class GetEventsByDateRange
    implements UseCase<List<Event>, GetEventsByDateRangeParams> {
  final EventsRepository repository;

  GetEventsByDateRange(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(
    GetEventsByDateRangeParams params,
  ) async {
    // Validate date range
    if (params.startDate.isAfter(params.endDate)) {
      return const Left(
        ValidationFailure('Start date must be before end date'),
      );
    }

    return await repository.getEventsByDateRange(
      params.startDate,
      params.endDate,
    );
  }
}

class GetEventsByDateRangeParams {
  final DateTime startDate;
  final DateTime endDate;

  GetEventsByDateRangeParams({required this.startDate, required this.endDate});
}
