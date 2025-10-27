import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/notification_setting.dart';
import '../../domain/usecases/create_user_event.dart';
import '../../domain/usecases/get_event_by_id.dart';
import '../../domain/usecases/update_user_event.dart';
import '../../services/event_notification_manager.dart';
import 'event_form_event.dart';
import 'event_form_state.dart';

final getIt = GetIt.instance;

class EventFormBloc extends Bloc<EventFormEvent, EventFormState> {
  final CreateUserEvent createEvent;
  final UpdateUserEvent updateEvent;
  final GetEventById getEventById;

  EventFormBloc({
    required this.createEvent,
    required this.updateEvent,
    required this.getEventById,
  }) : super(EventFormInitial()) {
    on<InitializeNewEvent>(_onInitializeNewEvent);
    on<InitializeEditEvent>(_onInitializeEditEvent);
    on<LoadEventForEdit>(_onLoadEventForEdit);
    on<UpdateEventTitle>(_onUpdateEventTitle);
    on<UpdateEventDescription>(_onUpdateEventDescription);
    on<UpdateEventDate>(_onUpdateEventDate);
    on<UpdateEventTime>(_onUpdateEventTime);
    on<ToggleAllDay>(_onToggleAllDay);
    on<UpdateEventCategory>(_onUpdateEventCategory);
    on<UpdateEventColor>(_onUpdateEventColor);
    on<UpdateEventLocation>(_onUpdateEventLocation);
    on<UpdateEventPriority>(_onUpdateEventPriority);
    on<UpdateRecurrenceRule>(_onUpdateRecurrenceRule);
    on<AddNotification>(_onAddNotification);
    on<RemoveNotification>(_onRemoveNotification);
    on<AddTag>(_onAddTag);
    on<RemoveTag>(_onRemoveTag);
    on<SubmitEventForm>(_onSubmitEventForm);
    on<ResetEventForm>(_onResetEventForm);
  }

  void _onInitializeNewEvent(
    InitializeNewEvent event,
    Emitter<EventFormState> emit,
  ) {
    final now = DateTime.now();
    emit(
      EventFormEditing(
        title: '',
        description: '',
        eventDate: event.initialDate ?? now,
        eventTime: null,
        isAllDay: true,
        category: EventCategory.personal,
        notifications: [],
        location: '',
        priority: EventPriority.normal,
        tags: [],
        isValid: false,
      ),
    );
  }

  void _onInitializeEditEvent(
    InitializeEditEvent event,
    Emitter<EventFormState> emit,
  ) {
    final e = event.event;
    emit(
      EventFormEditing(
        eventId: e.id,
        title: e.title,
        description: e.description ?? '',
        eventDate: e.eventDate,
        eventTime: e.eventTime,
        isAllDay: e.isAllDay,
        category: e.category,
        colorCode: e.colorCode,
        recurrenceRule: e.recurrenceRule,
        notifications: List.from(e.notifications),
        location: e.location ?? '',
        priority: e.priority,
        tags: List.from(e.tags),
        isValid: true,
      ),
    );
  }

  // Load event by ID for editing
  Future<void> _onLoadEventForEdit(
    LoadEventForEdit event,
    Emitter<EventFormState> emit,
  ) async {
    emit(const EventFormSubmitting()); // Use as loading state

    final result = await getEventById(GetEventByIdParams(event.eventId));

    result.fold(
      (failure) {
        emit(EventFormError(failure));
        emit(EventFormInitial());
      },
      (loadedEvent) {
        // Initialize form with loaded event
        add(InitializeEditEvent(loadedEvent));
      },
    );
  }

  void _onUpdateEventTitle(
    UpdateEventTitle event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;

    final isValid = event.title.trim().isNotEmpty;
    emit(
      currentState.copyWith(
        title: event.title,
        isValid: isValid,
        errorMessage: isValid ? null : 'Title is required',
      ),
    );
  }

  void _onUpdateEventDescription(
    UpdateEventDescription event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(currentState.copyWith(description: event.description));
  }

  void _onUpdateEventDate(UpdateEventDate event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(currentState.copyWith(eventDate: event.date));
  }

  void _onUpdateEventTime(UpdateEventTime event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(currentState.copyWith(eventTime: event.time));
  }

  void _onToggleAllDay(ToggleAllDay event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(
      currentState.copyWith(
        isAllDay: !currentState.isAllDay,
        eventTime: !currentState.isAllDay ? null : currentState.eventTime,
      ),
    );
  }

  void _onUpdateEventCategory(
    UpdateEventCategory event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(currentState.copyWith(category: event.category));
  }

  void _onUpdateEventColor(
    UpdateEventColor event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(currentState.copyWith(colorCode: event.colorCode));
  }

  void _onUpdateEventLocation(
    UpdateEventLocation event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(currentState.copyWith(location: event.location));
  }

  void _onUpdateEventPriority(
    UpdateEventPriority event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(currentState.copyWith(priority: event.priority));
  }

  void _onUpdateRecurrenceRule(
    UpdateRecurrenceRule event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(currentState.copyWith(recurrenceRule: event.rule));
  }

  void _onAddNotification(AddNotification event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    final notifications = List<NotificationSetting>.from(
      currentState.notifications,
    )..add(event.notification);
    emit(currentState.copyWith(notifications: notifications));
  }

  void _onRemoveNotification(
    RemoveNotification event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    final notifications = List<NotificationSetting>.from(
      currentState.notifications,
    )..removeAt(event.index);
    emit(currentState.copyWith(notifications: notifications));
  }

  void _onAddTag(AddTag event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    if (currentState.tags.contains(event.tag)) return;
    final tags = List<String>.from(currentState.tags)..add(event.tag);
    emit(currentState.copyWith(tags: tags));
  }

  void _onRemoveTag(RemoveTag event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    final tags = List<String>.from(currentState.tags)..remove(event.tag);
    emit(currentState.copyWith(tags: tags));
  }

  Future<void> _onSubmitEventForm(
    SubmitEventForm event,
    Emitter<EventFormState> emit,
  ) async {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;

    if (!currentState.isValid) {
      emit(
        EventFormError(ValidationFailure('Please fill in all required fields')),
      );
      emit(currentState);
      return;
    }

    emit(const EventFormSubmitting());

    final eventToSubmit = currentState.toEvent();

    if (currentState.eventId == null) {
      // Create new event
      final result = await createEvent(CreateUserEventParams(eventToSubmit));
      await result.fold(
        (failure) async {
          emit(EventFormError(failure));
          emit(currentState);
        },
        (createdEvent) async {
          // Schedule notifications
          if (createdEvent.hasNotifications) {
            final notificationManager = getIt<EventNotificationManager>();
            await notificationManager.scheduleEventNotifications(createdEvent);
          }
          emit(EventFormSuccess(createdEvent, isNew: true));
        },
      );
    } else {
      // Update existing event
      final result = await updateEvent(UpdateUserEventParams(eventToSubmit));
      await result.fold(
        (failure) async {
          emit(EventFormError(failure));
          emit(currentState);
        },
        (updatedEvent) async {
          // Reschedule notifications
          final notificationManager = getIt<EventNotificationManager>();
          await notificationManager.cancelEventNotifications(updatedEvent.id!);
          if (updatedEvent.hasNotifications) {
            await notificationManager.scheduleEventNotifications(updatedEvent);
          }
          emit(EventFormSuccess(updatedEvent, isNew: false));
        },
      );
    }
  }

  void _onResetEventForm(ResetEventForm event, Emitter<EventFormState> emit) {
    emit(EventFormInitial());
  }
}
