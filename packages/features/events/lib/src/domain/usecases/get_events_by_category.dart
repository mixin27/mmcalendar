import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class GetEventsByCategory implements UseCase<List<Event>, String> {
  final EventsRepository repository;

  GetEventsByCategory(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(String category) async {
    if (category.trim().isEmpty) {
      return const Left(ValidationFailure('Category cannot be empty'));
    }

    return await repository.getEventsByCategory(category);
  }
}
