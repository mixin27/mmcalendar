import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class GetEventById implements UseCase<Event, int> {
  final EventsRepository repository;

  GetEventById(this.repository);

  @override
  Future<Either<Failure, Event>> call(int id) async {
    if (id <= 0) {
      return const Left(ValidationFailure('Invalid event ID'));
    }

    return await repository.getEventById(id);
  }
}
