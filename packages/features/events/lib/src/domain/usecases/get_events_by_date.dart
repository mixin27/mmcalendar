import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class GetEventsByDate implements UseCase<List<Event>, DateTime> {
  final EventsRepository repository;

  GetEventsByDate(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(DateTime date) async {
    return await repository.getEventsByDate(date);
  }
}
