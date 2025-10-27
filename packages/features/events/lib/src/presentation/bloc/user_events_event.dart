import 'package:equatable/equatable.dart';

sealed class UserEventsEvent extends Equatable {
  const UserEventsEvent();

  @override
  List<Object?> get props => [];
}

/// Load all events
final class LoadAllEvents extends UserEventsEvent {
  final bool includeCompleted;

  const LoadAllEvents({this.includeCompleted = false});

  @override
  List<Object?> get props => [includeCompleted];
}

/// Load events by date
final class LoadEventsByDate extends UserEventsEvent {
  final DateTime date;

  const LoadEventsByDate(this.date);

  @override
  List<Object?> get props => [date];
}

/// Load events by date range
final class LoadEventsByDateRange extends UserEventsEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadEventsByDateRange(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Load upcoming events
final class LoadUpcomingEvents extends UserEventsEvent {
  final int days;

  const LoadUpcomingEvents({this.days = 7});

  @override
  List<Object?> get props => [days];
}

/// Search events
final class SearchEventsEvent extends UserEventsEvent {
  final String query;

  const SearchEventsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Refresh events
final class RefreshEvents extends UserEventsEvent {
  final bool includeCompleted;

  const RefreshEvents({this.includeCompleted = false});

  @override
  List<Object?> get props => [includeCompleted];
}

/// Toggle event completion
final class ToggleEventComplete extends UserEventsEvent {
  final int eventId;
  final bool isCompleted;

  const ToggleEventComplete(this.eventId, this.isCompleted);

  @override
  List<Object?> get props => [eventId, isCompleted];
}

/// Delete event
final class DeleteEventEvent extends UserEventsEvent {
  final int eventId;

  const DeleteEventEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

/// Start watching events
final class StartWatchingEvents extends UserEventsEvent {
  const StartWatchingEvents();
}

/// Start watching events by date range
final class StartWatchingEventsByDateRange extends UserEventsEvent {
  final DateTime startDate;
  final DateTime endDate;

  const StartWatchingEventsByDateRange(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Stop watching events
final class StopWatchingEvents extends UserEventsEvent {
  const StopWatchingEvents();
}
