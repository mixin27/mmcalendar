import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class ToggleEventComplete implements UseCase<Event, int> {
  final EventsRepository repository;

  ToggleEventComplete(this.repository);

  @override
  Future<Either<Failure, Event>> call(int id) async {
    if (id <= 0) {
      return const Left(ValidationFailure('Invalid event ID'));
    }

    return await repository.toggleComplete(id);
  }
}
