import 'package:bloc/bloc.dart';
import 'package:shared_core/shared_core.dart';

import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_preview_theme.dart';
import '../../domain/usecases/build_calendar_previews.dart';
import 'calendar_generation_event.dart';
import 'calendar_generation_state.dart';

class CalendarGenerationBloc
    extends Bloc<CalendarGenerationEvent, CalendarGenerationState> {
  CalendarGenerationBloc({
    required BuildCalendarPreviews buildCalendarPreviews,
    required CalendarDisplayConfigPort calendarDisplayConfigPort,
    required AnalyticsPort analyticsPort,
  }) : _buildCalendarPreviews = buildCalendarPreviews,
       _calendarDisplayConfigPort = calendarDisplayConfigPort,
       _analyticsPort = analyticsPort,
       super(const CalendarGenerationInitial()) {
    on<InitializeCalendarGeneration>(_onInitialize);
    on<ChangeGenerationMode>(_onChangeMode);
    on<ChangeGenerationYear>(_onChangeYear);
    on<ChangeGenerationMonth>(_onChangeMonth);
    on<ChangeBackgroundColor>(_onChangeBackgroundColor);
    on<ChangeForegroundColor>(_onChangeForegroundColor);
    on<ChangeAccentColor>(_onChangeAccentColor);
    on<ChangeBackgroundImageUrl>(_onChangeBackgroundImageUrl);
    on<ToggleGenerationHolidays>(_onToggleHolidays);
    on<ToggleGenerationAstrology>(_onToggleAstrology);
    on<ToggleGenerationWesternDates>(_onToggleWesternDates);
    on<ToggleGenerationMyanmarDates>(_onToggleMyanmarDates);
  }

  final BuildCalendarPreviews _buildCalendarPreviews;
  final CalendarDisplayConfigPort _calendarDisplayConfigPort;
  final AnalyticsPort _analyticsPort;

  Future<void> _onInitialize(
    InitializeCalendarGeneration event,
    Emitter<CalendarGenerationState> emit,
  ) async {
    emit(const CalendarGenerationLoading());

    try {
      _analyticsPort.logScreenView(
        screenName: 'calendar_generation',
        screenClass: 'CalendarGenerationPage',
      );

      final displayConfig = await _calendarDisplayConfigPort.getDisplayConfig();
      final now = DateTime.now();

      final request = CalendarGenerationRequest(
        mode: CalendarGenerationMode.month,
        year: now.year,
        month: now.month,
        language: displayConfig.calendarLanguage,
        calendarConfig: displayConfig.calendarConfig,
        useDeviceTimezone: displayConfig.useDeviceTimezone,
        showHolidays: displayConfig.showHolidays,
        showAstrology: displayConfig.showAstrology,
        showWesternDates: displayConfig.showWesternDates,
        showMyanmarDates: displayConfig.showMyanmarDates,
        firstDayOfWeek: 1,
        theme: CalendarPreviewTheme.defaults(),
      );

      final pages = _buildCalendarPreviews(request);
      emit(CalendarGenerationLoaded(request: request, pages: pages));
    } catch (error) {
      emit(CalendarGenerationError(error.toString()));
    }
  }

  void _onChangeMode(
    ChangeGenerationMode event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(mode: event.mode),
    );
  }

  void _onChangeYear(
    ChangeGenerationYear event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(year: event.year),
    );
  }

  void _onChangeMonth(
    ChangeGenerationMonth event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(month: event.month),
    );
  }

  void _onChangeBackgroundColor(
    ChangeBackgroundColor event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        theme: loaded.request.theme.copyWith(
          backgroundColorValue: event.colorValue,
        ),
      ),
    );
  }

  void _onChangeForegroundColor(
    ChangeForegroundColor event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        theme: loaded.request.theme.copyWith(
          foregroundColorValue: event.colorValue,
        ),
      ),
    );
  }

  void _onChangeAccentColor(
    ChangeAccentColor event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        theme: loaded.request.theme.copyWith(
          accentColorValue: event.colorValue,
        ),
      ),
    );
  }

  void _onChangeBackgroundImageUrl(
    ChangeBackgroundImageUrl event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        theme: loaded.request.theme.copyWith(backgroundImageUrl: event.url),
      ),
    );
  }

  void _onToggleHolidays(
    ToggleGenerationHolidays event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(showHolidays: event.value),
    );
  }

  void _onToggleAstrology(
    ToggleGenerationAstrology event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(showAstrology: event.value),
    );
  }

  void _onToggleWesternDates(
    ToggleGenerationWesternDates event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(showWesternDates: event.value),
    );
  }

  void _onToggleMyanmarDates(
    ToggleGenerationMyanmarDates event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(showMyanmarDates: event.value),
    );
  }

  void _regenerateIfLoaded(
    Emitter<CalendarGenerationState> emit,
    CalendarGenerationRequest Function(CalendarGenerationLoaded loaded)
    updateRequest,
  ) {
    final currentState = state;
    if (currentState is! CalendarGenerationLoaded) {
      return;
    }

    final nextRequest = updateRequest(currentState);
    final pages = _buildCalendarPreviews(nextRequest);
    emit(currentState.copyWith(request: nextRequest, pages: pages));
  }
}
