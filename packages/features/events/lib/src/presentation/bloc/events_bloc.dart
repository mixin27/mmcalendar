import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/usecases/create_category.dart' as create_cat_uc;
import '../../domain/usecases/create_event.dart' as create_ev_uc;
import '../../domain/usecases/delete_category.dart' as delete_cat_uc;
import '../../domain/usecases/delete_event.dart' as delete_ev_uc;
import '../../domain/usecases/get_all_categories.dart';
import '../../domain/usecases/get_all_events.dart';
import '../../domain/usecases/get_event_by_id.dart';
import '../../domain/usecases/get_events_by_category.dart';
import '../../domain/usecases/get_events_by_date.dart';
import '../../domain/usecases/get_events_by_date_range.dart';
import '../../domain/usecases/initialize_default_categories.dart'
    as init_def_cat_uc;
import '../../domain/usecases/toggle_event_complete.dart'
    as toggle_ev_complete_uc;
import '../../domain/usecases/update_event.dart' as update_ev_uc;
import '../../domain/usecases/watch_all_events.dart' as watch_ev_uc;
import '../../domain/usecases/watch_event_by_id.dart' as watch_ev_id_uc;
import 'events_event.dart';
import 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  // Use Cases
  final GetAllEvents getAllEvents;
  final GetEventsByDate getEventsByDate;
  final GetEventsByDateRange getEventsByDateRange;
  final GetEventsByCategory getEventsByCategory;
  final GetEventById getEventById;
  final create_ev_uc.CreateEvent createEvent;
  final update_ev_uc.UpdateEvent updateEvent;
  final delete_ev_uc.DeleteEvent deleteEvent;
  final toggle_ev_complete_uc.ToggleEventComplete toggleEventComplete;
  final GetAllCategories getAllCategories;
  final create_cat_uc.CreateCategory createCategory;
  final delete_cat_uc.DeleteCategory deleteCategory;
  final watch_ev_uc.WatchAllEvents watchAllEvents;
  final watch_ev_id_uc.WatchEventById watchEventById;
  final init_def_cat_uc.InitializeDefaultCategories initializeDefaultCategories;

  StreamSubscription? _eventsSubscription;
  // StreamSubscription? _eventBusSubscription;

  EventsBloc({
    required this.getAllEvents,
    required this.getEventsByDate,
    required this.getEventsByDateRange,
    required this.getEventsByCategory,
    required this.getEventById,
    required this.createEvent,
    required this.updateEvent,
    required this.deleteEvent,
    required this.toggleEventComplete,
    required this.getAllCategories,
    required this.createCategory,
    required this.deleteCategory,
    required this.watchAllEvents,
    required this.watchEventById,
    required this.initializeDefaultCategories,
  }) : super(EventsInitial()) {
    // Register event handlers
    on<LoadAllEvents>(_onLoadAllEvents);
    on<LoadEventsByDate>(_onLoadEventsByDate);
    on<LoadEventsByDateRange>(_onLoadEventsByDateRange);
    on<LoadEventsByCategory>(_onLoadEventsByCategory);
    on<LoadEventById>(_onLoadEventById);
    on<CreateEvent>(_onCreateEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<DeleteEvent>(_onDeleteEvent);
    on<ToggleEventComplete>(_onToggleEventComplete);
    on<WatchAllEvents>(_onWatchAllEvents);
    on<WatchEventById>(_onWatchEventById);
    on<RefreshEvents>(_onRefreshEvents);
    on<LoadCategories>(_onLoadCategories);
    on<CreateCategory>(_onCreateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<InitializeDefaultCategories>(_onInitializeDefaultCategories);

    // Listen to event bus for cross-feature communication
    _listenToEventBus();
  }

  void _listenToEventBus() {
    _eventsSubscription = watchAllEvents(null).listen((_) {
      add(const RefreshEvents());
    });

    // _eventBusSubscription = AppEventBus.on<EventCreatedEvent>().listen((event) {
    //   add(const RefreshEvents());
    // });

    // AppEventBus.on<EventUpdatedEvent>().listen((event) {
    //   add(const RefreshEvents());
    // });

    // AppEventBus.on<EventDeletedEvent>().listen((event) {
    //   add(const RefreshEvents());
    // });
  }

  Future<void> _onLoadAllEvents(
    LoadAllEvents event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await getAllEvents();
    final categoriesResult = await getAllCategories();

    result.fold((failure) => emit(EventsError(failure.message)), (events) {
      if (events.isEmpty) {
        emit(const EventsEmpty('No events found'));
      } else {
        categoriesResult.fold(
          (failure) => emit(EventsLoaded(events: events)),
          (categories) =>
              emit(EventsLoaded(events: events, categories: categories)),
        );
      }
    });
  }

  Future<void> _onLoadEventsByDate(
    LoadEventsByDate event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await getEventsByDate(event.date);
    final categoriesResult = await getAllCategories();

    result.fold((failure) => emit(EventsError(failure.message)), (events) {
      if (events.isEmpty) {
        emit(EventsEmpty('No events on ${_formatDate(event.date)}'));
      } else {
        categoriesResult.fold(
          (failure) =>
              emit(EventsLoaded(events: events, currentDate: event.date)),
          (categories) => emit(
            EventsLoaded(
              events: events,
              categories: categories,
              currentDate: event.date,
            ),
          ),
        );
      }
    });
  }

  Future<void> _onLoadEventsByDateRange(
    LoadEventsByDateRange event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final params = GetEventsByDateRangeParams(
      startDate: event.startDate,
      endDate: event.endDate,
    );

    final result = await getEventsByDateRange(params);
    final categoriesResult = await getAllCategories();

    result.fold((failure) => emit(EventsError(failure.message)), (events) {
      if (events.isEmpty) {
        emit(const EventsEmpty('No events in selected date range'));
      } else {
        categoriesResult.fold(
          (failure) => emit(EventsLoaded(events: events)),
          (categories) =>
              emit(EventsLoaded(events: events, categories: categories)),
        );
      }
    });
  }

  Future<void> _onLoadEventsByCategory(
    LoadEventsByCategory event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await getEventsByCategory(event.category);
    final categoriesResult = await getAllCategories();

    result.fold((failure) => emit(EventsError(failure.message)), (events) {
      if (events.isEmpty) {
        emit(EventsEmpty('No events in ${event.category} category'));
      } else {
        categoriesResult.fold(
          (failure) => emit(
            EventsLoaded(events: events, currentCategory: event.category),
          ),
          (categories) => emit(
            EventsLoaded(
              events: events,
              categories: categories,
              currentCategory: event.category,
            ),
          ),
        );
      }
    });
  }

  Future<void> _onLoadEventById(
    LoadEventById event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await getEventById(event.eventId);
    final categoriesResult = await getAllCategories();

    result.fold((failure) => emit(EventsError(failure.message)), (event) {
      categoriesResult.fold(
        (failure) => emit(EventDetailLoaded(event: event)),
        (categories) =>
            emit(EventDetailLoaded(event: event, categories: categories)),
      );
    });
  }

  Future<void> _onCreateEvent(
    CreateEvent event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final params = create_ev_uc.CreateEventParams(
      title: event.title,
      description: event.description,
      eventDate: event.eventDate,
      eventTime: event.eventTime,
      isAllDay: event.isAllDay,
      category: event.category,
      categoryId: event.categoryId,
      colorCode: event.colorCode,
      location: event.location,
      priority: event.priority,
      tags: event.tags,
    );

    final result = await createEvent(params);

    result.fold((failure) => emit(EventsError(failure.message)), (newEvent) {
      emit(EventCreated(newEvent));
      // Reload all events
      add(const LoadAllEvents());
    });
  }

  Future<void> _onUpdateEvent(
    UpdateEvent event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final params = update_ev_uc.UpdateEventParams(
      id: event.eventId,
      title: event.title,
      description: event.description,
      eventDate: event.eventDate,
      eventTime: event.eventTime,
      isAllDay: event.isAllDay,
      category: event.category,
      categoryId: event.categoryId,
      colorCode: event.colorCode,
      location: event.location,
      priority: event.priority,
    );

    final result = await updateEvent(params);

    result.fold((failure) => emit(EventsError(failure.message)), (
      updatedEvent,
    ) {
      emit(EventUpdated(updatedEvent));
      // Reload all events
      add(const LoadAllEvents());
    });
  }

  Future<void> _onDeleteEvent(
    DeleteEvent event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await deleteEvent(event.eventId);

    result.fold((failure) => emit(EventsError(failure.message)), (_) {
      emit(EventDeleted(event.eventId));
      // Reload all events
      add(const LoadAllEvents());
    });
  }

  Future<void> _onToggleEventComplete(
    ToggleEventComplete event,
    Emitter<EventsState> emit,
  ) async {
    final result = await toggleEventComplete(event.eventId);

    result.fold((failure) => emit(EventsError(failure.message)), (
      updatedEvent,
    ) {
      emit(EventUpdated(updatedEvent));
      // Reload all events
      add(const LoadAllEvents());
    });
  }

  Future<void> _onWatchAllEvents(
    WatchAllEvents event,
    Emitter<EventsState> emit,
  ) async {
    await _eventsSubscription?.cancel();

    emit(const EventsLoading());

    final categoriesResult = await getAllCategories();

    _eventsSubscription = watchAllEvents(null).listen(
      (result) {
        result.fold((failure) => emit(EventsError(failure.message)), (events) {
          if (events.isEmpty) {
            emit(const EventsEmpty('No events found'));
          } else {
            categoriesResult.fold(
              (failure) => emit(EventsLoaded(events: events)),
              (categories) =>
                  emit(EventsLoaded(events: events, categories: categories)),
            );
          }
        });
      },
      onError: (error) {
        emit(EventsError('Stream error: ${error.toString()}'));
      },
    );
  }

  Future<void> _onWatchEventById(
    WatchEventById event,
    Emitter<EventsState> emit,
  ) async {
    await _eventsSubscription?.cancel();

    emit(const EventsLoading());

    final categoriesResult = await getAllCategories();

    _eventsSubscription = watchEventById(event.eventId).listen(
      (result) {
        result.fold((failure) => emit(EventsError(failure.message)), (event) {
          categoriesResult.fold(
            (failure) => emit(EventDetailLoaded(event: event)),
            (categories) =>
                emit(EventDetailLoaded(event: event, categories: categories)),
          );
        });
      },
      onError: (error) {
        emit(EventsError('Stream error: ${error.toString()}'));
      },
    );
  }

  Future<void> _onRefreshEvents(
    RefreshEvents event,
    Emitter<EventsState> emit,
  ) async {
    // If we have a current state with filters, maintain them
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;

      if (currentState.currentDate != null) {
        add(LoadEventsByDate(currentState.currentDate!));
      } else if (currentState.currentCategory != null) {
        add(LoadEventsByCategory(currentState.currentCategory!));
      } else {
        add(const LoadAllEvents());
      }
    } else {
      add(const LoadAllEvents());
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<EventsState> emit,
  ) async {
    // emit(const EventsLoading());

    final result = await getAllCategories();

    result.fold((failure) => emit(EventsError(failure.message)), (categories) {
      if (categories.isEmpty) {
        emit(const EventsEmpty('No categories found'));
      } else {
        emit(CategoriesLoaded(categories));
      }
    });
  }

  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await createCategory(
      create_cat_uc.CreateCategoryParams(
        name: event.name,
        iconName: event.iconName,
        colorCode: event.colorCode,
        sortOrder: event.sortOrder,
      ),
    );

    result.fold((failure) => emit(EventsError(failure.message)), (category) {
      emit(CategoryCreated(category));
      // Reload categories
      add(const LoadCategories());
    });
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await deleteCategory(event.categoryId);

    result.fold((failure) => emit(EventsError(failure.message)), (_) {
      emit(CategoryDeleted(event.categoryId));
      // Reload categories
      add(const LoadCategories());
    });
  }

  Future<void> _onInitializeDefaultCategories(
    InitializeDefaultCategories event,
    Emitter<EventsState> emit,
  ) async {
    final result = await initializeDefaultCategories(null);
    result.fold((failure) => emit(EventsError(failure.message)), (_) {});
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> close() {
    _eventsSubscription?.cancel();
    // _eventBusSubscription?.cancel();
    return super.close();
  }
}
