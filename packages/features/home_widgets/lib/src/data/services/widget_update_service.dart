import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../domain/entities/widget_config.dart';
import '../../domain/entities/widget_data.dart';
import '../../presentation/widgets/moon_phase_widget.dart';

class WidgetUpdateService {
  /// Update all widgets with new data
  ///
  /// This method prepares and sends data to ALL widget providers:
  /// - CompactDateWidgetProvider
  /// - FullCalendarWidgetProvider
  /// - MoonPhaseWidgetProvider
  /// - MonthlyCalendarWidgetProvider
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
      );

      final moonImagePath = await _renderMoonPhaseImage(
        data.moonPhaseValue,
        data.fortnightDay,
        size: 90,
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
      // await _updateMonthlyCalendarWidget();

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
    await HomeWidget.saveWidgetData<String>(
      'fortnight_day',
      data.fortnightDay.toString(),
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
        moonImagePath,
      );
    }

    // Configuration
    await HomeWidget.saveWidgetData<bool>('show_holidays', true);
    await HomeWidget.saveWidgetData<bool>('show_astrology', true);
    await HomeWidget.saveWidgetData<bool>('show_last_updated', false);
    // Save widget configuration preferences
    await HomeWidget.saveWidgetData<String>('widget_theme', config.theme.name);
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

  /// Update monthly calendar widget
  // ignore: unused_element
  static Future<void> _updateMonthlyCalendarWidget() async {
    try {
      await HomeWidget.updateWidget(
        androidName: 'MonthlyCalendarWidgetProvider',
        iOSName: 'MonthlyCalendarWidget',
      );
      debugPrint('✅ Monthly calendar widget updated');
    } catch (e) {
      debugPrint('⚠️ Error updating monthly calendar widget: $e');
    }
  }

  /// Render moon phase image
  static Future<String?> _renderMoonPhaseImage(
    int moonPhase,
    int fortnightDay, {
    double size = 120,
  }) async {
    try {
      final moonWidget = Container(
        width: size,
        height: size,
        color: Colors.transparent,
        child: MoonPhaseWidget(
          moonPhase: moonPhase,
          size: 120,
          moonColor: const Color(0xFFF5F5DC),
          shadowColor: const Color(0xFF2C2C2C),
          showGlow: false,
        ),
      );

      final imagePath = await HomeWidget.renderFlutterWidget(
        moonWidget,
        key: 'moon_phase_image',
        logicalSize: const Size(120, 120),
        pixelRatio: 3.0,
      );

      return imagePath;
    } catch (e) {
      debugPrint('❌ Error rendering moon phase: $e');
      return null;
    }
  }

  /// Format timestamp for display
  static String _formatTimestamp(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  /// Get all installed widget IDs
  Future<Map<String, List<int>>> getInstalledWidgets() async {
    try {
      // This would need platform-specific implementation
      // For now, just check if any widgets exist
      final widgetIds = await HomeWidget.getInstalledWidgets();
      return {'all': widgetIds.map((e) => e.androidWidgetId!).toList()};
    } catch (e) {
      debugPrint('⚠️ Error getting installed widgets: $e');
      return {};
    }
  }

  /// Check if specific widget type is installed
  Future<bool> isWidgetInstalled(String widgetType) async {
    try {
      final widgets = await getInstalledWidgets();
      return widgets['all']?.isNotEmpty ?? false;
    } catch (e) {
      debugPrint('⚠️ Error checking widget installation: $e');
      return false;
    }
  }
}
