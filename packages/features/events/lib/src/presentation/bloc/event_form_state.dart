import 'package:shared_core/shared_core.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/notification_setting.dart';
import '../../domain/entities/recurrence_rule.dart';

sealed class EventFormState extends Equatable {
  const EventFormState();

  @override
  List<Object?> get props => [];
}

final class EventFormInitial extends EventFormState {}

/// Form editing state
final class EventFormEditing extends EventFormState {
  static const Object _noChange = Object();

  final int? eventId;
  final String title;
  final String description;
  final DateTime eventDate;
  final DateTime? eventTime;
  final bool isAllDay;
  final EventCategory category;
  final int? colorCode;
  final RecurrenceRule? recurrenceRule;

  /// For a new weekly event, each weekday's own time; empty when every day
  /// uses [eventTime].
  final Map<int, DateTime> dayTimes;
  final List<NotificationSetting> notifications;
  final String location;
  final EventPriority priority;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isValid;
  final String? errorMessage;

  const EventFormEditing({
    this.eventId,
    required this.title,
    required this.description,
    required this.eventDate,
    this.eventTime,
    required this.isAllDay,
    required this.category,
    this.colorCode,
    this.recurrenceRule,
    this.dayTimes = const {},
    required this.notifications,
    required this.location,
    required this.priority,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.isValid = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    eventId,
    title,
    description,
    eventDate,
    eventTime,
    isAllDay,
    category,
    colorCode,
    recurrenceRule,
    dayTimes,
    notifications,
    location,
    priority,
    tags,
    createdAt,
    updatedAt,
    isValid,
    errorMessage,
  ];

  EventFormEditing copyWith({
    int? eventId,
    String? title,
    String? description,
    DateTime? eventDate,
    DateTime? eventTime,
    bool? isAllDay,
    EventCategory? category,
    int? colorCode,
    Object? recurrenceRule = _noChange,
    Map<int, DateTime>? dayTimes,
    List<NotificationSetting>? notifications,
    String? location,
    EventPriority? priority,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isValid,
    Object? errorMessage = _noChange,
  }) {
    return EventFormEditing(
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      isAllDay: isAllDay ?? this.isAllDay,
      category: category ?? this.category,
      colorCode: colorCode ?? this.colorCode,
      // "Never" clears the repeat, so null is a value here.
      recurrenceRule: identical(recurrenceRule, _noChange)
          ? this.recurrenceRule
          : recurrenceRule as RecurrenceRule?,
      dayTimes: dayTimes ?? this.dayTimes,
      notifications: notifications ?? this.notifications,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isValid: isValid ?? this.isValid,
      errorMessage: identical(errorMessage, _noChange)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  Event toEvent() {
    return Event(
      id: eventId,
      title: title,
      description: description.isEmpty ? null : description,
      eventDate: eventDate,
      eventTime: eventTime,
      isAllDay: isAllDay,
      category: category,
      colorCode: colorCode,
      recurrenceRule: recurrenceRule,
      notifications: notifications,
      location: location.isEmpty ? null : location,
      priority: priority,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Form submitting state
final class EventFormSubmitting extends EventFormState {
  const EventFormSubmitting();
}

/// Form submitted successfully
final class EventFormSuccess extends EventFormState {
  final Event event;
  final bool isNew;

  /// How many events the save created: more than one when a timetable's
  /// days have different times.
  final int count;

  const EventFormSuccess(this.event, {this.isNew = true, this.count = 1});

  @override
  List<Object?> get props => [event, isNew, count];
}

/// Form submission failed
final class EventFormError extends EventFormState {
  final Failure failure;

  const EventFormError(this.failure);

  @override
  List<Object?> get props => [failure];
}
