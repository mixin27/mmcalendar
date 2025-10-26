import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event_category.dart';
import '../repositories/events_repository.dart';

/// Use case for creating a new event category
class CreateEventCategory
    implements UseCase<EventCategory, CreateEventCategoryParams> {
  final EventsRepository repository;

  CreateEventCategory(this.repository);

  @override
  Future<Either<Failure, EventCategory>> call(
    CreateEventCategoryParams params,
  ) async {
    // Validate category
    if (params.category.name.trim().isEmpty) {
      return Left(ValidationFailure('Category name cannot be empty'));
    }

    return await repository.createCategory(params.category);
  }
}

class CreateEventCategoryParams extends Equatable {
  final EventCategory category;

  const CreateEventCategoryParams(this.category);

  @override
  List<Object?> get props => [category];
}
