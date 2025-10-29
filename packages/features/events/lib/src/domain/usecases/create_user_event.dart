import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

/// Use case for creating a new event
class CreateUserEvent implements UseCase<Event, CreateUserEventParams> {
  final EventsRepository repository;

  CreateUserEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(CreateUserEventParams params) async {
    // Validate event data
    final validationResult = _validateEvent(params.event);
    if (validationResult != null) {
      return Left(ValidationFailure(validationResult));
    }

    // Create event
    final result = await repository.createEvent(params.event);

    // Fire domain event on success
    result.fold((failure) => null, (event) {
      if (event.id != null) {
        AppEventBus.fire(EventCreatedEvent(event.id!, event.title));
      }
    });

    return result;
  }

  String? _validateEvent(Event event) {
    if (event.title.trim().isEmpty) {
      return 'Event title cannot be empty';
    }
    if (event.title.length > 200) {
      return 'Event title cannot exceed 200 characters';
    }
    if (event.eventDate.year < 1900 || event.eventDate.year > 2100) {
      return 'Event date must be between 1900 and 2100';
    }
    if (!event.isAllDay && event.eventTime == null) {
      return 'Event time is required for non-all-day events';
    }
    return null;
  }
}

class CreateUserEventParams extends Equatable {
  final Event event;

  const CreateUserEventParams(this.event);

  @override
  List<Object?> get props => [event];
}
