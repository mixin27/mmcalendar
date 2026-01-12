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
import '../../services/smart_notification_scheduler.dart';
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
  final SmartNotificationScheduler smartScheduler;

  StreamSubscription? _eventsSubscription;
  StreamSubscription<MonthChangedEvent>? _monthChangedSubscription;

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
    required this.smartScheduler,
  }) : super(UserEventsInitial()) {
    on<LoadAllEvents>(_onLoadAllEvents);
    on<LoadMoreEvents>(_onLoadMoreEvents);
    on<LoadEventsByDate>(_onLoadEventsByDate);
    on<LoadEventsByDateRange>(_onLoadEventsByDateRange);
    on<LoadUpcomingEvents>(_onLoadUpcomingEvents);
    on<SearchEventsEvent>(_onSearchEvents);
    on<RefreshEvents>(_onRefreshEvents);
    on<ToggleEventComplete>(_onToggleEventComplete);
    on<DeleteEventEvent>(_onDeleteEvent);

    // Recurring instance events
    on<CompleteRecurringInstanceEvent>(_onCompleteRecurringInstance);
    on<DeleteRecurringInstanceEvent>(_onDeleteRecurringInstance);
    on<ModifyRecurringInstanceEvent>(_onModifyRecurringInstance);

    on<StartWatchingEvents>(_onStartWatchingEvents);
    on<StartWatchingEventsByDateRange>(_onStartWatchingEventsByDateRange);
    on<StopWatchingEvents>(_onStopWatchingEvents);

    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    _monthChangedSubscription = AppEventBus.on<MonthChangedEvent>().listen((
      event,
    ) {
      final month = event.month;
      // Load events for the month (include a few days buffer for grid)
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      // Add a buffer for grid display (some days from prev/next month)
      final startDate = startOfMonth.subtract(const Duration(days: 7));
      final endDate = endOfMonth.add(const Duration(days: 7));

      add(LoadEventsByDateRange(startDate, endDate));
    });
  }

  // ...
  Future<void> _onLoadAllEvents(
    LoadAllEvents event,
    Emitter<UserEventsState> emit,
  ) async {
    emit(const EventsLoading());

    final now = DateTime.now();
    // Load past 30 days and future 90 days initially
    final startDate = now.subtract(const Duration(days: 30));
    final endDate = now.add(const Duration(days: 90));

    final result = await eventsRepository.getEventsByDateRange(
      startDate,
      endDate,
    );

    result.fold((failure) => emit(EventsError(failure)), (events) {
      // Sort by date and then time
      events.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
      emit(EventsLoaded(events, hasMore: true, endDate: endDate));
    });
  }

  Future<void> _onLoadMoreEvents(
    LoadMoreEvents event,
    Emitter<UserEventsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    // Load next 30 days
    final startDate = event.currentEndDate;
    final endDate = startDate.add(const Duration(days: 30));

    final result = await eventsRepository.getEventsByDateRange(
      startDate,
      endDate,
    );

    result.fold((failure) => emit(EventsError(failure)), (newEvents) {
      // Append new events to existing ones
      final allEvents = [...currentState.events, ...newEvents];
      allEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

      emit(
        EventsLoaded(
          allEvents,
          isWatching: currentState.isWatching,
          hasMore: endDate.year < 2100,
          endDate: endDate,
        ),
      );
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
    // log('UserEventsBloc: Loading events from ${event.startDate} to ${event.endDate}');
    emit(const EventsLoading());

    final result = await getEventsByDateRange(
      GetEventsByDateRangeParams(event.startDate, event.endDate),
    );

    result.fold((failure) => emit(EventsError(failure)), (events) {
      // Deduplicate using Set (Event extends Equatable)
      // This handles exact duplicates (same ID, same date/time)
      final uniqueEvents = events.toSet().toList();
      // Sort by date and time
      uniqueEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

      emit(EventsLoaded(uniqueEvents));
    });
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

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (_) => null)!;
      emit(EventsError(failure));
      emit(currentState);
      return;
    }

    // Cancel notifications for deleted event
    await smartScheduler.cancelEventNotifications(event.eventId);

    final updatedEvents = currentState.events
        .where((e) => e.id != event.eventId)
        .toList();

    emit(EventsOperationSuccess(updatedEvents, 'Event deleted'));
    emit(EventsLoaded(updatedEvents, isWatching: currentState.isWatching));
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

  Future<void> _onCompleteRecurringInstance(
    CompleteRecurringInstanceEvent event,
    Emitter<UserEventsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    emit(
      EventsOperationInProgress(currentState.events, 'Completing instance...'),
    );

    final result = await eventsRepository.completeRecurringInstance(
      event.masterEventId,
      event.occurrenceDate,
    );

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (_) => null)!;
      emit(EventsError(failure));
      emit(currentState);
      return;
    }

    // Update notifications after completing instance
    await smartScheduler.onRecurringInstanceCompleted(
      masterEventId: event.masterEventId,
      occurrenceDate: event.occurrenceDate,
    );

    // Reload events to show updated state
    add(const RefreshEvents());

    emit(EventsOperationSuccess(currentState.events, 'Instance completed'));
  }

  Future<void> _onDeleteRecurringInstance(
    DeleteRecurringInstanceEvent event,
    Emitter<UserEventsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    emit(
      EventsOperationInProgress(currentState.events, 'Deleting instance...'),
    );

    final result = await eventsRepository.deleteRecurringInstance(
      event.masterEventId,
      event.occurrenceDate,
    );

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (_) => null)!;
      emit(EventsError(failure));
      emit(currentState);
      return;
    }

    // Update notifications after deleting instance
    await smartScheduler.onRecurringInstanceDeleted(
      masterEventId: event.masterEventId,
      occurrenceDate: event.occurrenceDate,
    );

    // Reload events to show updated state
    add(const RefreshEvents());

    emit(EventsOperationSuccess(currentState.events, 'Instance deleted'));
  }

  Future<void> _onModifyRecurringInstance(
    ModifyRecurringInstanceEvent event,
    Emitter<UserEventsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    emit(
      EventsOperationInProgress(currentState.events, 'Modifying instance...'),
    );

    final result = await eventsRepository.modifyRecurringInstance(
      masterEventId: event.masterEventId,
      occurrenceDate: event.occurrenceDate,
      modifiedTitle: event.modifiedTitle,
      modifiedDescription: event.modifiedDescription,
      modifiedDate: event.modifiedDate,
      modifiedTime: event.modifiedTime,
      modifiedLocation: event.modifiedLocation,
    );

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (_) => null)!;
      emit(EventsError(failure));
      emit(currentState);
      return;
    }

    // Update notifications after modifying instance
    await smartScheduler.onRecurringInstanceModified(
      masterEventId: event.masterEventId,
      occurrenceDate: event.occurrenceDate,
    );

    // Reload events to show updated state
    add(const RefreshEvents());

    emit(EventsOperationSuccess(currentState.events, 'Instance modified'));
  }

  @override
  Future<void> close() {
    _eventsSubscription?.cancel();
    _monthChangedSubscription?.cancel();
    return super.close();
  }
}
