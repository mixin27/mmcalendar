import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event_category.dart';
import '../repositories/events_repository.dart';

/// Use case for getting all event categories
class GetEventCategories implements NoParamsUseCase<List<EventCategory>> {
  final EventsRepository repository;

  GetEventCategories(this.repository);

  @override
  Future<Either<Failure, List<EventCategory>>> call() async {
    return await repository.getAllCategories();
  }
}
