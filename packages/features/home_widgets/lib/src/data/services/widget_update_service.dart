import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../domain/entities/widget_config.dart';
import '../../domain/entities/widget_data.dart';

class WidgetUpdateService {
  static const String timelineStorageKey = 'widget_timeline_v1';
  static const String monthTimelineStorageKey = 'widget_month_timeline_v1';

  /// Update all widgets with new data
  ///
  /// This method prepares and sends data to ALL widget providers:
  /// - CompactDateWidgetProvider
  /// - FullCalendarWidgetProvider
  /// - MoonPhaseWidgetProvider
  /// - MyanmarMonthWidgetProvider
  static Future<void> updateAllWidgets(
    WidgetData data,
    WidgetConfig config,
  ) async {
    try {
      debugPrint('📱 Updating all widgets...');

      // 1. Render moon phase image (needed by multiple widgets)
      final fullMoonImagePath = await _renderMoonPhaseImage(
        data.moonPhaseValue,
        data.fortnightDay,
        storageKey: 'moon_phase_image_large',
      );

      final moonImagePath = await _renderMoonPhaseImage(
        data.moonPhaseValue,
        data.fortnightDay,
        size: 90,
        storageKey: 'moon_phase_image_small',
      );

      // 2. Save common data (all widgets use this)
      await _saveCommonData(
        data,
        config,
        moonImagePath: moonImagePath,
        fullMoonImagePath: fullMoonImagePath,
      );

      // 3. Update each widget provider
      await _updateCompactWidget();
      await _updateFullCalendarWidget();
      await _updateMoonPhaseWidget();
      await _updateMyanmarMonthWidget();

      debugPrint('✅ All widgets updated successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating widgets: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Save data that's common to all widgets
  static Future<void> _saveCommonData(
    WidgetData data,
    WidgetConfig config, {
    String? fullMoonImagePath,
    String? moonImagePath,
  }) async {
    // Basic date data
    await HomeWidget.saveWidgetData<String>('myanmar_date', data.myanmarDate);
    await HomeWidget.saveWidgetData<String>('western_date', data.westernDate);
    await HomeWidget.saveWidgetData<String>('moon_phase', data.moonPhase);
    await HomeWidget.saveWidgetData<String>(
      'moon_phase_emoji',
      data.moonPhaseEmoji,
    );
    await HomeWidget.saveWidgetData<int>(
      'moon_phase_value',
      data.moonPhaseValue,
    );
    await HomeWidget.saveWidgetData<String>(
      'fortnight_day',
      data.fortnightDay.toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      'fortnight_day_text',
      data.fortnightDayText,
    );

    // Optional data
    await HomeWidget.saveWidgetData<String>(
      'holidays',
      data.holidays.join(', '),
    );
    await HomeWidget.saveWidgetData<String>(
      'sabbath_info',
      data.sabbathInfo ?? '',
    );
    await HomeWidget.saveWidgetData<String>(
      'yatyaza_info',
      data.yatyazaInfo ?? '',
    );
    await HomeWidget.saveWidgetData<String>(
      'pyathada_info',
      data.pyathadaInfo ?? '',
    );
    await HomeWidget.saveWidgetData<String>(
      'astrological_days',
      data.astrologicalDays.join(', '),
    );

    await HomeWidget.saveWidgetData<String>(
      'weekday_names',
      data.weekdayNames.join(', '),
    );
    await HomeWidget.saveWidgetData<String>(
      'moon_phase_names',
      data.moonPhaseNames.join(', '),
    );

    // Timestamp
    await HomeWidget.saveWidgetData<String>(
      'last_updated',
      _formatTimestamp(data.lastUpdated),
    );

    // Moon image path
    if (moonImagePath != null && moonImagePath.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>(
        'moon_phase_image_path',
        moonImagePath,
      );
    }
    if (fullMoonImagePath != null && fullMoonImagePath.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>(
        'full_moon_phase_image_path',
        fullMoonImagePath,
      );
    }

    await HomeWidget.saveWidgetData<String>(
      'next_moon_phase',
      data.nextMoonPhase,
    );

    // Configuration
    await HomeWidget.saveWidgetData<bool>('show_holidays', config.showHolidays);
    await HomeWidget.saveWidgetData<bool>(
      'show_astrology',
      config.showAstrology,
    );
    await HomeWidget.saveWidgetData<bool>('show_last_updated', false);
    await HomeWidget.saveWidgetData<bool>(
      'show_myanmar_date',
      config.showMyanmarDate,
    );
    await HomeWidget.saveWidgetData<bool>(
      'show_western_date',
      config.showWesternDate,
    );
    // Save widget configuration preferences
    await HomeWidget.saveWidgetData<String>('widget_size', config.size.name);
    await HomeWidget.saveWidgetData<String>('widget_theme', config.theme.name);
    await HomeWidget.saveWidgetData<String>(
      'calendar_language',
      config.language,
    );
    await HomeWidget.saveWidgetData<String>('widget_language', config.language);
  }

  /// Update compact date widget
  static Future<void> _updateCompactWidget() async {
    try {
      await HomeWidget.updateWidget(
        androidName: 'CompactDateWidgetProvider',
        iOSName: 'CompactDateWidget',
      );
      debugPrint('✅ Compact widget updated');
    } catch (e) {
      debugPrint('⚠️ Error updating compact widget: $e');
    }
  }

  /// Update full calendar widget
  static Future<void> _updateFullCalendarWidget() async {
    try {
      await HomeWidget.updateWidget(
        androidName: 'FullCalendarWidgetProvider',
        iOSName: 'FullCalendarWidget',
      );
      debugPrint('✅ Full calendar widget updated');
    } catch (e) {
      debugPrint('⚠️ Error updating full calendar widget: $e');
    }
  }

  /// Update moon phase widget
  static Future<void> _updateMoonPhaseWidget() async {
    try {
      await HomeWidget.updateWidget(
        androidName: 'MoonPhaseWidgetProvider',
        iOSName: 'MoonPhaseWidget',
      );
      debugPrint('✅ Moon phase widget updated');
    } catch (e) {
      debugPrint('⚠️ Error updating moon phase widget: $e');
    }
  }

  /// Update Myanmar month widget
  static Future<void> _updateMyanmarMonthWidget() async {
    try {
      await HomeWidget.updateWidget(
        androidName: 'MyanmarMonthWidgetProvider',
        iOSName: 'MyanmarMonthWidget',
      );
      debugPrint('✅ Myanmar month widget updated');
    } catch (e) {
      debugPrint('⚠️ Error updating Myanmar month widget: $e');
    }
  }

  /// Render moon phase image
  static Future<String?> _renderMoonPhaseImage(
    int moonPhase,
    int fortnightDay, {
    double size = 120,
    String storageKey = 'moon_phase_image',
  }) async {
    try {
      final moonWidget = Container(
        width: size,
        height: size,
        color: Colors.transparent,
        child: MoonPhaseVisual(
          moonPhase: moonPhase,
          fortnightDay: fortnightDay,
          size: size,
          moonColor: const Color(0xFFF5F5DC),
          shadowColor: const Color(0xFF2C2C2C),
          showGlow: false,
          widgetMode: true,
        ),
      );

      final imagePath = await HomeWidget.renderFlutterWidget(
        moonWidget,
        key: storageKey,
        logicalSize: Size(size, size),
        pixelRatio: 3.0,
      );

      return imagePath;
    } catch (e) {
      debugPrint('❌ Error rendering moon phase: $e');
      return null;
    }
  }

  /// Render moon phase image that can be reused by timeline entries.
  static Future<String?> renderMoonPhaseImage(
    int moonPhase,
    int fortnightDay, {
    double size = 120,
    required String storageKey,
  }) {
    return _renderMoonPhaseImage(
      moonPhase,
      fortnightDay,
      size: size,
      storageKey: storageKey,
    );
  }

  /// Save timeline payload used by native widget providers to read daily data
  /// without requiring a Dart background task at midnight.
  static Future<void> saveTimelinePayload(String timelineJson) async {
    await HomeWidget.saveWidgetData<String>(timelineStorageKey, timelineJson);
  }

  /// Save month timeline payload used by Myanmar month widget provider.
  static Future<void> saveMonthTimelinePayload(String timelineJson) async {
    await HomeWidget.saveWidgetData<String>(
      monthTimelineStorageKey,
      timelineJson,
    );
  }

  /// Format timestamp for display
  static String _formatTimestamp(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}
