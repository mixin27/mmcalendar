import 'package:equatable/equatable.dart';

import 'event_category.dart';
import 'notification_setting.dart';
import 'recurrence_rule.dart';

/// Core event entity representing a calendar event
class Event extends Equatable {
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
    int? id,
    String? title,
    String? description,
    DateTime? eventDate,
    DateTime? eventTime,
    bool? isAllDay,
    EventCategory? category,
    int? colorCode,
    RecurrenceRule? recurrenceRule,
    List<NotificationSetting>? notifications,
    String? location,
    EventStatus? status,
    EventPriority? priority,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      isAllDay: isAllDay ?? this.isAllDay,
      category: category ?? this.category,
      colorCode: colorCode ?? this.colorCode,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      notifications: notifications ?? this.notifications,
      location: location ?? this.location,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
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
