import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';

import '../../domain/entities/calendar_month.dart';
import '../../domain/usecases/get_calendar_month.dart';
import '../../domain/usecases/select_date.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetCalendarMonth getCalendarMonth;
  final SelectDate selectDateUseCase;
  final Map<int, CalendarMonth> _monthCache = <int, CalendarMonth>{};

  CalendarBloc({
    required this.getCalendarMonth,
    required this.selectDateUseCase,
  }) : super(const CalendarInitial()) {
    on<LoadCalendarMonth>(_onLoadCalendarMonth);
    on<NavigateToNextMonth>(_onNavigateToNextMonth);
    on<NavigateToPreviousMonth>(_onNavigateToPreviousMonth);
    on<NavigateToToday>(_onNavigateToToday);
    on<SelectDateEvent>(_onSelectDate);
    on<RefreshCalendar>(_onRefreshCalendar);
  }

  Future<void> _onLoadCalendarMonth(
    LoadCalendarMonth event,
    Emitter<CalendarState> emit,
  ) async {
    final currentState = state;
    final result = await _getMonth(event.month);

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (_) => null)!;
      emit(CalendarError(_mapFailureToMessage(failure)));
      return;
    }

    final calendarMonth = result.fold((_) => null, (m) => m)!;

    emit(
      CalendarLoaded(
        calendarMonth: calendarMonth,
        today: currentState is CalendarLoaded
            ? currentState.today
            : DateTime.now(),
      ),
    );

    _prefetchAdjacentMonths(calendarMonth.month);
  }

  Future<void> _onNavigateToNextMonth(
    NavigateToNextMonth event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is! CalendarLoaded) return;

    final currentState = state as CalendarLoaded;
    final nextMonth = DateTime(
      currentState.calendarMonth.month.year,
      currentState.calendarMonth.month.month + 1,
      1,
    );
    final result = await _getMonth(nextMonth);
    if (result.isLeft()) {
      final failure = result.fold((f) => f, (_) => null)!;
      emit(CalendarError(_mapFailureToMessage(failure)));
      return;
    }

    final calendarMonth = result.fold((_) => null, (m) => m)!;

    emit(
      CalendarLoaded(calendarMonth: calendarMonth, today: currentState.today),
    );
    _prefetchAdjacentMonths(calendarMonth.month);
  }

  Future<void> _onNavigateToPreviousMonth(
    NavigateToPreviousMonth event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is! CalendarLoaded) return;

    final currentState = state as CalendarLoaded;
    final previousMonth = DateTime(
      currentState.calendarMonth.month.year,
      currentState.calendarMonth.month.month - 1,
      1,
    );
    final result = await _getMonth(previousMonth);

    if (result.isLeft()) {
      final failure = result.fold((f) => f, (_) => null)!;
      emit(CalendarError(_mapFailureToMessage(failure)));
      return;
    }

    final calendarMonth = result.fold((_) => null, (m) => m)!;

    emit(
      CalendarLoaded(calendarMonth: calendarMonth, today: currentState.today),
    );
    _prefetchAdjacentMonths(calendarMonth.month);
  }

  Future<void> _onNavigateToToday(
    NavigateToToday event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is! CalendarLoaded) return;

    final currentState = state as CalendarLoaded;
    final result = await _getMonth(DateTime.now());
    if (result.isLeft()) {
      final failure = result.fold((f) => f, (_) => null)!;
      emit(CalendarError(_mapFailureToMessage(failure)));
      return;
    }

    final calendarMonth = result.fold((_) => null, (m) => m)!;

    emit(
      CalendarLoaded(
        calendarMonth: calendarMonth,
        selectedDate: null, // Clear selection when changing month
        today: currentState.today,
      ),
    );
    _prefetchAdjacentMonths(calendarMonth.month);
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
      },
    );
  }

  Future<void> _onRefreshCalendar(
    RefreshCalendar event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is! CalendarLoaded) return;

    final currentState = state as CalendarLoaded;
    _monthCache.clear();
    add(LoadCalendarMonth(currentState.calendarMonth.month));
  }

  Future<Either<Failure, CalendarMonth>> _getMonth(DateTime month) async {
    final normalizedMonth = _normalizeMonth(month);
    final cacheKey = _monthKey(normalizedMonth);
    final cached = _monthCache[cacheKey];
    if (cached != null) {
      return Right(cached);
    }

    final result = await getCalendarMonth(normalizedMonth);
    result.fold((_) => null, (calendarMonth) {
      _monthCache[cacheKey] = calendarMonth;
    });
    return result;
  }

  void _prefetchAdjacentMonths(DateTime month) {
    final baseMonth = _normalizeMonth(month);
    final previousMonth = DateTime(baseMonth.year, baseMonth.month - 1, 1);
    final nextMonth = DateTime(baseMonth.year, baseMonth.month + 1, 1);
    unawaited(_prefetchMonth(previousMonth));
    unawaited(_prefetchMonth(nextMonth));
  }

  Future<void> _prefetchMonth(DateTime month) async {
    final normalizedMonth = _normalizeMonth(month);
    final cacheKey = _monthKey(normalizedMonth);
    if (_monthCache.containsKey(cacheKey)) {
      return;
    }
    final result = await getCalendarMonth(normalizedMonth);
    result.fold((_) => null, (calendarMonth) {
      _monthCache[cacheKey] = calendarMonth;
    });
  }

  DateTime _normalizeMonth(DateTime month) =>
      DateTime(month.year, month.month, 1);

  int _monthKey(DateTime month) => month.year * 100 + month.month;

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
}
