import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import '../../config/di_setup.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppInitializing()) {
    on<InitializeApp>(_onInitializeApp);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<ChangeThemePreset>(_onChangeThemePreset);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  Future<void> _onInitializeApp(
    InitializeApp event,
    Emitter<AppState> emit,
  ) async {
    try {
      final database = getIt<AppDatabase>();
      final settingsDao = database.settingsDao;

      // Load theme settings
      final themeModeStr = await settingsDao.getSetting(StorageKeys.themeMode);
      final themeMode = _parseThemeMode(themeModeStr ?? 'system');

      final themePreset = await settingsDao.getSetting(StorageKeys.themePreset);
      // Load language settings
      final languageCode = await settingsDao.getSetting(
        StorageKeys.appLanguage,
      );
      final calendarLanguageCode = await settingsDao.getSetting(
        StorageKeys.calendarLanguage,
      );

      // Get theme colors from preset
      final preset = ThemePresets.getPreset(themePreset ?? 'modern');
      final themeColors = themeMode == ThemeMode.dark
          ? preset.darkColors
          : preset.lightColors;

      emit(
        AppInitialized(
          themeMode: themeMode,
          themePreset: themePreset ?? 'modern',
          themeColors: themeColors,
          languageCode: languageCode ?? 'en',
          calendarLanuageCode: calendarLanguageCode ?? 'en',
        ),
      );
    } catch (e) {
      emit(AppError(e.toString()));
    }
  }

  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<AppState> emit,
  ) async {
    if (state is! AppInitialized) return;

    final currentState = state as AppInitialized;

    try {
      final database = getIt<AppDatabase>();
      await database.settingsDao.setSetting(
        StorageKeys.themeMode,
        _themeModeToString(event.themeMode),
      );

      // Fire event to event bus
      AppEventBus.fire(ThemeModeChangedEvent(event.themeMode));

      emit(currentState.copyWith(themeMode: event.themeMode));
    } catch (e) {
      emit(AppError(e.toString()));
    }
  }

  Future<void> _onChangeThemePreset(
    ChangeThemePreset event,
    Emitter<AppState> emit,
  ) async {
    if (state is! AppInitialized) return;

    final currentState = state as AppInitialized;

    try {
      final database = getIt<AppDatabase>();
      await database.settingsDao.setSetting(
        StorageKeys.themePreset,
        event.presetId,
      );

      // Get theme colors from preset
      final preset = ThemePresets.getPreset(event.presetId);
      final themeColors = currentState.themeMode == ThemeMode.dark
          ? preset.darkColors
          : preset.lightColors;

      // Fire event to event bus
      AppEventBus.fire(ThemePresetChangedEvent(event.presetId));

      emit(
        currentState.copyWith(
          themePreset: event.presetId,
          themeColors: themeColors,
        ),
      );
    } catch (e) {
      emit(AppError(e.toString()));
    }
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<AppState> emit,
  ) async {
    if (state is! AppInitialized) return;

    final currentState = state as AppInitialized;

    try {
      final database = getIt<AppDatabase>();
      await database.settingsDao.setSetting(
        StorageKeys.appLanguage,
        event.languageCode,
      );

      // Update Myanmar Calendar language
      MyanmarCalendar.setLanguage(Language.fromCode(event.languageCode));

      // Fire event to event bus
      AppEventBus.fire(LanguageChangedEvent(event.languageCode));

      emit(currentState.copyWith(languageCode: event.languageCode));
    } catch (e) {
      emit(AppError(e.toString()));
    }
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}
