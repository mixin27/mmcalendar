import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../entities/notification_setting.dart';
import '../entities/recurrence_rule.dart';

/// Centralized event validation rules used by form and use-cases.
class EventValidationService {
  static const int maxTitleLength = 200;
  static const int maxDescriptionLength = 4000;
  static const int maxLocationLength = 255;
  static const int maxTagLength = 32;
  static const int maxTagsCount = 20;
  static const int maxReminderMinutes = 7 * 24 * 60; // 7 days

  const EventValidationService._();

  static EventValidationResult validateEvent(
    Event event, {
    required bool isUpdate,
  }) {
    if (isUpdate && event.id == null) {
      return const EventValidationResult.invalid(
        'Event ID is required for update',
      );
    }

    final title = event.title.trim();
    if (title.isEmpty) {
      return const EventValidationResult.invalid('Event title cannot be empty');
    }
    if (title.length > maxTitleLength) {
      return const EventValidationResult.invalid(
        'Event title cannot exceed 200 characters',
      );
    }

    if (event.description != null &&
        event.description!.trim().length > maxDescriptionLength) {
      return const EventValidationResult.invalid(
        'Description cannot exceed 4000 characters',
      );
    }

    if (event.location != null &&
        event.location!.trim().length > maxLocationLength) {
      return const EventValidationResult.invalid(
        'Location cannot exceed 255 characters',
      );
    }

    if (event.eventDate.year < 1900 || event.eventDate.year > 2100) {
      return const EventValidationResult.invalid(
        'Event date must be between 1900 and 2100',
      );
    }

    if (!event.isAllDay && event.eventTime == null) {
      return const EventValidationResult.invalid(
        'Event time is required for non-all-day events',
      );
    }

    final reminderValidation = _validateNotifications(event.notifications);
    if (!reminderValidation.isValid) {
      return reminderValidation;
    }

    final recurrenceValidation = _validateRecurrence(
      event.recurrenceRule,
      event.eventDate,
    );
    if (!recurrenceValidation.isValid) {
      return recurrenceValidation;
    }

    final tags = event.tags.map((tag) => tag.trim()).where((t) => t.isNotEmpty);
    if (tags.length > maxTagsCount) {
      return const EventValidationResult.invalid(
        'You can only add up to 20 tags',
      );
    }

    for (final tag in tags) {
      if (tag.length > maxTagLength) {
        return const EventValidationResult.invalid(
          'Each tag must be at most 32 characters',
        );
      }
    }

    return const EventValidationResult.valid();
  }

  static Event sanitizeForPersist(
    Event event, {
    required DateTime now,
    required bool isUpdate,
  }) {
    final normalizedTitle = event.title.trim();
    final normalizedDescription = event.description?.trim();
    final normalizedLocation = event.location?.trim();

    final normalizedTags = event.tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final normalizedNotifications = _normalizeNotifications(
      event.notifications,
    );

    return event.copyWith(
      title: normalizedTitle,
      description: (normalizedDescription?.isEmpty ?? true)
          ? null
          : normalizedDescription,
      location: (normalizedLocation?.isEmpty ?? true)
          ? null
          : normalizedLocation,
      tags: normalizedTags,
      notifications: normalizedNotifications,
      eventTime: event.isAllDay ? null : event.eventTime,
      createdAt: isUpdate ? event.createdAt : now,
      updatedAt: now,
      completedAt: event.status == EventStatus.completed
          ? event.completedAt
          : null,
    );
  }

  static EventValidationResult _validateNotifications(
    List<NotificationSetting> notifications,
  ) {
    final seen = <String>{};
    for (final notification in notifications) {
      if (notification.minutesBefore < 0 ||
          notification.minutesBefore > maxReminderMinutes) {
        return const EventValidationResult.invalid(
          'Reminder time must be between 0 and 10080 minutes',
        );
      }

      final key = '${notification.minutesBefore}:${notification.channel.name}';
      if (!seen.add(key)) {
        return const EventValidationResult.invalid(
          'Duplicate reminder settings are not allowed',
        );
      }
    }
    return const EventValidationResult.valid();
  }

  static EventValidationResult _validateRecurrence(
    RecurrenceRule? recurrenceRule,
    DateTime eventDate,
  ) {
    if (recurrenceRule == null || recurrenceRule.type == RecurrenceType.none) {
      return const EventValidationResult.valid();
    }

    if (recurrenceRule.interval < 1) {
      return const EventValidationResult.invalid(
        'Recurrence interval must be at least 1',
      );
    }

    if (recurrenceRule.type == RecurrenceType.weekly &&
        recurrenceRule.daysOfWeek != null &&
        recurrenceRule.daysOfWeek!.isNotEmpty) {
      final valid = recurrenceRule.daysOfWeek!.every(
        (day) => day >= 1 && day <= 7,
      );
      if (!valid) {
        return const EventValidationResult.invalid(
          'Weekly recurrence days must be between 1 and 7',
        );
      }
    }

    if (recurrenceRule.dayOfMonth != null &&
        (recurrenceRule.dayOfMonth! < 1 || recurrenceRule.dayOfMonth! > 31)) {
      return const EventValidationResult.invalid(
        'Day of month must be between 1 and 31',
      );
    }

    if (recurrenceRule.monthOfYear != null &&
        (recurrenceRule.monthOfYear! < 1 || recurrenceRule.monthOfYear! > 12)) {
      return const EventValidationResult.invalid(
        'Month of year must be between 1 and 12',
      );
    }

    if (recurrenceRule.occurrenceCount != null &&
        recurrenceRule.occurrenceCount! < 1) {
      return const EventValidationResult.invalid(
        'Occurrence count must be at least 1',
      );
    }

    if (recurrenceRule.endDate != null &&
        _dateOnly(recurrenceRule.endDate!).isBefore(_dateOnly(eventDate))) {
      return const EventValidationResult.invalid(
        'Recurrence end date must be on or after the event date',
      );
    }

    return const EventValidationResult.valid();
  }

  static List<NotificationSetting> _normalizeNotifications(
    List<NotificationSetting> notifications,
  ) {
    final unique = <String, NotificationSetting>{};
    for (final notification in notifications) {
      final key = '${notification.minutesBefore}:${notification.channel.name}';
      unique[key] = notification;
    }
    final result = unique.values.toList(growable: false);
    result.sort((a, b) => b.minutesBefore.compareTo(a.minutesBefore));
    return result;
  }

  static DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);
}

class EventValidationResult extends Equatable {
  final bool isValid;
  final String? message;

  const EventValidationResult._(this.isValid, this.message);

  const EventValidationResult.valid() : this._(true, null);

  const EventValidationResult.invalid(String message) : this._(false, message);

  @override
  List<Object?> get props => [isValid, message];
}
