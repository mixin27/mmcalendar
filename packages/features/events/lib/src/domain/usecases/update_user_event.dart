import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';
import '../services/event_validation_service.dart';

/// Use case for updating an existing event
class UpdateUserEvent implements UseCase<Event, UpdateUserEventParams> {
  final EventsRepository repository;

  UpdateUserEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(UpdateUserEventParams params) async {
    final validation = EventValidationService.validateEvent(
      params.event,
      isUpdate: true,
    );
    if (!validation.isValid) {
      return Left(
        ValidationFailure(validation.message ?? 'Invalid event data'),
      );
    }

    final updatedEvent = EventValidationService.sanitizeForPersist(
      params.event,
      now: DateTime.now(),
      isUpdate: true,
    );
    return repository.updateEvent(updatedEvent);
  }
}

class UpdateUserEventParams extends Equatable {
  final Event event;

  const UpdateUserEventParams(this.event);

  @override
  List<Object?> get props => [event];
}
