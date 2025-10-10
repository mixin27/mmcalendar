import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class WatchAllEvents implements StreamUseCase<List<Event>, void> {
  final EventsRepository repository;

  WatchAllEvents(this.repository);

  @override
  Stream<Either<Failure, List<Event>>> call(void params) {
    return repository.watchAllEvents();
  }
}
