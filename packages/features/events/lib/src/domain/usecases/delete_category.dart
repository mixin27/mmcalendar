import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../repositories/events_repository.dart';

class DeleteCategory implements UseCase<void, int> {
  final EventsRepository repository;

  DeleteCategory(this.repository);

  @override
  Future<Either<Failure, void>> call(int id) async {
    if (id <= 0) {
      return const Left(ValidationFailure('Invalid category ID'));
    }

    return await repository.deleteCategory(id);
  }
}
