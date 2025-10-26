import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

/// Use case for watching all events stream
class WatchUserEvents implements StreamUseCase<List<Event>, NoParams> {
  final EventsRepository repository;

  WatchUserEvents(this.repository);

  @override
  Stream<Either<Failure, List<Event>>> call(NoParams params) {
    return repository.watchAllEvents();
  }
}

/// Use case for watching events by date range
class WatchEventsByDateRange
    implements StreamUseCase<List<Event>, WatchEventsByDateRangeParams> {
  final EventsRepository repository;

  WatchEventsByDateRange(this.repository);

  @override
  Stream<Either<Failure, List<Event>>> call(
    WatchEventsByDateRangeParams params,
  ) {
    return repository.watchEventsByDateRange(params.startDate, params.endDate);
  }
}

class WatchEventsByDateRangeParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const WatchEventsByDateRangeParams(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}
