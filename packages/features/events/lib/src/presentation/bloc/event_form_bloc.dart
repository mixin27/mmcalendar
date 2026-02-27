import 'package:bloc/bloc.dart';
import 'package:shared_core/shared_core.dart';

import '../../application/services/event_flow_service.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/notification_setting.dart';
import '../../domain/services/event_validation_service.dart';
import '../../domain/usecases/get_event_by_id.dart';
import '../../utils/event_creation_diagnostic.dart';
import 'event_form_event.dart';
import 'event_form_state.dart';

class EventFormBloc extends Bloc<EventFormEvent, EventFormState> {
  final EventFlowService eventFlowService;
  final GetEventById getEventById;

  EventFormBloc({required this.eventFlowService, required this.getEventById})
    : super(EventFormInitial()) {
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
      _validatedState(
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
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );
  }

  void _onInitializeEditEvent(
    InitializeEditEvent event,
    Emitter<EventFormState> emit,
  ) {
    final e = event.event;
    emit(
      _validatedState(
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
          createdAt: e.createdAt,
          updatedAt: e.updatedAt,
        ),
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
    emit(_validatedState(currentState.copyWith(title: event.title)));
  }

  void _onUpdateEventDescription(
    UpdateEventDescription event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(
      _validatedState(currentState.copyWith(description: event.description)),
    );
  }

  void _onUpdateEventDate(UpdateEventDate event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(_validatedState(currentState.copyWith(eventDate: event.date)));
  }

  void _onUpdateEventTime(UpdateEventTime event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(_validatedState(currentState.copyWith(eventTime: event.time)));
  }

  void _onToggleAllDay(ToggleAllDay event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(
      _validatedState(
        currentState.copyWith(
          isAllDay: !currentState.isAllDay,
          eventTime: !currentState.isAllDay ? null : currentState.eventTime,
        ),
      ),
    );
  }

  void _onUpdateEventCategory(
    UpdateEventCategory event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(_validatedState(currentState.copyWith(category: event.category)));
  }

  void _onUpdateEventColor(
    UpdateEventColor event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(_validatedState(currentState.copyWith(colorCode: event.colorCode)));
  }

  void _onUpdateEventLocation(
    UpdateEventLocation event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(_validatedState(currentState.copyWith(location: event.location)));
  }

  void _onUpdateEventPriority(
    UpdateEventPriority event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(_validatedState(currentState.copyWith(priority: event.priority)));
  }

  void _onUpdateRecurrenceRule(
    UpdateRecurrenceRule event,
    Emitter<EventFormState> emit,
  ) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    emit(_validatedState(currentState.copyWith(recurrenceRule: event.rule)));
  }

  void _onAddNotification(AddNotification event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;

    final alreadyAdded = currentState.notifications.any(
      (n) =>
          n.minutesBefore == event.notification.minutesBefore &&
          n.channel == event.notification.channel,
    );
    if (alreadyAdded) {
      emit(
        currentState.copyWith(
          errorMessage: 'This reminder is already added',
          isValid: currentState.isValid,
        ),
      );
      return;
    }

    final notifications = List<NotificationSetting>.from(
      currentState.notifications,
    )..add(event.notification);
    emit(_validatedState(currentState.copyWith(notifications: notifications)));
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
    emit(_validatedState(currentState.copyWith(notifications: notifications)));
  }

  void _onAddTag(AddTag event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    final normalized = event.tag.trim();
    if (normalized.isEmpty) return;

    final exists = currentState.tags.any(
      (tag) => tag.toLowerCase() == normalized.toLowerCase(),
    );
    if (exists) return;

    final tags = List<String>.from(currentState.tags)..add(normalized);
    emit(_validatedState(currentState.copyWith(tags: tags)));
  }

  void _onRemoveTag(RemoveTag event, Emitter<EventFormState> emit) {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;
    final tags = List<String>.from(currentState.tags)..remove(event.tag);
    emit(_validatedState(currentState.copyWith(tags: tags)));
  }

  Future<void> _onSubmitEventForm(
    SubmitEventForm event,
    Emitter<EventFormState> emit,
  ) async {
    if (state is! EventFormEditing) return;
    final currentState = state as EventFormEditing;

    final validatedState = _validatedState(currentState);
    if (!validatedState.isValid) {
      emit(validatedState);
      emit(
        EventFormError(
          ValidationFailure(
            validatedState.errorMessage ?? 'Please fill in required fields',
          ),
        ),
      );
      emit(validatedState);
      return;
    }

    emit(const EventFormSubmitting());

    final eventToSubmit = validatedState.toEvent();
    EventCreationDiagnostic.logBlocCreateStart(eventToSubmit.title);

    final result = await eventFlowService.saveEvent(eventToSubmit);
    result.fold(
      (failure) {
        emit(EventFormError(failure));
        emit(validatedState);
      },
      (flowResult) {
        if (flowResult.warningMessage != null) {
          emit(EventFormError(DataFailure(flowResult.warningMessage!)));
        }
        emit(EventFormSuccess(flowResult.event, isNew: flowResult.isNew));
      },
    );
  }

  EventFormEditing _validatedState(EventFormEditing state) {
    final validation = EventValidationService.validateEvent(
      state.toEvent(),
      isUpdate: state.eventId != null,
    );
    return state.copyWith(
      isValid: validation.isValid,
      errorMessage: validation.message,
      updatedAt: DateTime.now(),
    );
  }

  void _onResetEventForm(ResetEventForm event, Emitter<EventFormState> emit) {
    emit(EventFormInitial());
  }
}
