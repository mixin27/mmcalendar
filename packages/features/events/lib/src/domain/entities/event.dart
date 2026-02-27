import 'package:equatable/equatable.dart';

import 'event_category.dart';
import 'notification_setting.dart';
import 'recurrence_rule.dart';

/// Core event entity representing a calendar event
class Event extends Equatable {
  static const Object _noChange = Object();

  final int? id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final DateTime? eventTime;
  final bool isAllDay;
  final EventCategory category;
  final int? colorCode;
  final RecurrenceRule? recurrenceRule;
  final List<NotificationSetting> notifications;
  final String? location;
  final EventStatus status;
  final EventPriority priority;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const Event({
    this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.eventTime,
    this.isAllDay = true,
    required this.category,
    this.colorCode,
    this.recurrenceRule,
    this.notifications = const [],
    this.location,
    this.status = EventStatus.pending,
    this.priority = EventPriority.normal,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// Get event color (from custom or category)
  int get effectiveColor => colorCode ?? category.colorCode;

  /// Check if event is completed
  bool get isCompleted => status == EventStatus.completed;

  /// Check if event is recurring
  bool get isRecurring => recurrenceRule != null;

  /// Check if event has notifications
  bool get hasNotifications => notifications.isNotEmpty;

  /// Get event date time (combines date and time)
  DateTime get eventDateTime {
    if (eventTime != null && !isAllDay) {
      return DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        eventTime!.hour,
        eventTime!.minute,
        eventTime!.second,
      );
    }
    return eventDate;
  }

  /// Check if event is on a specific date
  bool isOnDate(DateTime date) {
    return eventDate.year == date.year &&
        eventDate.month == date.month &&
        eventDate.day == date.day;
  }

  /// Check if event is in date range
  bool isInRange(DateTime start, DateTime end) {
    return !eventDate.isBefore(start) && !eventDate.isAfter(end);
  }

  /// Check if event is overdue (for non-completed events)
  bool get isOverdue {
    if (isCompleted) return false;
    return eventDateTime.isBefore(DateTime.now());
  }

  /// Check if event is today
  bool get isToday {
    final now = DateTime.now();
    return isOnDate(now);
  }

  /// Check if event is upcoming (within next 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    return eventDateTime.isAfter(now) && eventDateTime.isBefore(sevenDaysLater);
  }

  /// Copy with method for immutability
  Event copyWith({
    Object? id = _noChange,
    String? title,
    Object? description = _noChange,
    DateTime? eventDate,
    Object? eventTime = _noChange,
    bool? isAllDay,
    EventCategory? category,
    Object? colorCode = _noChange,
    Object? recurrenceRule = _noChange,
    List<NotificationSetting>? notifications,
    Object? location = _noChange,
    EventStatus? status,
    EventPriority? priority,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? completedAt = _noChange,
  }) {
    return Event(
      id: identical(id, _noChange) ? this.id : id as int?,
      title: title ?? this.title,
      description: identical(description, _noChange)
          ? this.description
          : description as String?,
      eventDate: eventDate ?? this.eventDate,
      eventTime: identical(eventTime, _noChange)
          ? this.eventTime
          : eventTime as DateTime?,
      isAllDay: isAllDay ?? this.isAllDay,
      category: category ?? this.category,
      colorCode: identical(colorCode, _noChange)
          ? this.colorCode
          : colorCode as int?,
      recurrenceRule: identical(recurrenceRule, _noChange)
          ? this.recurrenceRule
          : recurrenceRule as RecurrenceRule?,
      notifications: notifications ?? this.notifications,
      location: identical(location, _noChange)
          ? this.location
          : location as String?,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: identical(completedAt, _noChange)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    eventDate,
    eventTime,
    isAllDay,
    category,
    colorCode,
    recurrenceRule,
    notifications,
    location,
    status,
    priority,
    tags,
    createdAt,
    updatedAt,
    completedAt,
  ];
}

/// Event status enum
enum EventStatus {
  pending,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case EventStatus.pending:
        return 'Pending';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Event priority enum
enum EventPriority {
  low(0),
  normal(1),
  high(2),
  urgent(3);

  final int value;
  const EventPriority(this.value);

  String get displayName {
    switch (this) {
      case EventPriority.low:
        return 'Low';
      case EventPriority.normal:
        return 'Normal';
      case EventPriority.high:
        return 'High';
      case EventPriority.urgent:
        return 'Urgent';
    }
  }

  static EventPriority fromValue(int value) {
    return EventPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => EventPriority.normal,
    );
  }
}

/// Represents a single occurrence of a recurring event (virtual, not stored)
class EventInstance {
  final Event masterEvent;
  final DateTime occurrenceDate;
  final DateTime? occurrenceTime;
  final RecurringEventException? exception;

  const EventInstance({
    required this.masterEvent,
    required this.occurrenceDate,
    this.occurrenceTime,
    this.exception,
  });

  /// Get the effective title (considering exceptions)
  String get effectiveTitle {
    if (exception?.exceptionType == ExceptionType.modified &&
        exception?.modifiedTitle != null) {
      return exception!.modifiedTitle!;
    }
    return masterEvent.title;
  }

  /// Get the effective description
  String? get effectiveDescription {
    if (exception?.exceptionType == ExceptionType.modified &&
        exception?.modifiedDescription != null) {
      return exception!.modifiedDescription!;
    }
    return masterEvent.description;
  }

  /// Get the effective date
  DateTime get effectiveDate {
    if (exception?.exceptionType == ExceptionType.modified &&
        exception?.modifiedDate != null) {
      return exception!.modifiedDate!;
    }
    return occurrenceDate;
  }

  /// Get the effective time
  DateTime? get effectiveTime {
    if (exception?.exceptionType == ExceptionType.modified &&
        exception?.modifiedTime != null) {
      return exception!.modifiedTime!;
    }
    return occurrenceTime;
  }

  /// Get the effective location
  String? get effectiveLocation {
    if (exception?.exceptionType == ExceptionType.modified &&
        exception?.modifiedLocation != null) {
      return exception!.modifiedLocation!;
    }
    return masterEvent.location;
  }

  /// Check if this instance is deleted
  bool get isDeleted => exception?.exceptionType == ExceptionType.deleted;

  /// Check if this instance is completed
  bool get isCompleted {
    if (exception?.exceptionType == ExceptionType.completed) {
      return true;
    }
    if (exception?.isCompleted == true) {
      return true;
    }
    return false;
  }

  /// Check if this instance is modified
  bool get isModified => exception?.exceptionType == ExceptionType.modified;

  /// Get completed timestamp
  DateTime? get completedAt => exception?.completedAt;

  /// Convert to Event object for UI display
  /// This creates a "flattened" event that looks like a regular event
  Event toEvent() {
    return Event(
      // Use master event's ID with a special marker for virtual instances
      // This helps identify it's a virtual instance in the UI
      id: masterEvent.id,

      // Use effective values (considers exceptions)
      title: effectiveTitle,
      description: effectiveDescription,
      eventDate: effectiveDate,
      eventTime: effectiveTime,
      location: effectiveLocation,

      // Keep master event properties
      isAllDay: masterEvent.isAllDay,
      category: masterEvent.category,
      colorCode: masterEvent.colorCode,
      priority: masterEvent.priority,
      tags: masterEvent.tags,
      notifications: masterEvent.notifications,

      // Status depends on exception
      status: isCompleted ? EventStatus.completed : EventStatus.pending,
      completedAt: completedAt,

      // Keep recurrence rule reference (so UI knows it's recurring)
      recurrenceRule: masterEvent.recurrenceRule,

      // Timestamps
      createdAt: masterEvent.createdAt,
      updatedAt: exception?.createdAt ?? masterEvent.updatedAt,
    );
  }

  /// Create a copy with updated exception
  EventInstance copyWith({
    Event? masterEvent,
    DateTime? occurrenceDate,
    DateTime? occurrenceTime,
    RecurringEventException? exception,
  }) {
    return EventInstance(
      masterEvent: masterEvent ?? this.masterEvent,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      occurrenceTime: occurrenceTime ?? this.occurrenceTime,
      exception: exception ?? this.exception,
    );
  }

  /// Check if this instance should be displayed
  /// (not deleted, and within valid date range)
  bool isValid() {
    return !isDeleted;
  }

  @override
  String toString() {
    return 'EventInstance('
        'masterEventId: ${masterEvent.id}, '
        'date: ${effectiveDate.toString()}, '
        'title: $effectiveTitle, '
        'isCompleted: $isCompleted, '
        'isModified: $isModified, '
        'isDeleted: $isDeleted'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventInstance &&
        other.masterEvent.id == masterEvent.id &&
        other.occurrenceDate == occurrenceDate;
  }

  @override
  int get hashCode => Object.hash(masterEvent.id, occurrenceDate);
}
