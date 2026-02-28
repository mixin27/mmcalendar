import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

/// Use case for getting a single event by ID
class GetEventById implements UseCase<Event, GetEventByIdParams> {
  final EventsRepository repository;

  GetEventById(this.repository);

  @override
  Future<Either<Failure, Event>> call(GetEventByIdParams params) async {
    return await repository.getEventById(params.eventId);
  }
}

class GetEventByIdParams extends Equatable {
  final int eventId;

  const GetEventByIdParams(this.eventId);

  @override
  List<Object?> get props => [eventId];
}
