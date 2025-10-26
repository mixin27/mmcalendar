import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

/// Use case for toggling event completion status
class ToggleEventCompletion
    implements UseCase<Event, ToggleEventCompletionParams> {
  final EventsRepository repository;

  ToggleEventCompletion(this.repository);

  @override
  Future<Either<Failure, Event>> call(
    ToggleEventCompletionParams params,
  ) async {
    final result = await repository.toggleEventCompletion(
      params.eventId,
      params.isCompleted,
    );

    // Fire domain event on success
    result.fold((failure) => null, (event) {
      if (event.id != null) {
        AppEventBus.fire(EventUpdatedEvent(event.id!, event.title));
      }
    });

    return result;
  }
}

class ToggleEventCompletionParams extends Equatable {
  final int eventId;
  final bool isCompleted;

  const ToggleEventCompletionParams(this.eventId, this.isCompleted);

  @override
  List<Object?> get props => [eventId, isCompleted];
}
