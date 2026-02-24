import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

/// Use case for getting upcoming events
class GetUpcomingEvents
    implements UseCase<List<Event>, GetUpcomingEventsParams> {
  final EventsRepository repository;

  GetUpcomingEvents(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(
    GetUpcomingEventsParams params,
  ) async {
    return await repository.getUpcomingEvents(days: params.days);
  }
}

class GetUpcomingEventsParams extends Equatable {
  final int days;

  const GetUpcomingEventsParams({this.days = 7});

  @override
  List<Object?> get props => [days];
}
