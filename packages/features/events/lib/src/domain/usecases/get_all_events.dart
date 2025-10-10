import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class GetAllEvents implements NoParamsUseCase<List<Event>> {
  final EventsRepository repository;

  GetAllEvents(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call() async {
    return await repository.getAllEvents();
  }
}
