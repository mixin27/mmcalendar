import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

/// Use case for updating an existing event
class UpdateUserEvent implements UseCase<Event, UpdateUserEventParams> {
  final EventsRepository repository;

  UpdateUserEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(UpdateUserEventParams params) async {
    // Validate event
    if (params.event.id == null) {
      return Left(ValidationFailure('Event ID is required for update'));
    }

    final validationResult = _validateEvent(params.event);
    if (validationResult != null) {
      return Left(ValidationFailure(validationResult));
    }

    // Update event with new timestamp
    final updatedEvent = params.event.copyWith(updatedAt: DateTime.now());
    return repository.updateEvent(updatedEvent);
  }

  String? _validateEvent(Event event) {
    if (event.title.trim().isEmpty) {
      return 'Event title cannot be empty';
    }
    if (event.title.length > 200) {
      return 'Event title cannot exceed 200 characters';
    }
    return null;
  }
}

class UpdateUserEventParams extends Equatable {
  final Event event;

  const UpdateUserEventParams(this.event);

  @override
  List<Object?> get props => [event];
}
