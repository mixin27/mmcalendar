import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/get_settings.dart';
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

  SettingsBloc({
    required this.getSettings,
    required this.updateTheme,
    required this.updateLanguage,
    required this.updateCalendarConfig,
    required this.updateDisplayPreferences,
    required this.resetSettings,
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
        _applyCalendarConfiguration(settings.calendarConfig);
        MyanmarCalendar.setLanguage(settings.calendarLanguage);

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
          final updatedSettings = currentState.settings.copyWith(
            themePreset: 'custom',
            customColors: AppColorSchemes.fromCustomColor(event.colorScheme),
          );
          emit(SettingsLoaded(updatedSettings));
        },
      );
    }
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

    result.fold(
      (failure) => emit(SettingsError(_mapFailureToMessage(failure))),
      (_) {
        MyanmarCalendar.setLanguage(event.language);

        // Fire calendar language changed event
        AppEventBus.fire(CalendarLanguageChangedEvent(event.language));

        final updatedSettings = currentState.settings.copyWith(
          calendarLanguage: event.language,
        );
        emit(SettingsLoaded(updatedSettings));
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
        _applyCalendarConfiguration(event.config);

        // Fire clanedar configuraton changed event
        AppEventBus.fire(CalendarConfigurationChangedEvent(event.config));

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
        _applyCalendarConfiguration(null);

        // Reload settings after reset
        add(const LoadSettings());
      },
    );
  }

  AppSettingsEntity _updatePreference(
    AppSettingsEntity settings,
    String key,
    bool value,
  ) {
    switch (key) {
      case StorageKeys.showHolidays:
        return settings.copyWith(showHolidays: value);
      case StorageKeys.showAstrology:
        return settings.copyWith(showAstrology: value);
      case StorageKeys.showWesternDates:
        return settings.copyWith(showWesternDates: value);
      case StorageKeys.showMyanmarDates:
        return settings.copyWith(showMyanmarDates: value);
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
  void _applyCalendarConfiguration(CalendarConfig? config) {
    if (config == null) {
      MyanmarCalendar.configure();
    } else {
      MyanmarCalendar.configure(
        language: Language.fromCode(config.defaultLanguage),
        timezoneOffset: config.timezoneOffset,
        sasanaYearType: config.sasanaYearType,
        calendarType: config.calendarType,
        gregorianStart: config.gregorianStart,
      );
    }
  }
}
