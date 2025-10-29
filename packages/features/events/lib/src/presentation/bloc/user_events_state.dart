import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/event.dart';

sealed class UserEventsState extends Equatable {
  const UserEventsState();

  @override
  List<Object?> get props => [];
}

final class UserEventsInitial extends UserEventsState {
  const UserEventsInitial();
}

/// Loading state
final class EventsLoading extends UserEventsState {
  const EventsLoading();
}

/// Loaded state with events
final class EventsLoaded extends UserEventsState {
  final List<Event> events;
  final bool isWatching;

  const EventsLoaded(this.events, {this.isWatching = false});

  @override
  List<Object?> get props => [events, isWatching];

  EventsLoaded copyWith({List<Event>? events, bool? isWatching}) {
    return EventsLoaded(
      events ?? this.events,
      isWatching: isWatching ?? this.isWatching,
    );
  }
}

/// Error state
final class EventsError extends UserEventsState {
  final Failure failure;

  const EventsError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Operation in progress state (for delete, toggle, etc.)
final class EventsOperationInProgress extends UserEventsState {
  final List<Event> currentEvents;
  final String operation;

  const EventsOperationInProgress(this.currentEvents, this.operation);

  @override
  List<Object?> get props => [currentEvents, operation];
}

/// Operation success state
final class EventsOperationSuccess extends UserEventsState {
  final List<Event> events;
  final String message;

  const EventsOperationSuccess(this.events, this.message);

  @override
  List<Object?> get props => [events, message];
}
