import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../repositories/events_repository.dart';

class InitializeDefaultCategories implements UseCase<void, void> {
  final EventsRepository repository;

  InitializeDefaultCategories(this.repository);

  @override
  Future<Either<Failure, void>> call(void param) async {
    return await repository.initializeDefaultCategories();
  }
}
