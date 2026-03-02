import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:shared_core/shared_core.dart';

import '../../data/datasources/calendar_generation_preferences_datasource.dart';
import '../../domain/entities/calendar_image_quality.dart';
import '../../domain/entities/calendar_export_tuning.dart';
import '../../domain/entities/calendar_generation_mode.dart';
import '../../domain/entities/calendar_landscape_decoration_area_side.dart';
import '../../domain/entities/calendar_overlay_element.dart';
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
    on<ChangeBackgroundImageOpacity>(_onChangeBackgroundImageOpacity);
    on<ChangeBackgroundImageFit>(_onChangeBackgroundImageFit);
    on<ChangeBackgroundImageAlignment>(_onChangeBackgroundImageAlignment);
    on<UpdateCalendarPreviewTheme>(_onUpdateTheme);
    on<ChangeMonthBackgroundImageUrl>(_onChangeMonthBackgroundImageUrl);
    on<ToggleGenerationHolidays>(_onToggleHolidays);
    on<ToggleGenerationAstrology>(_onToggleAstrology);
    on<ToggleGenerationWesternDates>(_onToggleWesternDates);
    on<ToggleGenerationMyanmarDates>(_onToggleMyanmarDates);
    on<ChangePaperSize>(_onChangePaperSize);
    on<ChangePageOrientation>(_onChangePageOrientation);
    on<ChangeLandscapeDecorationAreaSide>(_onChangeLandscapeDecorationAreaSide);
    on<ChangeImageQuality>(_onChangeImageQuality);
    on<ChangeExportDpi>(_onChangeExportDpi);
    on<ChangeExportJpegQuality>(_onChangeExportJpegQuality);
    on<ChangeExportTargetSizeKb>(_onChangeExportTargetSizeKb);
    on<ToggleAdaptiveImageCompression>(_onToggleAdaptiveImageCompression);
    on<ReplaceOverlayElementsByMonth>(_onReplaceOverlayElementsByMonth);
    on<SaveGenerationTemplate>(_onSaveGenerationTemplate);
    on<ApplyGenerationTemplate>(_onApplyGenerationTemplate);
    on<DeleteGenerationTemplate>(_onDeleteGenerationTemplate);
    on<RenameGenerationTemplate>(_onRenameGenerationTemplate);
  }

  final BuildCalendarPreviews _buildCalendarPreviews;
  final CalendarDisplayConfigPort _calendarDisplayConfigPort;
  final CalendarGenerationPreferencesDataSource _preferencesDataSource;
  final AnalyticsPort _analyticsPort;
  Timer? _requestSaveDebounceTimer;
  CalendarGenerationRequest? _pendingRequestToSave;
  static const Duration _requestSaveDebounceDuration = Duration(
    milliseconds: 320,
  );

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
        landscapeDecorationAreaSide: CalendarLandscapeDecorationAreaSide.right,
        imageQuality: CalendarImageQuality.print,
        exportTuning: CalendarExportTuning(
          dpi: CalendarImageQuality.print.defaultDpi,
          jpegQuality: CalendarImageQuality.print.defaultJpegQuality,
          targetSizeKb: CalendarImageQuality.print.defaultTargetSizeKb,
          enableAdaptiveCompression: true,
        ),
      );

      var restoredRequest = _preferencesDataSource.restoreRequest(request);
      restoredRequest = await _migrateLegacyDataImageUris(restoredRequest);
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

  void _onChangeBackgroundImageOpacity(
    ChangeBackgroundImageOpacity event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        theme: loaded.request.theme.copyWith(
          backgroundImageOpacity: event.opacity.clamp(0.0, 1.0).toDouble(),
        ),
      ),
    );
  }

  void _onChangeBackgroundImageFit(
    ChangeBackgroundImageFit event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        theme: loaded.request.theme.copyWith(backgroundImageFit: event.fit),
      ),
    );
  }

  void _onChangeBackgroundImageAlignment(
    ChangeBackgroundImageAlignment event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        theme: loaded.request.theme.copyWith(
          backgroundImageAlignment: event.alignment,
        ),
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

  void _onUpdateTheme(
    UpdateCalendarPreviewTheme event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(theme: event.theme),
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

  void _onChangeLandscapeDecorationAreaSide(
    ChangeLandscapeDecorationAreaSide event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) =>
          loaded.request.copyWith(landscapeDecorationAreaSide: event.side),
    );
  }

  void _onChangeImageQuality(
    ChangeImageQuality event,
    Emitter<CalendarGenerationState> emit,
  ) {
    final tuned = CalendarExportTuning(
      dpi: event.quality.defaultDpi,
      jpegQuality: event.quality.defaultJpegQuality,
      targetSizeKb: event.quality.defaultTargetSizeKb,
      enableAdaptiveCompression: true,
    );
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        imageQuality: event.quality,
        exportTuning: tuned,
      ),
    );
  }

  void _onChangeExportDpi(
    ChangeExportDpi event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        exportTuning: loaded.request.exportTuning.copyWith(dpi: event.dpi),
      ),
    );
  }

  void _onChangeExportJpegQuality(
    ChangeExportJpegQuality event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        exportTuning: loaded.request.exportTuning.copyWith(
          jpegQuality: event.jpegQuality,
        ),
      ),
    );
  }

  void _onChangeExportTargetSizeKb(
    ChangeExportTargetSizeKb event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        exportTuning: loaded.request.exportTuning.copyWith(
          targetSizeKb: event.targetSizeKb,
        ),
      ),
    );
  }

  void _onToggleAdaptiveImageCompression(
    ToggleAdaptiveImageCompression event,
    Emitter<CalendarGenerationState> emit,
  ) {
    _regenerateIfLoaded(
      emit,
      (loaded) => loaded.request.copyWith(
        exportTuning: loaded.request.exportTuning.copyWith(
          enableAdaptiveCompression: event.value,
        ),
      ),
    );
  }

  void _onReplaceOverlayElementsByMonth(
    ReplaceOverlayElementsByMonth event,
    Emitter<CalendarGenerationState> emit,
  ) {
    final currentState = state;
    if (currentState is! CalendarGenerationLoaded) {
      return;
    }
    final copied = _copyOverlayElementsByMonth(event.overlayElementsByMonth);
    final nextRequest = currentState.request.copyWith(
      overlayElementsByMonth: copied,
    );
    emit(currentState.copyWith(request: nextRequest));
    _queueRequestPersistence(nextRequest);
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
    _queueRequestPersistence(nextRequest);
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
    _queueRequestPersistence(nextRequest);
  }

  void _queueRequestPersistence(CalendarGenerationRequest request) {
    _pendingRequestToSave = request;
    _requestSaveDebounceTimer?.cancel();
    _requestSaveDebounceTimer = Timer(_requestSaveDebounceDuration, () {
      final pending = _pendingRequestToSave;
      _pendingRequestToSave = null;
      if (pending == null) {
        return;
      }
      unawaited(_preferencesDataSource.saveRequest(pending));
    });
  }

  @override
  Future<void> close() async {
    _requestSaveDebounceTimer?.cancel();
    final pending = _pendingRequestToSave;
    _pendingRequestToSave = null;
    if (pending != null) {
      await _preferencesDataSource.saveRequest(pending);
    }
    await super.close();
  }

  Future<CalendarGenerationRequest> _migrateLegacyDataImageUris(
    CalendarGenerationRequest request,
  ) async {
    final theme = request.theme;
    final migratedDefault = await _persistDataImageUri(
      theme.backgroundImageUrl,
    );

    var hasChanges = migratedDefault != theme.backgroundImageUrl;
    var migratedMonthly = theme.backgroundImageUrlsByMonth;

    for (final entry in theme.backgroundImageUrlsByMonth.entries) {
      final migratedValue = await _persistDataImageUri(entry.value);
      if (migratedValue == null || migratedValue == entry.value) {
        continue;
      }
      if (!hasChanges) {
        migratedMonthly = Map<int, String>.from(
          theme.backgroundImageUrlsByMonth,
        );
      }
      hasChanges = true;
      migratedMonthly[entry.key] = migratedValue;
    }

    if (!hasChanges) {
      return request;
    }

    final migratedRequest = request.copyWith(
      theme: theme.copyWith(
        backgroundImageUrl: migratedDefault,
        backgroundImageUrlsByMonth: migratedMonthly,
      ),
    );
    await _preferencesDataSource.saveRequest(migratedRequest);
    return migratedRequest;
  }

  Future<String?> _persistDataImageUri(String? source) async {
    final normalized = source?.trim();
    if (normalized == null ||
        normalized.isEmpty ||
        !_isDataImageUri(normalized)) {
      return normalized;
    }

    final payloadStart = normalized.indexOf('base64,');
    if (payloadStart < 0) {
      return normalized;
    }

    try {
      final encoded = normalized.substring(payloadStart + 7);
      final bytes = base64Decode(encoded);
      if (bytes.isEmpty) {
        return '';
      }

      final directory = Directory(
        '${Directory.systemTemp.path}/mmcalendar_background_images',
      );
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final extension = _fileExtensionFromDataImageUri(normalized);
      final file = File(
        '${directory.path}/bg_${DateTime.now().microsecondsSinceEpoch}.$extension',
      );
      await file.writeAsBytes(bytes, flush: true);
      return Uri.file(file.path).toString();
    } catch (_) {
      return normalized;
    }
  }

  bool _isDataImageUri(String value) {
    return value.startsWith('data:image/') && value.contains(';base64,');
  }

  String _fileExtensionFromDataImageUri(String dataUri) {
    final mimeStart = dataUri.indexOf(':');
    final mimeEnd = dataUri.indexOf(';');
    if (mimeStart < 0 || mimeEnd <= mimeStart) {
      return 'png';
    }
    final mimeType = dataUri.substring(mimeStart + 1, mimeEnd).toLowerCase();
    return switch (mimeType) {
      'image/jpeg' || 'image/jpg' => 'jpg',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      'image/bmp' => 'bmp',
      'image/heic' => 'heic',
      _ => 'png',
    };
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

  Map<int, List<CalendarOverlayElement>> _copyOverlayElementsByMonth(
    Map<int, List<CalendarOverlayElement>> source,
  ) {
    final copied = <int, List<CalendarOverlayElement>>{};
    for (final entry in source.entries) {
      copied[entry.key] = List<CalendarOverlayElement>.unmodifiable(
        entry.value,
      );
    }
    return Map<int, List<CalendarOverlayElement>>.unmodifiable(copied);
  }
}
