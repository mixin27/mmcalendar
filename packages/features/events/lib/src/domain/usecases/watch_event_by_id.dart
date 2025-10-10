import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class WatchEventById implements StreamUseCase<Event, int> {
  final EventsRepository repository;

  WatchEventById(this.repository);

  @override
  Stream<Either<Failure, Event>> call(int id) {
    if (id <= 0) {
      return Stream.value(const Left(ValidationFailure('Invalid event ID')));
    }

    return repository.watchEventById(id);
  }
}
