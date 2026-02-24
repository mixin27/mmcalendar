import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

/// Use case for getting events within a date range
class GetEventsByDateRange
    implements UseCase<List<Event>, GetEventsByDateRangeParams> {
  final EventsRepository repository;

  GetEventsByDateRange(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(
    GetEventsByDateRangeParams params,
  ) async {
    // Validate date range
    if (params.endDate.isBefore(params.startDate)) {
      return Left(ValidationFailure('End date must be after start date'));
    }

    final result = await repository.getEventsByDateRange(
      params.startDate,
      params.endDate,
    );

    // Include recurring events within this range
    return result.map((events) {
      final allEvents = <Event>[...events];

      // Add recurring event occurrences
      for (final event in events) {
        if (event.isRecurring && event.recurrenceRule != null) {
          final occurrences = event.recurrenceRule!.generateOccurrences(
            event.eventDate,
            params.startDate,
            params.endDate,
          );
          for (final occurrence in occurrences) {
            allEvents.add(event.copyWith(eventDate: occurrence));
          }
        }
      }

      // Sort by date/time
      allEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
      return allEvents;
    });
  }
}

class GetEventsByDateRangeParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const GetEventsByDateRangeParams(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}
