import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

/// Use case for getting events by specific date
class GetEventsByDate implements UseCase<List<Event>, GetEventsByDateParams> {
  final EventsRepository repository;

  GetEventsByDate(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(
    GetEventsByDateParams params,
  ) async {
    final result = await repository.getEventsByDate(params.date);

    // Include recurring events for this date
    return result.map((events) {
      final allEvents = <Event>[...events];

      // Add recurring event occurrences
      for (final event in events) {
        if (event.isRecurring && event.recurrenceRule != null) {
          final occurrences = event.recurrenceRule!.generateOccurrences(
            event.eventDate,
            params.date,
            params.date.add(const Duration(days: 1)),
          );
          for (final occurrence in occurrences) {
            if (!allEvents.any((e) => e.isOnDate(occurrence))) {
              allEvents.add(event.copyWith(eventDate: occurrence));
            }
          }
        }
      }

      // Sort by time
      allEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
      return allEvents;
    });
  }
}

class GetEventsByDateParams extends Equatable {
  final DateTime date;

  const GetEventsByDateParams(this.date);

  @override
  List<Object?> get props => [date];
}
