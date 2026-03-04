import 'dart:convert';
import 'dart:developer';

import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart'
    hide CacheException;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

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

      final customColors = await localDataSource.getSetting(
        StorageKeys.customColors,
      );

      // Parse theme mode
      final themeModeStr = settings[StorageKeys.themeMode] ?? 'system';
      final themeMode = _parseThemeMode(themeModeStr);

      // Get theme preset
      final themePreset = settings[StorageKeys.themePreset] ?? 'modern';
      final appIcon = settings[StorageKeys.appIcon] ?? 'default';

      // Get languages
      final appLanguage = settings[StorageKeys.appLanguage] ?? 'en';
      final calendarLanguageStr =
          settings[StorageKeys.calendarLanguage] ?? Language.myanmar.code;
      final calendarLanguage = Language.fromCode(calendarLanguageStr);
      final useDeviceTimezone = _parseBool(
        settings[StorageKeys.useDeviceTimezone] ?? 'true',
      );

      // Get calendar config from database
      final calendarSettings = await database.calendarDao.getOrCreateSettings();
      final calendarConfig = CalendarConfig(
        sasanaYearType: calendarSettings.sasanaYearType,
        calendarType: 0,
        gregorianStart: calendarSettings.gregorianStart,
        timezoneOffset: calendarSettings.timezoneOffset,
        defaultLanguage: calendarSettings.defaultLanguage,
      );

      // Get display preferences
      final showHolidays = _parseBool(
        settings[StorageKeys.showHolidays] ?? 'true',
      );
      final showAnniversaryDays = _parseBool(
        settings[StorageKeys.showAnniversaryDays] ?? 'true',
      );
      final showSabbaths = _parseBool(
        settings[StorageKeys.showSabbaths] ?? 'true',
      );
      final showAstrology = _parseBool(
        settings[StorageKeys.showAstrology] ?? 'true',
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
      ColorScheme themeColors = themeMode == ThemeMode.dark
          ? preset.darkColors
          : preset.lightColors;

      if (themePreset == "custom" && customColors != null) {
        try {
          final json = (jsonDecode(customColors) as Map<String, dynamic>);
          themeColors = AppColorSchemes.fromMap(json);
        } catch (e) {
          log(e.toString());
        }
      }

      // Parse analytics consent
      final enableAnalytics = _parseBool(
        settings[StorageKeys.enableAnalytics] ?? 'true',
      );
      final enableCrashlytics = _parseBool(
        settings[StorageKeys.enableCrashlytics] ?? 'true',
      );

      // Check if consent dialog has been shown
      final hasShownConsentDialog = _parseBool(
        settings[StorageKeys.hasShownConsentDialog] ?? 'false',
      );

      final showShanCalendar = _parseBool(
        settings[StorageKeys.showShanCalendar] ?? 'true',
      );

      return Right(
        AppSettingsEntity(
          themeMode: themeMode,
          themePreset: themePreset,
          appIcon: appIcon,
          customColors: themeColors,
          appLanguage: appLanguage,
          calendarLanguage: calendarLanguage,
          calendarConfig: calendarConfig,
          showHolidays: showHolidays,
          showAnniversaryDays: showAnniversaryDays,
          showSabbaths: showSabbaths,
          showAstrology: showAstrology,
          showWesternDates: showWesternDates,
          showMyanmarDates: showMyanmarDates,
          firstDayOfWeek: firstDayOfWeek,
          enableAnalytics: enableAnalytics,
          enableCrashlytics: enableCrashlytics,
          hasShownConsentDialog: hasShownConsentDialog,
          showShanCalendar: showShanCalendar,
          useDeviceTimezone: useDeviceTimezone,
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
  Future<Either<Failure, void>> updateAppIcon(String appIconId) async {
    try {
      await localDataSource.setSetting(StorageKeys.appIcon, appIconId);
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
      final scheme = AppColorSchemes.fromCustomColor(colors);
      final json = jsonEncode(scheme.toMap());
      await localDataSource.setSetting(StorageKeys.customColors, json);
      await localDataSource.setSetting(StorageKeys.themePreset, 'custom');

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

      // Store in SharedPreferences to access from background isolates
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.calendarLanguage, language.code);

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
          calendarType: const Value(0),
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
      if (key == StorageKeys.useDeviceTimezone) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(StorageKeys.useDeviceTimezone, value);
      }

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.useDeviceTimezone, true);

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

  @override
  Future<Either<Failure, void>> updateAnalyticsConsent(
    bool enableAnalytics,
  ) async {
    try {
      await localDataSource.setSetting(
        StorageKeys.enableAnalytics,
        enableAnalytics.toString(),
      );

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCrashlyticsConsent(
    bool enableCrashlytics,
  ) async {
    try {
      await localDataSource.setSetting(
        StorageKeys.enableCrashlytics,
        enableCrashlytics.toString(),
      );

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markConsentDialogShown() async {
    try {
      await localDataSource.setSetting(
        StorageKeys.hasShownConsentDialog,
        'true',
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
