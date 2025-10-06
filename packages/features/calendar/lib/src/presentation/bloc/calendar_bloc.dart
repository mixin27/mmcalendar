import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';

import '../../domain/usecases/get_calendar_month.dart';
import '../../domain/usecases/navigate_month.dart';
import '../../domain/usecases/toggle_astrology.dart';
import '../../domain/usecases/select_date.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetCalendarMonth getCalendarMonth;
  final NavigateMonth navigateMonth;
  final SelectDate selectDateUseCase;
  final ToggleAstrology toggleAstrology;

  StreamSubscription<CalendarConfigurationChangedEvent>? _configSubscription;
  StreamSubscription<CalendarLanguageChangedEvent>? _languageSubscription;

  CalendarBloc({
    required this.getCalendarMonth,
    required this.navigateMonth,
    required this.selectDateUseCase,
    required this.toggleAstrology,
  }) : super(const CalendarInitial()) {
    on<LoadCalendarMonth>(_onLoadCalendarMonth);
    on<NavigateToNextMonth>(_onNavigateToNextMonth);
    on<NavigateToPreviousMonth>(_onNavigateToPreviousMonth);
    on<NavigateToToday>(_onNavigateToToday);
    on<SelectDateEvent>(_onSelectDate);
    on<ToggleAstrologyCard>(_onToggleAstrologyCard);
    on<RefreshCalendar>(_onRefreshCalendar);

    // Subscribe to event bus
    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    _configSubscription = AppEventBus.on<CalendarConfigurationChangedEvent>()
        .listen((event) {
          add(RefreshCalendar());
        });

    _languageSubscription = AppEventBus.on<CalendarLanguageChangedEvent>()
        .listen((event) {
          add(RefreshCalendar());
        });
  }

  Future<void> _onLoadCalendarMonth(
    LoadCalendarMonth event,
    Emitter<CalendarState> emit,
  ) async {
    emit(const CalendarLoading());

    // Get astrology expansion state
    final astrologyResult = await toggleAstrology.get();
    final isAstrologyExpanded = astrologyResult.fold(
      (_) => false,
      (isExpanded) => isExpanded,
    );

    // Get calendar month
    final result = await getCalendarMonth(event.month);

    result.fold(
      (failure) => emit(CalendarError(_mapFailureToMessage(failure))),
      (calendarMonth) {
        emit(
          CalendarLoaded(
            calendarMonth: calendarMonth,
            isAstrologyExpanded: isAstrologyExpanded,
            today: DateTime.now(),
          ),
        );

        // Fire event to event bus
        AppEventBus.fire(MonthChangedEvent(event.month));
      },
    );
  }

  Future<void> _onNavigateToNextMonth(
    NavigateToNextMonth event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is! CalendarLoaded) return;

    final currentState = state as CalendarLoaded;

    // Preserve astrology expansion state
    final currentAstrologyExpanded = currentState.isAstrologyExpanded;

    emit(const CalendarLoading());

    final result = await navigateMonth.next(currentState.calendarMonth.month);

    result.fold(
      (failure) => emit(CalendarError(_mapFailureToMessage(failure))),
      (calendarMonth) {
        emit(
          CalendarLoaded(
            calendarMonth: calendarMonth,
            selectedDate: null, // Clear selection when changing month
            isAstrologyExpanded: currentAstrologyExpanded, // Preserve state
            today: currentState.today,
          ),
        );

        // Fire event to event bus
        AppEventBus.fire(MonthChangedEvent(calendarMonth.month));
      },
    );
  }

  Future<void> _onNavigateToPreviousMonth(
    NavigateToPreviousMonth event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is! CalendarLoaded) return;

    final currentState = state as CalendarLoaded;

    // Preserve astrology expansion state
    final currentAstrologyExpanded = currentState.isAstrologyExpanded;

    emit(const CalendarLoading());

    final result = await navigateMonth.previous(
      currentState.calendarMonth.month,
    );

    result.fold(
      (failure) => emit(CalendarError(_mapFailureToMessage(failure))),
      (calendarMonth) {
        emit(
          CalendarLoaded(
            calendarMonth: calendarMonth,
            selectedDate: null, // Clear selection when changing month
            isAstrologyExpanded: currentAstrologyExpanded, // Preserve state
            today: currentState.today,
          ),
        );

        // Fire event to event bus
        AppEventBus.fire(MonthChangedEvent(calendarMonth.month));
      },
    );
  }

  Future<void> _onNavigateToToday(
    NavigateToToday event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is! CalendarLoaded) return;

    final currentState = state as CalendarLoaded;

    // Preserve astrology expansion state
    final currentAstrologyExpanded = currentState.isAstrologyExpanded;

    emit(const CalendarLoading());

    final result = await navigateMonth.today();

    result.fold(
      (failure) => emit(CalendarError(_mapFailureToMessage(failure))),
      (calendarMonth) {
        emit(
          CalendarLoaded(
            calendarMonth: calendarMonth,
            selectedDate: null, // Clear selection when changing month
            isAstrologyExpanded: currentAstrologyExpanded, // Preserve state
            today: currentState.today,
          ),
        );

        // Fire event to event bus
        AppEventBus.fire(MonthChangedEvent(calendarMonth.month));
      },
    );
  }

  Future<void> _onSelectDate(
    SelectDateEvent event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is! CalendarLoaded) return;

    final currentState = state as CalendarLoaded;

    final result = await selectDateUseCase(event.date);

    result.fold(
      (failure) => emit(CalendarError(_mapFailureToMessage(failure))),
      (dateSelection) {
        emit(currentState.copyWith(selectedDate: dateSelection));

        // Fire event to event bus
        AppEventBus.fire(DateSelectedEvent(event.date));
      },
    );
  }

  Future<void> _onToggleAstrologyCard(
    ToggleAstrologyCard event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is! CalendarLoaded) return;

    final currentState = state as CalendarLoaded;

    final result = await toggleAstrology();

    result.fold(
      (failure) {
        // Just toggle locally if fails
        emit(
          currentState.copyWith(
            isAstrologyExpanded: !currentState.isAstrologyExpanded,
          ),
        );
      },
      (isExpanded) {
        emit(currentState.copyWith(isAstrologyExpanded: isExpanded));
      },
    );
  }

  Future<void> _onRefreshCalendar(
    RefreshCalendar event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is! CalendarLoaded) return;

    final currentState = state as CalendarLoaded;
    add(LoadCalendarMonth(currentState.calendarMonth.month));
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case const (CacheFailure):
        return 'Failed to load calendar data';
      case const (DataFailure):
        return 'Invalid calendar data';
      default:
        return 'Unexpected error occurred';
    }
  }

  @override
  Future<void> close() {
    _configSubscription?.cancel();
    _languageSubscription?.cancel();
    return super.close();
  }
}
