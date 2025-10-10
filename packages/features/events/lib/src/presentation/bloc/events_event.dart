import 'package:equatable/equatable.dart';

sealed class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

final class LoadAllEvents extends EventsEvent {
  const LoadAllEvents();
}

/// Load events for a specific date
final class LoadEventsByDate extends EventsEvent {
  final DateTime date;

  const LoadEventsByDate(this.date);

  @override
  List<Object?> get props => [date];
}

/// Load events within a date range
final class LoadEventsByDateRange extends EventsEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadEventsByDateRange({required this.startDate, required this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Load events by category
final class LoadEventsByCategory extends EventsEvent {
  final String category;

  const LoadEventsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Load a single event by ID
final class LoadEventById extends EventsEvent {
  final int eventId;

  const LoadEventById(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

/// Create a new event
final class CreateEvent extends EventsEvent {
  final String title;
  final String? description;
  final DateTime eventDate;
  final DateTime? eventTime;
  final bool isAllDay;
  final String category;
  final int? categoryId;
  final int? colorCode;
  final String? location;
  final int priority;
  final List<String>? tags;

  const CreateEvent({
    required this.title,
    this.description,
    required this.eventDate,
    this.eventTime,
    this.isAllDay = true,
    required this.category,
    this.categoryId,
    this.colorCode,
    this.location,
    this.priority = 0,
    this.tags,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    eventDate,
    eventTime,
    isAllDay,
    category,
    categoryId,
    colorCode,
    location,
    priority,
    tags,
  ];
}

/// Update an existing event
final class UpdateEvent extends EventsEvent {
  final int eventId;
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

  const UpdateEvent({
    required this.eventId,
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

  @override
  List<Object?> get props => [
    eventId,
    title,
    description,
    eventDate,
    eventTime,
    isAllDay,
    category,
    categoryId,
    colorCode,
    location,
    priority,
  ];
}

/// Delete an event
final class DeleteEvent extends EventsEvent {
  final int eventId;

  const DeleteEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

/// Toggle event completion status
final class ToggleEventComplete extends EventsEvent {
  final int eventId;

  const ToggleEventComplete(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

/// Watch all events (stream)
final class WatchAllEvents extends EventsEvent {
  const WatchAllEvents();
}

/// Watch a single event by ID (stream)
final class WatchEventById extends EventsEvent {
  final int eventId;

  const WatchEventById(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

/// Refresh events (force reload)
final class RefreshEvents extends EventsEvent {
  const RefreshEvents();
}

/// Load categories
final class LoadCategories extends EventsEvent {
  const LoadCategories();
}

/// Create a new category
final class CreateCategory extends EventsEvent {
  final String name;
  final String iconName;
  final int colorCode;
  final int sortOrder;

  const CreateCategory({
    required this.name,
    required this.iconName,
    required this.colorCode,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [name, iconName, colorCode, sortOrder];
}

/// Delete a category
final class DeleteCategory extends EventsEvent {
  final int categoryId;

  const DeleteCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

final class InitializeDefaultCategories extends EventsEvent {
  const InitializeDefaultCategories();
}
