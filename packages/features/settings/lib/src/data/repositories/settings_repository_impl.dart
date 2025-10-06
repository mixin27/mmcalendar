import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:data/data.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl extends BaseRepository
    implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;
  final AppDatabase database;

  SettingsRepositoryImpl(this.localDataSource, this.database);

  @override
  Future<Either<Failure, AppSettingsEntity>> getSettings() async {
    try {
      final settings = await localDataSource.getAllSettings();

      // Parse theme mode
      final themeModeStr = settings[StorageKeys.themeMode] ?? 'system';
      final themeMode = _parseThemeMode(themeModeStr);

      // Get theme preset
      final themePreset = settings[StorageKeys.themePreset] ?? 'modern';

      // Get languages
      final appLanguage = settings[StorageKeys.appLanguage] ?? 'en';
      final calendarLanguageStr =
          settings[StorageKeys.calendarLanguage] ?? 'en';
      final calendarLanguage = Language.fromCode(calendarLanguageStr);

      // Get calendar config from database
      final calendarSettings = await database.calendarDao.getOrCreateSettings();
      final calendarConfig = CalendarConfig(
        sasanaYearType: calendarSettings.sasanaYearType,
        calendarType: calendarSettings.calendarType,
        gregorianStart: calendarSettings.gregorianStart,
        timezoneOffset: calendarSettings.timezoneOffset,
        defaultLanguage: calendarSettings.defaultLanguage,
      );

      // Get display preferences
      final showHolidays = _parseBool(
        settings[StorageKeys.showHolidays] ?? 'true',
      );
      final showAstrology = _parseBool(
        settings[StorageKeys.showAstrology] ?? 'false',
      );
      final showWesternDates = _parseBool(
        settings[StorageKeys.showWesternDates] ?? 'true',
      );
      final showMyanmarDates = _parseBool(
        settings[StorageKeys.showMyanmarDates] ?? 'true',
      );
      final firstDayOfWeek = int.parse(
        settings[StorageKeys.firstDayOfWeek] ?? '1',
      );

      // Get theme colors
      final preset = ThemePresets.getPreset(themePreset);
      final themeColors = themeMode == ThemeMode.dark
          ? preset.darkColors
          : preset.lightColors;

      return Right(
        AppSettingsEntity(
          themeMode: themeMode,
          themePreset: themePreset,
          customColors: themeColors,
          appLanguage: appLanguage,
          calendarLanguage: calendarLanguage,
          calendarConfig: calendarConfig,
          showHolidays: showHolidays,
          showAstrology: showAstrology,
          showWesternDates: showWesternDates,
          showMyanmarDates: showMyanmarDates,
          firstDayOfWeek: firstDayOfWeek,
        ),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateThemeMode(ThemeMode themeMode) async {
    try {
      await localDataSource.setSetting(
        StorageKeys.themeMode,
        _themeModeToString(themeMode),
      );

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateThemePreset(String presetId) async {
    try {
      await localDataSource.setSetting(StorageKeys.themePreset, presetId);

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomColors(ColorScheme colors) async {
    try {
      // Store custom colors as JSON or individual values
      // For now, we'll use presets only
      await localDataSource.setSetting(StorageKeys.customColors, 'custom');

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAppLanguage(String languageCode) async {
    try {
      await localDataSource.setSetting(StorageKeys.appLanguage, languageCode);

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCalendarLanguage(
    Language language,
  ) async {
    try {
      await localDataSource.setSetting(
        StorageKeys.calendarLanguage,
        language.code,
      );

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCalendarConfig(
    CalendarConfig config,
  ) async {
    try {
      await database.calendarDao.updateSettings(
        CalendarSettingsCompanion(
          sasanaYearType: Value(config.sasanaYearType),
          calendarType: Value(config.calendarType),
          gregorianStart: Value(config.gregorianStart),
          timezoneOffset: Value(config.timezoneOffset),
          defaultLanguage: Value(config.defaultLanguage),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDisplayPreference(
    String key,
    bool value,
  ) async {
    try {
      await localDataSource.setSetting(key, value.toString());

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetSettings() async {
    try {
      await localDataSource.clearAllSettings();

      // Reset calendar settings to default
      await database.calendarDao.updateSettings(
        CalendarSettingsCompanion(
          sasanaYearType: const Value(0),
          calendarType: const Value(0),
          gregorianStart: const Value(2361222),
          timezoneOffset: const Value(6.5),
          defaultLanguage: const Value('en'),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // Helper methods
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

  bool _parseBool(String value) {
    return value.toLowerCase() == 'true';
  }
}
