import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class GetAllCategories implements NoParamsUseCase<List<EventCategory>> {
  final EventsRepository repository;

  GetAllCategories(this.repository);

  @override
  Future<Either<Failure, List<EventCategory>>> call() async {
    return await repository.getAllCategories();
  }
}
