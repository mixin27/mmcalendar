import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../repositories/events_repository.dart';

/// Use case for deleting an event
class DeleteUserEvent implements UseCase<void, DeleteUserEventParams> {
  final EventsRepository repository;

  DeleteUserEvent(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteUserEventParams params) async {
    final result = await repository.deleteEvent(params.eventId);

    // Fire domain event on success
    result.fold(
      (failure) => null,
      (_) => AppEventBus.fire(EventDeletedEvent(params.eventId)),
    );

    return result;
  }
}

class DeleteUserEventParams extends Equatable {
  final int eventId;

  const DeleteUserEventParams(this.eventId);

  @override
  List<Object?> get props => [eventId];
}
