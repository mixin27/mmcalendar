import 'package:equatable/equatable.dart';

import '../../domain/entities/event.dart';

sealed class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
final class EventsInitial extends EventsState {
  const EventsInitial();
}

/// Loading state
final class EventsLoading extends EventsState {
  const EventsLoading();
}

/// Events loaded successfully
final class EventsLoaded extends EventsState {
  final List<Event> events;
  final List<EventCategory> categories;
  final DateTime? currentDate;
  final String? currentCategory;

  const EventsLoaded({
    required this.events,
    this.categories = const [],
    this.currentDate,
    this.currentCategory,
  });

  @override
  List<Object?> get props => [events, categories, currentDate, currentCategory];

  /// Group events by date
  Map<DateTime, List<Event>> get groupedByDate {
    final Map<DateTime, List<Event>> grouped = {};
    for (final event in events) {
      final dateKey = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(event);
    }
    return grouped;
  }

  /// Get events for today
  List<Event> get todayEvents {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    return groupedByDate[todayKey] ?? [];
  }

  /// Get upcoming events (next 7 days)
  List<Event> get upcomingEvents {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    return events.where((event) {
      return event.eventDate.isAfter(now) &&
          event.eventDate.isBefore(sevenDaysLater);
    }).toList()..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  /// Get completed events
  List<Event> get completedEvents {
    return events.where((e) => e.isCompleted).toList();
  }

  /// Get pending events
  List<Event> get pendingEvents {
    return events.where((e) => !e.isCompleted).toList();
  }

  /// Copy with
  EventsLoaded copyWith({
    List<Event>? events,
    List<EventCategory>? categories,
    DateTime? currentDate,
    String? currentCategory,
  }) {
    return EventsLoaded(
      events: events ?? this.events,
      categories: categories ?? this.categories,
      currentDate: currentDate ?? this.currentDate,
      currentCategory: currentCategory ?? this.currentCategory,
    );
  }
}

/// Single event loaded
final class EventDetailLoaded extends EventsState {
  final Event event;
  final List<EventCategory> categories;

  const EventDetailLoaded({required this.event, this.categories = const []});

  @override
  List<Object?> get props => [event, categories];
}

/// Event created successfully
final class EventCreated extends EventsState {
  final Event event;

  const EventCreated(this.event);

  @override
  List<Object?> get props => [event];
}

/// Event updated successfully
final class EventUpdated extends EventsState {
  final Event event;

  const EventUpdated(this.event);

  @override
  List<Object?> get props => [event];
}

/// Event deleted successfully
final class EventDeleted extends EventsState {
  final int eventId;

  const EventDeleted(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

/// Categories loaded
final class CategoriesLoaded extends EventsState {
  final List<EventCategory> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

/// Category created
final class CategoryCreated extends EventsState {
  final EventCategory category;

  const CategoryCreated(this.category);

  @override
  List<Object?> get props => [category];
}

/// Category deleted
final class CategoryDeleted extends EventsState {
  final int categoryId;

  const CategoryDeleted(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// Error state
final class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Empty state
final class EventsEmpty extends EventsState {
  final String message;

  const EventsEmpty([this.message = 'No events found']);

  @override
  List<Object?> get props => [message];
}
