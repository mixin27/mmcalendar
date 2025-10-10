import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

class CreateEvent implements UseCase<Event, CreateEventParams> {
  final EventsRepository repository;

  CreateEvent(this.repository);

  @override
  Future<Either<Failure, Event>> call(CreateEventParams params) async {
    // Validate title
    if (params.title.trim().isEmpty) {
      return const Left(ValidationFailure('Event title cannot be empty'));
    }

    if (params.title.length > 200) {
      return const Left(
        ValidationFailure('Event title too long (max 200 characters)'),
      );
    }

    // Validate date
    if (params.eventDate.year < 1900 || params.eventDate.year > 2100) {
      return const Left(ValidationFailure('Invalid event date'));
    }

    // Validate priority
    if (params.priority < 0 || params.priority > 3) {
      return const Left(ValidationFailure('Invalid priority value'));
    }

    // Validate notification minutes
    if (params.hasNotification &&
        (params.notificationMinutes == null ||
            params.notificationMinutes!.isEmpty)) {
      return const Left(
        ValidationFailure(
          'Notification times required when notifications enabled',
        ),
      );
    }

    return await repository.createEvent(
      title: params.title,
      description: params.description,
      eventDate: params.eventDate,
      eventTime: params.eventTime,
      isAllDay: params.isAllDay,
      category: params.category,
      categoryId: params.categoryId,
      colorCode: params.colorCode,
      recurrence: params.recurrence,
      hasNotification: params.hasNotification,
      notificationMinutes: params.notificationMinutes,
      location: params.location,
      priority: params.priority,
      tags: params.tags,
    );
  }
}

class CreateEventParams {
  final String title;
  final String? description;
  final DateTime eventDate;
  final DateTime? eventTime;
  final bool isAllDay;
  final String category;
  final int? categoryId;
  final int? colorCode;
  final RecurrenceRule? recurrence;
  final bool hasNotification;
  final List<int>? notificationMinutes;
  final String? location;
  final int priority;
  final List<String>? tags;

  CreateEventParams({
    required this.title,
    this.description,
    required this.eventDate,
    this.eventTime,
    this.isAllDay = true,
    required this.category,
    this.categoryId,
    this.colorCode,
    this.recurrence,
    this.hasNotification = false,
    this.notificationMinutes,
    this.location,
    this.priority = 0,
    this.tags,
  });
}
