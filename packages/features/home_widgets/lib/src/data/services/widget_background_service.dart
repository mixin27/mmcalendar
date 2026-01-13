import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../datasources/widget_local_datasource.dart';

/// Background service for updating widgets
/// This runs independently of the Flutter app
///
/// IMPORTANT: This must be a top-level function, not inside a class
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 Background task started: $task');
    final startTime = DateTime.now();

    try {
      // Initialize Flutter binding for background task
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize shared preferences for background
      final prefs = await SharedPreferences.getInstance();
      final languageCode =
          prefs.getString(StorageKeys.calendarLanguage) ??
          Language.myanmar.code;

      // Create data source with prefs
      final dataSource = WidgetLocalDataSource(prefs);

      // Configure Myanmar Calendar with defaults
      // Note: We can't access database in background isolate
      MyanmarCalendar.configure(
        language: Language.fromCode(
          languageCode,
        ), // Use default or from inputData
        timezoneOffset: 6.5,
        sasanaYearType: 0,
        calendarType: 0,
        gregorianStart: 2361222,
        customHolidays: [],
      );

      MyanmarCalendar.clearCache();
      MyanmarCalendar.configureCache(const CacheConfig.memoryEfficient());

      debugPrint('✅ Myanmar Calendar configured in background');

      // Get today's date
      final today = DateTime.now();
      debugPrint('📅 Updating widget for date: $today');

      // Generate widget data
      final config = await dataSource.getWidgetConfig();
      final widgetData = await dataSource.generateWidgetDataWithLanguage(
        today,
        config.language,
      );

      // Update widget
      await dataSource.updateWidgetWithConfig(widgetData, config);

      // Calculate execution time
      final duration = DateTime.now().difference(startTime);

      // Log success to SharedPreferences
      await _logBackgroundSuccess(prefs, task, duration);

      debugPrint('✅ Background widget update completed');
      return true;
    } catch (e, stackTrace) {
      // Log error to SharedPreferences (instead of Firebase Crashlytics)
      final duration = DateTime.now().difference(startTime);
      await _logBackgroundError(e, stackTrace, task, duration);

      debugPrint('❌ Background task failed: $e');
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

    debugPrint('📝 Background success logged to SharedPreferences');
  } catch (e) {
    debugPrint('⚠️ Failed to log background success: $e');
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

    debugPrint('📝 Background error logged to SharedPreferences');
  } catch (e) {
    debugPrint('⚠️ Failed to log background error: $e');
  }
}
