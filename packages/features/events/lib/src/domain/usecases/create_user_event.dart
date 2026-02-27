import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';
import '../services/event_validation_service.dart';

/// Use case for creating a new event
class CreateUserEvent implements UseCase<Event, CreateUserEventParams> {
  final EventsRepository repository;

  CreateUserEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(CreateUserEventParams params) async {
    final validation = EventValidationService.validateEvent(
      params.event,
      isUpdate: false,
    );
    if (!validation.isValid) {
      return Left(
        ValidationFailure(validation.message ?? 'Invalid event data'),
      );
    }

    final sanitized = EventValidationService.sanitizeForPersist(
      params.event,
      now: DateTime.now(),
      isUpdate: false,
    );

    return repository.createEvent(sanitized);
  }
}

class CreateUserEventParams extends Equatable {
  final Event event;

  const CreateUserEventParams(this.event);

  @override
  List<Object?> get props => [event];
}
