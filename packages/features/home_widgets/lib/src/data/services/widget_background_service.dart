import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:holidays/holidays.dart';

import '../datasources/widget_local_datasource.dart';
import '../../home_widget_configuration.dart';

/// Background service for updating widgets
/// This runs independently of the Flutter app
///
/// IMPORTANT: This must be a top-level function, not inside a class
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task started: $task');
    final startTime = DateTime.now();

    try {
      // Initialize Flutter binding for background task
      WidgetsFlutterBinding.ensureInitialized();

      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId(homeWidgetAppGroupId);
      }

      final prefs = await SharedPreferences.getInstance();
      final languageCode =
          prefs.getString(StorageKeys.calendarLanguage) ??
          Language.myanmar.code;
      final useDeviceTimezone =
          prefs.getBool(StorageKeys.useDeviceTimezone) ?? true;

      // The app caches its calendar settings and holiday overrides (from
      // Remote Config, which this isolate can't reach), so background data
      // matches the app's.
      final cached = WidgetBackgroundCache.read(prefs);
      final holidays = HolidayService(
        holidayConfigPort: _CachedHolidayConfig(cached.holidayConfig),
      );
      applyMyanmarCalendarRuntimeConfig(
        baseConfig: cached.calendarConfig,
        language: Language.fromCode(languageCode),
        useDeviceTimezone: useDeviceTimezone,
        customHolidayRules: holidays.getCustomHolidayRules(),
        disabledHolidays: holidays.getDisabledHolidays(),
        disabledHolidaysByYear: holidays.getDisabledHolidaysByYear(),
        disabledHolidaysByDate: holidays.getDisabledHolidaysByDate(),
        cacheProfile: MyanmarCalendarCacheProfile.memoryEfficient,
      );

      // Events can't be read here; the last ones the app wrote are kept.
      await WidgetLocalDataSource(prefs).writePayload();

      // Calculate execution time
      final duration = DateTime.now().difference(startTime);

      // Log success to SharedPreferences
      await _logBackgroundSuccess(prefs, task, duration);

      debugPrint('Background widget update completed');
      return true;
    } catch (e, stackTrace) {
      // Log error to SharedPreferences (instead of Firebase Crashlytics)
      final duration = DateTime.now().difference(startTime);
      await _logBackgroundError(e, stackTrace, task, duration);

      debugPrint('Background task failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  });
}

/// Log background task success to SharedPreferences
Future<void> _logBackgroundSuccess(
  SharedPreferences prefs,
  String task,
  Duration duration,
) async {
  try {
    final timestamp = DateTime.now().toIso8601String();

    // Store last successful update
    await prefs.setString('last_background_update', timestamp);
    await prefs.setString('last_background_task', task);
    await prefs.setInt('last_background_duration_ms', duration.inMilliseconds);
    await prefs.setInt(
      'background_success_count',
      (prefs.getInt('background_success_count') ?? 0) + 1,
    );

    // Store logs for syncing (max 10 recent logs)
    final logs = prefs.getStringList('background_logs') ?? [];
    logs.add('SUCCESS|$task|$timestamp|${duration.inMilliseconds}ms');
    if (logs.length > 10) {
      logs.removeAt(0); // Remove oldest
    }
    await prefs.setStringList('background_logs', logs);

    debugPrint('Background success logged to SharedPreferences');
  } catch (e) {
    debugPrint('Failed to log background success: $e');
  }
}

/// Log background task error to SharedPreferences
Future<void> _logBackgroundError(
  dynamic error,
  StackTrace stackTrace,
  String task,
  Duration duration,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();
    final errorMsg = error.toString();
    final stackMsg = stackTrace
        .toString()
        .split('\n')
        .take(5)
        .join('\n'); // First 5 lines

    // Store last error
    await prefs.setString('last_background_error', errorMsg);
    await prefs.setString('last_background_error_stack', stackMsg);
    await prefs.setString('last_background_error_time', timestamp);
    await prefs.setInt(
      'background_error_count',
      (prefs.getInt('background_error_count') ?? 0) + 1,
    );

    // Store error logs for syncing (max 5 recent errors)
    final errorLogs = prefs.getStringList('background_error_logs') ?? [];
    errorLogs.add(
      'ERROR|$task|$timestamp|$errorMsg|${duration.inMilliseconds}ms',
    );
    if (errorLogs.length > 5) {
      errorLogs.removeAt(0); // Remove oldest
    }
    await prefs.setStringList('background_error_logs', errorLogs);

    debugPrint('Background error logged to SharedPreferences');
  } catch (e) {
    debugPrint('Failed to log background error: $e');
  }
}

class _CachedHolidayConfig implements HolidayConfigPort {
  const _CachedHolidayConfig(this.config);
  final Map<String, dynamic> config;

  @override
  Map<String, dynamic> getHolidayConfig() => config;
}

/// Calendar settings and holiday overrides the app saves for background
/// widget refreshes.
abstract final class WidgetBackgroundCache {
  static const _calendarKey = 'widget_calendar_config_v1';
  static const _holidaysKey = 'widget_holiday_config_v1';

  static Future<void> save(
    SharedPreferences prefs, {
    required CalendarConfig calendarConfig,
    required Map<String, dynamic> holidayConfig,
  }) async {
    await prefs.setString(
      _calendarKey,
      jsonEncode({
        'sasanaYearType': calendarConfig.sasanaYearType,
        'calendarType': calendarConfig.calendarType,
        'gregorianStart': calendarConfig.gregorianStart,
        'timezoneOffset': calendarConfig.timezoneOffset,
        'defaultLanguage': calendarConfig.defaultLanguage,
      }),
    );
    await prefs.setString(_holidaysKey, jsonEncode(holidayConfig));
  }

  static ({CalendarConfig calendarConfig, Map<String, dynamic> holidayConfig})
  read(SharedPreferences prefs) {
    var calendar = const CalendarConfig();
    var holidays = <String, dynamic>{};
    try {
      final raw = prefs.getString(_calendarKey);
      if (raw != null) {
        final c = jsonDecode(raw) as Map<String, dynamic>;
        calendar = CalendarConfig(
          sasanaYearType: c['sasanaYearType'] as int? ?? 0,
          calendarType: c['calendarType'] as int? ?? 0,
          gregorianStart: c['gregorianStart'] as int? ?? 2361222,
          timezoneOffset: (c['timezoneOffset'] as num?)?.toDouble() ?? 6.5,
          defaultLanguage: c['defaultLanguage'] as String? ?? 'en',
        );
      }
      final rawHolidays = prefs.getString(_holidaysKey);
      if (rawHolidays != null) {
        holidays = jsonDecode(rawHolidays) as Map<String, dynamic>;
      }
    } catch (_) {
      // Defaults: no overrides.
    }
    return (calendarConfig: calendar, holidayConfig: holidays);
  }
}
