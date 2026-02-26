import 'package:bloc/bloc.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:integrations_database/integrations_database.dart';

import '../../config/di_setup.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppInitializing()) {
    on<InitializeApp>(_onInitializeApp);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<ChangeThemePreset>(_onChangeThemePreset);
  }

  Future<void> _onInitializeApp(
    InitializeApp event,
    Emitter<AppState> emit,
  ) async {
    try {
      final database = getIt<AppDatabase>();
      final settingsDao = database.settingsDao;

      // Load ONLY theme settings (AppBloc handles theme only)
      final themeModeStr = await settingsDao.getSetting(StorageKeys.themeMode);
      final themeMode = _parseThemeMode(themeModeStr ?? 'system');

      final themePreset = await settingsDao.getSetting(StorageKeys.themePreset);
      final preset = ThemePresets.getPreset(themePreset ?? 'modern');
      final themeColors = themeMode == ThemeMode.dark
          ? preset.darkColors
          : preset.lightColors;

      emit(
        AppInitialized(
          themeMode: themeMode,
          themePreset: themePreset ?? 'modern',
          themeColors: themeColors,
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

      final preset = ThemePresets.getPreset(event.presetId);
      final themeColors = currentState.themeMode == ThemeMode.dark
          ? preset.darkColors
          : preset.lightColors;

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
