import 'package:bloc/bloc.dart';
import 'package:shared_core/shared_core.dart';

import '../../domain/usecases/get_day_view.dart';
import '../../domain/usecases/get_week_view.dart';
import '../../domain/usecases/get_year_view.dart';
import 'views_event.dart';
import 'views_state.dart';

class ViewsBloc extends Bloc<ViewsEvent, ViewsState> {
  final GetYearView getYearView;
  final GetWeekView getWeekView;
  final GetDayView getDayView;

  ViewsBloc({
    required this.getYearView,
    required this.getWeekView,
    required this.getDayView,
  }) : super(const ViewsInitial()) {
    on<LoadViews>(_onLoadViews);
    on<LoadYearView>(_onLoadYearView);
    on<LoadWeekView>(_onLoadWeekView);
    on<LoadDayView>(_onLoadDayView);
    on<NavigateYearNext>(_onNavigateYearNext);
    on<NavigateYearPrevious>(_onNavigateYearPrevious);
    on<NavigateWeekNext>(_onNavigateWeekNext);
    on<NavigateWeekPrevious>(_onNavigateWeekPrevious);
    on<NavigateDayNext>(_onNavigateDayNext);
    on<NavigateDayPrevious>(_onNavigateDayPrevious);
  }

  Future<void> _onLoadViews(LoadViews event, Emitter<ViewsState> emit) async {
    emit(const ViewsLoading());

    final yearResult = await getYearView(event.date.year);
    yearResult.fold(
      (failure) => emit(ViewsError(_mapFailureToMessage(failure))),
      (yearData) => emit(YearViewLoaded(yearData)),
    );

    await Future.delayed(const Duration(milliseconds: 100));

    final weekResult = await getWeekView(event.date);
    weekResult.fold(
      (failure) => emit(ViewsError(_mapFailureToMessage(failure))),
      (data) => emit(WeekViewLoaded(data)),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    final dayResult = await getDayView(event.date);
    dayResult.fold(
      (failure) => emit(ViewsError(_mapFailureToMessage(failure))),
      (data) => emit(DayViewLoaded(data)),
    );
  }

  Future<void> _onLoadYearView(
    LoadYearView event,
    Emitter<ViewsState> emit,
  ) async {
    emit(const ViewsLoading());

    final result = await getYearView(event.year);

    result.fold(
      (failure) => emit(ViewsError(_mapFailureToMessage(failure))),
      (yearData) => emit(YearViewLoaded(yearData)),
    );
  }

  Future<void> _onLoadWeekView(
    LoadWeekView event,
    Emitter<ViewsState> emit,
  ) async {
    emit(const ViewsLoading());

    final result = await getWeekView(event.date);

    result.fold(
      (failure) => emit(ViewsError(_mapFailureToMessage(failure))),
      (weekData) => emit(WeekViewLoaded(weekData)),
    );
  }

  Future<void> _onLoadDayView(
    LoadDayView event,
    Emitter<ViewsState> emit,
  ) async {
    emit(const ViewsLoading());

    final result = await getDayView(event.date);

    result.fold(
      (failure) => emit(ViewsError(_mapFailureToMessage(failure))),
      (dayData) => emit(DayViewLoaded(dayData)),
    );
  }

  Future<void> _onNavigateYearNext(
    NavigateYearNext event,
    Emitter<ViewsState> emit,
  ) async {
    if (state is! YearViewLoaded) return;

    final currentState = state as YearViewLoaded;
    add(LoadYearView(currentState.yearData.year + 1));
  }

  Future<void> _onNavigateYearPrevious(
    NavigateYearPrevious event,
    Emitter<ViewsState> emit,
  ) async {
    if (state is! YearViewLoaded) return;

    final currentState = state as YearViewLoaded;
    add(LoadYearView(currentState.yearData.year - 1));
  }

  Future<void> _onNavigateWeekNext(
    NavigateWeekNext event,
    Emitter<ViewsState> emit,
  ) async {
    if (state is! WeekViewLoaded) return;

    final currentState = state as WeekViewLoaded;
    final nextWeekDate = currentState.weekData.weekEnd.add(
      const Duration(days: 1),
    );
    add(LoadWeekView(nextWeekDate));
  }

  Future<void> _onNavigateWeekPrevious(
    NavigateWeekPrevious event,
    Emitter<ViewsState> emit,
  ) async {
    if (state is! WeekViewLoaded) return;

    final currentState = state as WeekViewLoaded;
    final prevWeekDate = currentState.weekData.weekStart.subtract(
      const Duration(days: 1),
    );
    add(LoadWeekView(prevWeekDate));
  }

  Future<void> _onNavigateDayNext(
    NavigateDayNext event,
    Emitter<ViewsState> emit,
  ) async {
    if (state is! DayViewLoaded) return;

    final currentState = state as DayViewLoaded;
    final nextDate = currentState.dayData.date.add(const Duration(days: 1));
    add(LoadDayView(nextDate));
  }

  Future<void> _onNavigateDayPrevious(
    NavigateDayPrevious event,
    Emitter<ViewsState> emit,
  ) async {
    if (state is! DayViewLoaded) return;

    final currentState = state as DayViewLoaded;
    final prevDate = currentState.dayData.date.subtract(
      const Duration(days: 1),
    );
    add(LoadDayView(prevDate));
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case const (CacheFailure):
        return 'Failed to load view data';
      case const (DataFailure):
        return 'Invalid view data';
      default:
        return 'Unexpected error occurred';
    }
  }
}
