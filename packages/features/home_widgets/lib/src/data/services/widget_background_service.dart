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
    try {
      // Initialize Flutter binding for background task
      WidgetsFlutterBinding.ensureInitialized();

      // Configure Myanmar Calendar with defaults
      // Note: We can't access database in background isolate
      MyanmarCalendar.configure(
        language: Language.myanmar, // Use default or from inputData
        timezoneOffset: 6.5,
        sasanaYearType: 0,
        calendarType: 0,
        gregorianStart: 2361222,
      );

      debugPrint('✅ Myanmar Calendar configured in background');

      // Initialize shared preferences for background
      final prefs = await SharedPreferences.getInstance();

      // Create data source with prefs
      final dataSource = WidgetLocalDataSource(prefs);

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

      debugPrint('✅ Background widget update completed');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Background task failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  });
}
