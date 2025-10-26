import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';

import '../../domain/repositories/events_repository.dart';
import '../../domain/usecases/delete_user_event.dart';
import '../../domain/usecases/get_events_by_date.dart';
import '../../domain/usecases/get_events_by_date_range.dart';
import '../../domain/usecases/get_upcoming_events.dart';
import '../../domain/usecases/search_user_events.dart';
import '../../domain/usecases/toggle_event_completion.dart';
import '../../domain/usecases/watch_user_events.dart';
import 'user_events_event.dart';
import 'user_events_state.dart';

class UserEventsBloc extends Bloc<UserEventsEvent, UserEventsState> {
  final GetEventsByDate getEventsByDate;
  final GetEventsByDateRange getEventsByDateRange;
  final GetUpcomingEvents getUpcomingEvents;
  final SearchUserEvents searchEvents;
  final ToggleEventCompletion toggleEventCompletion;
  final DeleteUserEvent deleteEvent;
  final WatchUserEvents watchEvents;
  final WatchEventsByDateRange watchEventsByDateRange;
  final EventsRepository eventsRepository;

  StreamSubscription? _eventsSubscription;

  UserEventsBloc({
    required this.getEventsByDate,
    required this.getEventsByDateRange,
    required this.getUpcomingEvents,
    required this.searchEvents,
    required this.toggleEventCompletion,
    required this.deleteEvent,
    required this.watchEvents,
    required this.watchEventsByDateRange,
    required this.eventsRepository,
  }) : super(UserEventsInitial()) {
    on<LoadAllEvents>(_onLoadAllEvents);
    on<LoadEventsByDate>(_onLoadEventsByDate);
    on<LoadEventsByDateRange>(_onLoadEventsByDateRange);
    on<LoadUpcomingEvents>(_onLoadUpcomingEvents);
    on<SearchEventsEvent>(_onSearchEvents);
    on<RefreshEvents>(_onRefreshEvents);
    on<ToggleEventComplete>(_onToggleEventComplete);
    on<DeleteEventEvent>(_onDeleteEvent);
    on<StartWatchingEvents>(_onStartWatchingEvents);
    on<StartWatchingEventsByDateRange>(_onStartWatchingEventsByDateRange);
    on<StopWatchingEvents>(_onStopWatchingEvents);
  }

  Future<void> _onLoadAllEvents(
    LoadAllEvents event,
    Emitter<UserEventsState> emit,
  ) async {
    emit(const EventsLoading());

    // Get ALL events (not just upcoming)
    final result = await eventsRepository.getAllEvents();

    result.fold((failure) => emit(EventsError(failure)), (events) {
      // Sort by date
      events.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
      emit(EventsLoaded(events));
    });
  }

  Future<void> _onLoadEventsByDate(
    LoadEventsByDate event,
    Emitter<UserEventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await getEventsByDate(GetEventsByDateParams(event.date));

    result.fold(
      (failure) => emit(EventsError(failure)),
      (events) => emit(EventsLoaded(events)),
    );
  }

  Future<void> _onLoadEventsByDateRange(
    LoadEventsByDateRange event,
    Emitter<UserEventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await getEventsByDateRange(
      GetEventsByDateRangeParams(event.startDate, event.endDate),
    );

    result.fold(
      (failure) => emit(EventsError(failure)),
      (events) => emit(EventsLoaded(events)),
    );
  }

  Future<void> _onLoadUpcomingEvents(
    LoadUpcomingEvents event,
    Emitter<UserEventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await getUpcomingEvents(
      GetUpcomingEventsParams(days: event.days),
    );

    result.fold(
      (failure) => emit(EventsError(failure)),
      (events) => emit(EventsLoaded(events)),
    );
  }

  Future<void> _onSearchEvents(
    SearchEventsEvent event,
    Emitter<UserEventsState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      add(const LoadAllEvents());
      return;
    }

    emit(const EventsLoading());

    final result = await searchEvents(SearchUserEventsParams(event.query));

    result.fold(
      (failure) => emit(EventsError(failure)),
      (events) => emit(EventsLoaded(events)),
    );
  }

  Future<void> _onRefreshEvents(
    RefreshEvents event,
    Emitter<UserEventsState> emit,
  ) async {
    // Reload all events
    add(const LoadAllEvents());
  }

  Future<void> _onToggleEventComplete(
    ToggleEventComplete event,
    Emitter<UserEventsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    emit(EventsOperationInProgress(currentState.events, 'Updating event...'));

    final result = await toggleEventCompletion(
      ToggleEventCompletionParams(event.eventId, event.isCompleted),
    );

    result.fold(
      (failure) {
        emit(EventsError(failure));
        emit(currentState);
      },
      (updatedEvent) {
        final updatedEvents = currentState.events.map((e) {
          return e.id == updatedEvent.id ? updatedEvent : e;
        }).toList();

        emit(
          EventsOperationSuccess(
            updatedEvents,
            event.isCompleted ? 'Event completed' : 'Event reopened',
          ),
        );
        emit(EventsLoaded(updatedEvents, isWatching: currentState.isWatching));
      },
    );
  }

  Future<void> _onDeleteEvent(
    DeleteEventEvent event,
    Emitter<UserEventsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    emit(EventsOperationInProgress(currentState.events, 'Deleting event...'));

    final result = await deleteEvent(DeleteUserEventParams(event.eventId));

    result.fold(
      (failure) {
        emit(EventsError(failure));
        emit(currentState);
      },
      (_) {
        final updatedEvents = currentState.events
            .where((e) => e.id != event.eventId)
            .toList();

        emit(EventsOperationSuccess(updatedEvents, 'Event deleted'));
        emit(EventsLoaded(updatedEvents, isWatching: currentState.isWatching));
      },
    );
  }

  Future<void> _onStartWatchingEvents(
    StartWatchingEvents event,
    Emitter<UserEventsState> emit,
  ) async {
    await _eventsSubscription?.cancel();

    emit(const EventsLoading());

    _eventsSubscription = watchEvents(NoParams()).listen((result) {
      result.fold((failure) => add(const StopWatchingEvents()), (events) {
        if (!isClosed) {
          emit(EventsLoaded(events, isWatching: true));
        }
      });
    });
  }

  Future<void> _onStartWatchingEventsByDateRange(
    StartWatchingEventsByDateRange event,
    Emitter<UserEventsState> emit,
  ) async {
    await _eventsSubscription?.cancel();

    emit(const EventsLoading());

    _eventsSubscription =
        watchEventsByDateRange(
          WatchEventsByDateRangeParams(event.startDate, event.endDate),
        ).listen((result) {
          result.fold((failure) => add(const StopWatchingEvents()), (events) {
            if (!isClosed) {
              emit(EventsLoaded(events, isWatching: true));
            }
          });
        });
  }

  Future<void> _onStopWatchingEvents(
    StopWatchingEvents event,
    Emitter<UserEventsState> emit,
  ) async {
    await _eventsSubscription?.cancel();
    _eventsSubscription = null;

    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;
      emit(EventsLoaded(currentState.events, isWatching: false));
    }
  }

  @override
  Future<void> close() {
    _eventsSubscription?.cancel();
    return super.close();
  }
}
