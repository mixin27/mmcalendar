import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../repositories/events_repository.dart';

/// Use case for deleting an event
class DeleteUserEvent implements UseCase<void, DeleteUserEventParams> {
  final EventsRepository repository;

  DeleteUserEvent(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteUserEventParams params) =>
      repository.deleteEvent(params.eventId);
}

class DeleteUserEventParams extends Equatable {
  final int eventId;

  const DeleteUserEventParams(this.eventId);

  @override
  List<Object?> get props => [eventId];
}
