import 'package:equatable/equatable.dart';

import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/notification_setting.dart';
import '../../domain/entities/recurrence_rule.dart';

sealed class EventFormEvent extends Equatable {
  const EventFormEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize form for creating new event
final class InitializeNewEvent extends EventFormEvent {
  final DateTime? initialDate;

  const InitializeNewEvent({this.initialDate});

  @override
  List<Object?> get props => [initialDate];
}

/// Initialize form for editing existing event
final class InitializeEditEvent extends EventFormEvent {
  final Event event;

  const InitializeEditEvent(this.event);

  @override
  List<Object?> get props => [event];
}

/// Update event title
final class UpdateEventTitle extends EventFormEvent {
  final String title;

  const UpdateEventTitle(this.title);

  @override
  List<Object?> get props => [title];
}

/// Update event description
final class UpdateEventDescription extends EventFormEvent {
  final String description;

  const UpdateEventDescription(this.description);

  @override
  List<Object?> get props => [description];
}

/// Update event date
final class UpdateEventDate extends EventFormEvent {
  final DateTime date;

  const UpdateEventDate(this.date);

  @override
  List<Object?> get props => [date];
}

/// Update event time
final class UpdateEventTime extends EventFormEvent {
  final DateTime? time;

  const UpdateEventTime(this.time);

  @override
  List<Object?> get props => [time];
}

/// Toggle all-day event
final class ToggleAllDay extends EventFormEvent {
  const ToggleAllDay();
}

/// Update event category
final class UpdateEventCategory extends EventFormEvent {
  final EventCategory category;

  const UpdateEventCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Update event color
final class UpdateEventColor extends EventFormEvent {
  final int? colorCode;

  const UpdateEventColor(this.colorCode);

  @override
  List<Object?> get props => [colorCode];
}

/// Update event location
final class UpdateEventLocation extends EventFormEvent {
  final String location;

  const UpdateEventLocation(this.location);

  @override
  List<Object?> get props => [location];
}

/// Update event priority
final class UpdateEventPriority extends EventFormEvent {
  final EventPriority priority;

  const UpdateEventPriority(this.priority);

  @override
  List<Object?> get props => [priority];
}

/// Update recurrence rule
final class UpdateRecurrenceRule extends EventFormEvent {
  final RecurrenceRule? rule;

  const UpdateRecurrenceRule(this.rule);

  @override
  List<Object?> get props => [rule];
}

/// Add notification
final class AddNotification extends EventFormEvent {
  final NotificationSetting notification;

  const AddNotification(this.notification);

  @override
  List<Object?> get props => [notification];
}

/// Remove notification
final class RemoveNotification extends EventFormEvent {
  final int index;

  const RemoveNotification(this.index);

  @override
  List<Object?> get props => [index];
}

/// Add tag
final class AddTag extends EventFormEvent {
  final String tag;

  const AddTag(this.tag);

  @override
  List<Object?> get props => [tag];
}

/// Remove tag
final class RemoveTag extends EventFormEvent {
  final String tag;

  const RemoveTag(this.tag);

  @override
  List<Object?> get props => [tag];
}

/// Submit form (create or update)
final class SubmitEventForm extends EventFormEvent {
  const SubmitEventForm();
}

/// Reset form
final class ResetEventForm extends EventFormEvent {
  const ResetEventForm();
}
