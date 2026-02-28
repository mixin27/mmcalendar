import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, AppSettingsEntity>> getSettings();
  Future<Either<Failure, void>> updateThemeMode(ThemeMode themeMode);
  Future<Either<Failure, void>> updateThemePreset(String presetId);
  Future<Either<Failure, void>> updateCustomColors(ColorScheme colors);
  Future<Either<Failure, void>> updateAppLanguage(String languageCode);
  Future<Either<Failure, void>> updateCalendarLanguage(Language language);
  Future<Either<Failure, void>> updateCalendarConfig(CalendarConfig config);
  Future<Either<Failure, void>> updateDisplayPreference(String key, bool value);
  Future<Either<Failure, void>> resetSettings();
  Future<Either<Failure, void>> updateAnalyticsConsent(bool enableAnalytics);
  Future<Either<Failure, void>> updateCrashlyticsConsent(
    bool enableCrashlytics,
  );
  Future<Either<Failure, void>> markConsentDialogShown();
}
