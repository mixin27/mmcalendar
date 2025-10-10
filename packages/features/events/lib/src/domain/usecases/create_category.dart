import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class CreateCategoryParams {
  final String name;
  final String iconName;
  final int colorCode;
  final int sortOrder;

  CreateCategoryParams({
    required this.name,
    required this.iconName,
    required this.colorCode,
    this.sortOrder = 0,
  });
}

class CreateCategory implements UseCase<EventCategory, CreateCategoryParams> {
  final EventsRepository repository;

  CreateCategory(this.repository);

  @override
  Future<Either<Failure, EventCategory>> call(
    CreateCategoryParams params,
  ) async {
    // Validate name
    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure('Category name cannot be empty'));
    }

    if (params.name.length > 50) {
      return const Left(
        ValidationFailure('Category name too long (max 50 characters)'),
      );
    }

    // Validate icon name
    if (params.iconName.trim().isEmpty) {
      return const Left(ValidationFailure('Icon name cannot be empty'));
    }

    return await repository.createCategory(
      name: params.name,
      iconName: params.iconName,
      colorCode: params.colorCode,
      sortOrder: params.sortOrder,
    );
  }
}
