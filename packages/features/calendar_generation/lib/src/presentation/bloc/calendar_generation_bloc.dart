import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:shared_core/shared_core.dart';

import '../../data/datasources/calendar_generation_preferences_datasource.dart';
import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_page_orientation.dart';
import '../../domain/entities/calendar_paper_size.dart';
import '../../domain/entities/calendar_generation_request.dart';
import '../../domain/entities/calendar_generation_template.dart';
import '../../domain/entities/calendar_preview_theme.dart';
import '../../domain/usecases/build_calendar_previews.dart';
import 'calendar_generation_event.dart';
import 'calendar_generation_state.dart';

class CalendarGenerationBloc
    extends Bloc<CalendarGenerationEvent, CalendarGenerationState> {
  CalendarGenerationBloc({
    required BuildCalendarPreviews buildCalendarPreviews,
    required CalendarDisplayConfigPort calendarDisplayConfigPort,
    required CalendarGenerationPreferencesDataSource preferencesDataSource,
    required AnalyticsPort analyticsPort,
  }) : _buildCalendarPreviews = buildCalendarPreviews,
       _calendarDisplayConfigPort = calendarDisplayConfigPort,
       _preferencesDataSource = preferencesDataSource,
       _analyticsPort = analyticsPort,
       super(const CalendarGenerationInitial()) {
    on<InitializeCalendarGeneration>(_onInitialize);
    on<ChangeGenerationMode>(_onChangeMode);
    on<ChangeGenerationLanguage>(_onChangeLanguage);
    on<ChangeGenerationYear>(_onChangeYear);
    on<ChangeGenerationMonth>(_onChangeMonth);
    on<ChangeBackgroundColor>(_onChangeBackgroundColor);
    on<ChangeForegroundColor>(_onChangeForegroundColor);
    on<ChangeAccentColor>(_onChangeAccentColor);
    on<ChangeBackgroundImageUrl>(_onChangeBackgroundImageUrl);
    on<ChangeMonthBackgroundImageUrl>(_onChangeMonthBackgroundImageUrl);
    on<ToggleGenerationHolidays>(_onToggleHolidays);
    on<ToggleGenerationAstrology>(_onToggleAstrology);
    on<ToggleGenerationWesternDates>(_onToggleWesternDates);
    on<ToggleGenerationMyanmarDates>(_onToggleMyanmarDates);
    on<ChangePaperSize>(_onChangePaperSize);
    on<ChangePageOrientation>(_onChangePageOrientation);
    on<ChangeImageQuality>(_onChangeImageQuality);
    on<SaveGenerationTemplate>(_onSaveGenerationTemplate);
    on<ApplyGenerationTemplate>(_onApplyGenerationTemplate);
    on<DeleteGenerationTemplate>(_onDeleteGenerationTemplate);
    on<RenameGenerationTemplate>(_onRenameGenerationTemplate);
  }

  final BuildCalendarPreviews _buildCalendarPreviews;
  final CalendarDisplayConfigPort _calendarDisplayConfigPort;
  final CalendarGenerationPreferencesDataSource _preferencesDataSource;
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
        paperSize: CalendarPaperSize.a4,
        pageOrientation: CalendarPageOrientation.portrait,
        imageQuality: CalendarImageQuality.print,
      );

      final restoredRequest = _preferencesDataSource.restoreRequest(request);
      final templates = _preferencesDataSource.getTemplates();
      final pages = _buildCalendarPreviews(restoredRequest);
      emit(
        CalendarGenerationLoaded(
          request: restoredRequest,
          pages: pages,
          templates: templates,
        ),
      );
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

  void _onChangeLanguage(
    ChangeGenerationLanguage event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(language: event.language),
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

  void _onChangeMonthBackgroundImageUrl(
    ChangeMonthBackgroundImageUrl event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(emit, (loaded) {
      final imagesByMonth = Map<int, String>.from(
        loaded.request.theme.backgroundImageUrlsByMonth,
      );
      final normalizedUrl = event.url.trim();
      if (normalizedUrl.isEmpty) {
        imagesByMonth.remove(event.month);
      } else {
        imagesByMonth[event.month] = normalizedUrl;
      }
      return loaded.request.copyWith(
        theme: loaded.request.theme.copyWith(
          backgroundImageUrlsByMonth: imagesByMonth,
        ),
      );
    });
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

  void _onChangePaperSize(
    ChangePaperSize event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(paperSize: event.paperSize),
    );
  }

  void _onChangePageOrientation(
    ChangePageOrientation event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(pageOrientation: event.orientation),
    );
  }

  void _onChangeImageQuality(
    ChangeImageQuality event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(imageQuality: event.quality),
    );
  }

  Future<void> _onSaveGenerationTemplate(
    SaveGenerationTemplate event,
    Emitter<CalendarGenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CalendarGenerationLoaded) {
      return;
    }

    final templates = await _preferencesDataSource.saveTemplate(
      name: event.name,
      request: currentState.request,
    );
    emit(currentState.copyWith(templates: templates));
  }

  void _onApplyGenerationTemplate(
    ApplyGenerationTemplate event,
    Emitter<CalendarGenerationState> emit,
  ) {
    final currentState = state;
    if (currentState is! CalendarGenerationLoaded) {
      return;
    }

    final template = _findTemplate(currentState.templates, event.templateId);
    if (template == null) {
      return;
    }

    final nextRequest = _preferencesDataSource.applyTemplate(
      baseRequest: currentState.request,
      template: template,
    );
    final pages = _buildCalendarPreviews(nextRequest);
    emit(currentState.copyWith(request: nextRequest, pages: pages));
    unawaited(_preferencesDataSource.saveRequest(nextRequest));
  }

  Future<void> _onDeleteGenerationTemplate(
    DeleteGenerationTemplate event,
    Emitter<CalendarGenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CalendarGenerationLoaded) {
      return;
    }

    final templates = await _preferencesDataSource.deleteTemplate(
      event.templateId,
    );
    emit(currentState.copyWith(templates: templates));
  }

  Future<void> _onRenameGenerationTemplate(
    RenameGenerationTemplate event,
    Emitter<CalendarGenerationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CalendarGenerationLoaded) {
      return;
    }

    final templates = await _preferencesDataSource.renameTemplate(
      templateId: event.templateId,
      name: event.name,
    );
    emit(currentState.copyWith(templates: templates));
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
    unawaited(_preferencesDataSource.saveRequest(nextRequest));
  }

  CalendarGenerationTemplate? _findTemplate(
    List<CalendarGenerationTemplate> templates,
    String templateId,
  ) {
    for (final template in templates) {
      if (template.id == templateId) {
        return template;
      }
    }
    return null;
  }
}
