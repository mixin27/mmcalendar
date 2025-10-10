import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class UpdateEvent implements UseCase<Event, UpdateEventParams> {
  final EventsRepository repository;

  UpdateEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(UpdateEventParams params) async {
    // Validate ID
    if (params.id <= 0) {
      return const Left(ValidationFailure('Invalid event ID'));
    }

    // Validate title if provided
    if (params.title != null && params.title!.trim().isEmpty) {
      return const Left(ValidationFailure('Event title cannot be empty'));
    }

    if (params.title != null && params.title!.length > 200) {
      return const Left(
        ValidationFailure('Event title too long (max 200 characters)'),
      );
    }

    // Validate priority if provided
    if (params.priority != null &&
        (params.priority! < 0 || params.priority! > 3)) {
      return const Left(ValidationFailure('Invalid priority value'));
    }

    return await repository.updateEvent(
      id: params.id,
      title: params.title,
      description: params.description,
      eventDate: params.eventDate,
      eventTime: params.eventTime,
      isAllDay: params.isAllDay,
      category: params.category,
      categoryId: params.categoryId,
      colorCode: params.colorCode,
      location: params.location,
      priority: params.priority,
    );
  }
}

class UpdateEventParams {
  final int id;
  final String? title;
  final String? description;
  final DateTime? eventDate;
  final DateTime? eventTime;
  final bool? isAllDay;
  final String? category;
  final int? categoryId;
  final int? colorCode;
  final String? location;
  final int? priority;

  UpdateEventParams({
    required this.id,
    this.title,
    this.description,
    this.eventDate,
    this.eventTime,
    this.isAllDay,
    this.category,
    this.categoryId,
    this.colorCode,
    this.location,
    this.priority,
  });
}
