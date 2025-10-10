import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../repositories/events_repository.dart';

class DeleteEvent implements UseCase<void, int> {
  final EventsRepository repository;

  DeleteEvent(this.repository);

  @override
  Future<Either<Failure, void>> call(int id) async {
    if (id <= 0) {
      return const Left(ValidationFailure('Invalid event ID'));
    }

    return await repository.deleteEvent(id);
  }
}
