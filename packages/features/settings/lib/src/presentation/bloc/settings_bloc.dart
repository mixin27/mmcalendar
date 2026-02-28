import 'package:bloc/bloc.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/mark_as_consent_dialog_shown.dart';
import '../../domain/usecases/reset_settings.dart';
import '../../domain/usecases/update_calendar_config.dart';
import '../../domain/usecases/update_display_preferences.dart';
import '../../domain/usecases/update_language.dart';
import '../../domain/usecases/update_theme.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final UpdateTheme updateTheme;
  final UpdateLanguage updateLanguage;
  final UpdateCalendarConfig updateCalendarConfig;
  final UpdateDisplayPreferences updateDisplayPreferences;
  final ResetSettings resetSettings;
  final MarkAsConsentDialogShown markAsConsentDialogShown;
  final WidgetRepository widgetRepository;
  final AnalyticsPort analyticsService;
  final CrashlyticsPort crashlyticsService;
  final HolidayOverridesPort holidayOverridesPort;

  SettingsBloc({
    required this.getSettings,
    required this.updateTheme,
    required this.updateLanguage,
    required this.updateCalendarConfig,
    required this.updateDisplayPreferences,
    required this.resetSettings,
    required this.markAsConsentDialogShown,
    required this.widgetRepository,
    required this.analyticsService,
    required this.crashlyticsService,
    required this.holidayOverridesPort,
  }) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<ChangeThemePreset>(_onChangeThemePreset);
    on<ChangeAppLanguage>(_onChangeAppLanguage);
    on<ChangeCalendarLanguage>(_onChangeCalendarLanguage);
    on<UpdateCalendarConfiguration>(_onUpdateCalendarConfiguration);
    on<ToggleDisplayPreference>(_onToggleDisplayPreference);
    on<ResetAllSettings>(_onResetAllSettings);
    on<UpdateCustomColors>(_onUpdateCustomColors);
    on<UpdateAnalyticsConsent>(_onUpdateAnalyticsConsent);
    on<UpdateCrashlyticsConsent>(_onUpdateCrashlyticsConsent);
    on<MarkConsentDialogShown>(_onMarkConsentDialogShown);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    final result = await getSettings();

    result.fold(
      (failure) => emit(SettingsError(_mapFailureToMessage(failure))),
      (settings) {
        // Apply both config AND language
        _applyCalendarConfiguration(
          config: settings.calendarConfig,
          language: settings.calendarLanguage,
        );

        emit(SettingsLoaded(settings));
      },
    );
  }

  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final currentState = state as SettingsLoaded;
    final result = await updateTheme.updateMode(event.themeMode);

    result.fold(
      (failure) => emit(SettingsError(_mapFailureToMessage(failure))),
      (_) {
        // Log to Analytics
        analyticsService.logThemeChange(
          themeMode: event.themeMode.toString(),
          themePreset: currentState.settings.themePreset,
        );

        final preset = ThemePresets.getPreset(
          currentState.settings.themePreset,
        );
        final newColors = event.themeMode == ThemeMode.dark
            ? preset.darkColors
            : preset.lightColors;

        final updatedSettings = currentState.settings.copyWith(
          themeMode: event.themeMode,
          customColors: newColors,
        );
        emit(SettingsLoaded(updatedSettings));
      },
    );
  }

  Future<void> _onChangeThemePreset(
    ChangeThemePreset event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final currentState = state as SettingsLoaded;
    final result = await updateTheme.updatePreset(event.presetId);

    result.fold(
      (failure) => emit(SettingsError(_mapFailureToMessage(failure))),
      (_) {
        // Log to Analytics
        analyticsService.logSettingsChange(
          settingName: 'theme_preset',
          oldValue: currentState.settings.themePreset,
          newValue: event.presetId,
        );

        // Get new theme colors
        final preset = ThemePresets.getPreset(event.presetId);
        final newColors = currentState.settings.themeMode == ThemeMode.dark
            ? preset.darkColors
            : preset.lightColors;

        final updatedSettings = currentState.settings.copyWith(
          themePreset: event.presetId,
          customColors: newColors,
        );
        emit(SettingsLoaded(updatedSettings));
      },
    );
  }

  Future<void> _onChangeAppLanguage(
    ChangeAppLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final currentState = state as SettingsLoaded;
    final result = await updateLanguage.updateAppLanguage(event.languageCode);

    result.fold(
      (failure) => emit(SettingsError(_mapFailureToMessage(failure))),
      (_) {
        // Log to Analytics
        analyticsService.logLanguageChange(
          languageCode: event.languageCode,
          languageName: event.languageCode == 'en' ? 'English' : 'Myanmar',
        );

        final updatedSettings = currentState.settings.copyWith(
          appLanguage: event.languageCode,
        );
        emit(SettingsLoaded(updatedSettings));
      },
    );
  }

  Future<void> _onChangeCalendarLanguage(
    ChangeCalendarLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final currentState = state as SettingsLoaded;
    final result = await updateLanguage.updateCalendarLanguage(event.language);

    await result.fold(
      (failure) async {
        emit(SettingsError(_mapFailureToMessage(failure)));
      },
      (_) async {
        // Log to Analytics
        analyticsService.logLanguageChange(
          languageCode: event.language.code,
          languageName: event.language.name,
        );
        _applyCalendarConfiguration(
          config: currentState.settings.calendarConfig,
          language: event.language,
        );

        final updatedSettings = currentState.settings.copyWith(
          calendarLanguage: event.language,
        );
        emit(SettingsLoaded(updatedSettings));

        try {
          await widgetRepository.refreshWidget();
        } catch (e, stackTrace) {
          await crashlyticsService.recordException(
            exception: e,
            stackTrace: stackTrace,
            reason: 'Failed to refresh home widgets after language change',
          );
        }
      },
    );
  }

  Future<void> _onUpdateCalendarConfiguration(
    UpdateCalendarConfiguration event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final currentState = state as SettingsLoaded;
    final result = await updateCalendarConfig(event.config);

    result.fold(
      (failure) => emit(SettingsError(_mapFailureToMessage(failure))),
      (_) {
        _applyCalendarConfiguration(
          config: event.config,
          language: currentState.settings.calendarLanguage,
        );

        final updatedSettings = currentState.settings.copyWith(
          calendarConfig: event.config,
        );
        emit(SettingsLoaded(updatedSettings));
      },
    );
  }

  Future<void> _onToggleDisplayPreference(
    ToggleDisplayPreference event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final currentState = state as SettingsLoaded;
    final result = await updateDisplayPreferences(event.key, event.value);

    result.fold(
      (failure) => emit(SettingsError(_mapFailureToMessage(failure))),
      (_) {
        // Log to Analytics
        analyticsService.logFeatureToggle(
          featureName: event.key,
          enabled: event.value,
        );

        // Update the specific preference
        final updatedSettings = _updatePreference(
          currentState.settings,
          event.key,
          event.value,
        );
        emit(SettingsLoaded(updatedSettings));
      },
    );
  }

  Future<void> _onResetAllSettings(
    ResetAllSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    final result = await resetSettings();

    result.fold(
      (failure) => emit(SettingsError(_mapFailureToMessage(failure))),
      (_) {
        // Log to Analytics
        analyticsService.logButtonClick(
          buttonName: 'reset_settings',
          buttonLocation: 'settings_page',
        );

        _applyCalendarConfiguration(
          config: const CalendarConfig(),
          language: Language.english,
        );

        // Reload settings after reset
        add(const LoadSettings());
      },
    );
  }

  Future<void> _onUpdateCustomColors(
    UpdateCustomColors event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;

      // Save custom colors
      final result = await updateTheme.updateCustomColors(event.colorScheme);

      result.fold(
        (failure) => emit(SettingsError(_mapFailureToMessage(failure))),
        (_) {
          // Log to Analytics
          analyticsService.logSettingsChange(
            settingName: 'custom_colors',
            oldValue: 'changed',
            newValue: 'updated',
          );

          final updatedSettings = currentState.settings.copyWith(
            themePreset: 'custom',
            customColors: AppColorSchemes.fromCustomColor(event.colorScheme),
          );
          emit(SettingsLoaded(updatedSettings));
        },
      );
    }
  }

  Future<void> _onUpdateAnalyticsConsent(
    UpdateAnalyticsConsent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final currentState = state as SettingsLoaded;

    // Update the AnalyticsPort config
    await analyticsService.updateConfig(
      analyticsService.config.copyWith(enableCollection: event.enableAnalytics),
    );

    // Also update repository for persistence
    final result = await updateDisplayPreferences(
      StorageKeys.enableAnalytics,
      event.enableAnalytics,
    );

    result.fold(
      (failure) => emit(SettingsError(_mapFailureToMessage(failure))),
      (_) {
        // Log the consent change
        analyticsService.logSettingsChange(
          settingName: 'analytics_consent',
          oldValue: currentState.settings.enableAnalytics,
          newValue: event.enableAnalytics,
        );

        final updatedSettings = currentState.settings.copyWith(
          enableAnalytics: event.enableAnalytics,
        );
        emit(SettingsLoaded(updatedSettings));
      },
    );
  }

  Future<void> _onUpdateCrashlyticsConsent(
    UpdateCrashlyticsConsent event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final currentState = state as SettingsLoaded;

    // Update the CrashlyticsPort config
    await crashlyticsService.updateConfig(
      crashlyticsService.config.copyWith(
        enableCollection: event.enableCrashlytics,
      ),
    );

    // Also update repository for persistence
    final result = await updateDisplayPreferences(
      StorageKeys.enableCrashlytics,
      event.enableCrashlytics,
    );

    result.fold(
      (failure) => emit(SettingsError(_mapFailureToMessage(failure))),
      (_) {
        final updatedSettings = currentState.settings.copyWith(
          enableCrashlytics: event.enableCrashlytics,
        );
        emit(SettingsLoaded(updatedSettings));
      },
    );
  }

  Future<void> _onMarkConsentDialogShown(
    MarkConsentDialogShown event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;

    final currentState = state as SettingsLoaded;

    // Mark in database
    await markAsConsentDialogShown();

    final updatedSettings = currentState.settings.copyWith(
      hasShownConsentDialog: true,
    );

    emit(SettingsLoaded(updatedSettings));
  }

  AppSettingsEntity _updatePreference(
    AppSettingsEntity settings,
    String key,
    bool value,
  ) {
    switch (key) {
      case StorageKeys.showHolidays:
        return settings.copyWith(showHolidays: value);
      case StorageKeys.showAnniversaryDays:
        return settings.copyWith(showAnniversaryDays: value);
      case StorageKeys.showSabbaths:
        return settings.copyWith(showSabbaths: value);
      case StorageKeys.showAstrology:
        return settings.copyWith(showAstrology: value);
      case StorageKeys.showWesternDates:
        return settings.copyWith(showWesternDates: value);
      case StorageKeys.showMyanmarDates:
        return settings.copyWith(showMyanmarDates: value);
      case StorageKeys.showShanCalendar:
        return settings.copyWith(showShanCalendar: value);
      default:
        return settings;
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case const (CacheFailure):
        return 'Failed to save settings';
      case const (DataFailure):
        return 'Invalid settings data';
      default:
        return 'Unexpected error occurred';
    }
  }

  // Helper method to apply calendar configuration
  void _applyCalendarConfiguration({
    required CalendarConfig config,
    required Language language,
  }) {
    applyMyanmarCalendarRuntimeConfig(
      baseConfig: config,
      language: language,
      customHolidayRules: holidayOverridesPort.getCustomHolidayRules(),
      disabledHolidays: holidayOverridesPort.getDisabledHolidays(),
      disabledHolidaysByYear: holidayOverridesPort.getDisabledHolidaysByYear(),
      disabledHolidaysByDate: holidayOverridesPort.getDisabledHolidaysByDate(),
      cacheProfile: MyanmarCalendarCacheProfile.memoryEfficient,
    );
  }
}
