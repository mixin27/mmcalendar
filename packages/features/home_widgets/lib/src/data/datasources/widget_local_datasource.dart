import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:home_widgets/src/domain/entities/widget_data.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../domain/entities/widget_config.dart';
import '../../presentation/widgets/moon_phase_widget.dart';

class WidgetLocalDataSource {
  static const String _configKey = 'widget_config';
  static const String _updateTaskName = 'widget_update_task';

  // Widget data keys - MUST match Android code
  static const String _myanmarDateKey = 'myanmar_date';
  static const String _westernDateKey = 'western_date';
  static const String _moonPhaseKey = 'moon_phase';
  static const String _moonPhaseEmojiKey = 'moon_phase_emoji';
  static const String _holidaysKey = 'holidays';
  static const String _astrologicalDaysKey = 'astrological_days';
  static const String _sabbathInfoKey = 'sabbath_info';
  static const String _yatyazaInfoKey = 'yatyaza_info';
  static const String _pyathadaInfoKey = 'pyathada_info';
  static const String _lastUpdatedKey = 'last_updated';

  final SharedPreferences sharedPreferences;

  WidgetLocalDataSource(this.sharedPreferences);

  /// Update widget with custom configuration
  Future<void> updateWidgetWithConfig(
    WidgetData data,
    WidgetConfig config,
  ) async {
    try {
      debugPrint('🔄 Updating widget with custom config...');
      debugPrint('📝 Config: ${config.toJson()}');

      final moonImagePath = await _renderMoonPhaseImage(
        data.moonPhaseValue,
        data.fortnightDay,
      );
      debugPrint('🎨 Moon image path: $moonImagePath');

      // Save basic data
      await HomeWidget.saveWidgetData<String>(
        _myanmarDateKey,
        config.showMyanmarDate ? data.myanmarDate : '',
      );
      await HomeWidget.saveWidgetData<String>(
        _westernDateKey,
        config.showWesternDate ? data.westernDate : '',
      );
      await HomeWidget.saveWidgetData<String>(_moonPhaseKey, data.moonPhase);
      await HomeWidget.saveWidgetData<String>(
        _moonPhaseEmojiKey,
        data.moonPhaseEmoji,
      );

      // Conditional data based on config
      if (config.showHolidays && data.holidays.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>(
          _holidaysKey,
          data.holidays.join(', '),
        );
      } else {
        await HomeWidget.saveWidgetData<String>(_holidaysKey, '');
      }

      if (config.showAstrology) {
        await HomeWidget.saveWidgetData<String>(
          _sabbathInfoKey,
          data.sabbathInfo ?? '',
        );
        await HomeWidget.saveWidgetData<String>(
          _yatyazaInfoKey,
          data.yatyazaInfo ?? '',
        );
        await HomeWidget.saveWidgetData<String>(
          _pyathadaInfoKey,
          data.pyathadaInfo ?? '',
        );
        await HomeWidget.saveWidgetData<String>(
          _astrologicalDaysKey,
          data.astrologicalDays.join(', '),
        );
      } else {
        await HomeWidget.saveWidgetData<String>(_sabbathInfoKey, '');
        await HomeWidget.saveWidgetData<String>(_yatyazaInfoKey, '');
        await HomeWidget.saveWidgetData<String>(_pyathadaInfoKey, '');
        await HomeWidget.saveWidgetData<String>(_astrologicalDaysKey, '');
      }

      // Save widget configuration preferences
      await HomeWidget.saveWidgetData<String>('widget_size', config.size.name);
      await HomeWidget.saveWidgetData<String>(
        'widget_theme',
        config.theme.name,
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_language',
        config.language,
      );

      final dateStr = DateFormat(
        "yyyy-MM-dd hh:mm aaa",
      ).format(data.lastUpdated);
      await HomeWidget.saveWidgetData<String>(_lastUpdatedKey, dateStr);

      if (moonImagePath != null && moonImagePath.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>(
          'moon_phase_image_path',
          moonImagePath,
        );
        debugPrint('✅ Moon phase image path saved: $moonImagePath');
      } else {
        debugPrint('⚠️ No moon phase image path to save');
      }

      // Trigger widget update
      await HomeWidget.updateWidget(
        androidName: 'AppHomeWidgetProvider',
        iOSName: 'HomeWidget',
      );

      debugPrint('✅ Widget updated with config');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to update widget with config: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate widget data from Myanmar Calendar
  Future<WidgetData> generateWidgetData(DateTime date) async {
    try {
      debugPrint('🔄 Generating widget data for $date');

      // Get Myanmar calendar date info
      final myanmarDateTime = MyanmarCalendar.fromWestern(
        date.year,
        date.month,
        date.day,
      );

      // Format dates
      final myanmarDate = myanmarDateTime.formatMyanmar('&y &M &P &f');
      final westernDate = myanmarDateTime.formatWestern('%d %M %yyyy');

      debugPrint('📅 Myanmar Date: $myanmarDate');
      debugPrint('📅 Western Date: $westernDate');

      // Get moon phase
      final moonPhase = _getMoonPhaseName(
        myanmarDateTime.moonPhase,
        Language.myanmar,
      );
      final moonPhaseEmoji = _getMoonPhaseEmoji(myanmarDateTime.moonPhase);

      // Get holidays
      final allHolidays = [
        ...myanmarDateTime.allHolidays,
        ...myanmarDateTime.allAnniversaryDays,
      ];
      final holidays = allHolidays;

      // Get astrology info
      String? sabbathInfo;
      String? yatyazaInfo;
      String? pyathadaInfo;

      if (myanmarDateTime.isSabbath || myanmarDateTime.isSabbathEve) {
        sabbathInfo = myanmarDateTime.sabbath;
      }

      if (myanmarDateTime.isYatyaza) {
        yatyazaInfo = myanmarDateTime.yatyaza;
      }

      if (myanmarDateTime.hasPyathada) {
        pyathadaInfo = myanmarDateTime.pyathada;
      }

      final widgetData = WidgetData(
        myanmarDate: myanmarDate,
        westernDate: westernDate,
        moonPhase: moonPhase,
        moonPhaseValue: myanmarDateTime.moonPhase,
        moonPhaseEmoji: moonPhaseEmoji,
        fortnightDay: myanmarDateTime.fortnightDay,
        holidays: holidays,
        astrologicalDays: myanmarDateTime.astrologicalDays,
        sabbathInfo: sabbathInfo,
        yatyazaInfo: yatyazaInfo,
        pyathadaInfo: pyathadaInfo,
        lastUpdated: DateTime.now(),
      );

      debugPrint('✅ Widget data generated successfully');
      return widgetData;
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating widget data: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate widget data with specific language
  Future<WidgetData> generateWidgetDataWithLanguage(
    DateTime date,
    String languageCode,
  ) async {
    try {
      debugPrint(
        '🔄 Generating widget data for $date in language: $languageCode',
      );

      // Temporarily set language
      final currentLanguage = MyanmarCalendar.currentLanguage;
      final targetLanguage = Language.fromCode(languageCode);

      if (currentLanguage != targetLanguage) {
        MyanmarCalendar.setLanguage(targetLanguage);
      }

      // Get Myanmar calendar date info
      final myanmarDateTime = MyanmarCalendar.fromWestern(
        date.year,
        date.month,
        date.day,
      );

      // Format dates with correct language
      final myanmarDate = myanmarDateTime.formatMyanmar('&y &M &P &f');
      final westernDate = myanmarDateTime.formatWestern('%d %M %yyyy');

      // Get moon phase
      final moonPhase = _getMoonPhaseName(
        myanmarDateTime.moonPhase,
        targetLanguage,
      );
      final moonPhaseEmoji = _getMoonPhaseEmoji(myanmarDateTime.moonPhase);

      // Get holidays
      final allHolidays = [
        ...myanmarDateTime.allHolidays,
        ...myanmarDateTime.allAnniversaryDays,
      ];
      final holidays = allHolidays
          .map((h) => TranslationService.translateTo(h, targetLanguage))
          .toList();

      final astrologicalDays = myanmarDateTime.astrologicalDays
          .map((a) => TranslationService.translateTo(a, targetLanguage))
          .toList();

      // Get astrology info
      String? sabbathInfo;
      String? yatyazaInfo;
      String? pyathadaInfo;

      if (myanmarDateTime.isSabbath || myanmarDateTime.isSabbathEve) {
        sabbathInfo = TranslationService.translateTo(
          myanmarDateTime.sabbath,
          targetLanguage,
        );
      }

      if (myanmarDateTime.isYatyaza) {
        yatyazaInfo = TranslationService.translateTo(
          myanmarDateTime.yatyaza,
          targetLanguage,
        );
      }

      if (myanmarDateTime.hasPyathada) {
        pyathadaInfo = TranslationService.translateTo(
          myanmarDateTime.pyathada,
          targetLanguage,
        );
      }

      // Restore original language
      if (currentLanguage != targetLanguage) {
        MyanmarCalendar.setLanguage(currentLanguage);
      }

      return WidgetData(
        myanmarDate: myanmarDate,
        westernDate: westernDate,
        moonPhase: moonPhase,
        moonPhaseValue: myanmarDateTime.moonPhase,
        moonPhaseEmoji: moonPhaseEmoji,
        fortnightDay: myanmarDateTime.fortnightDay,
        holidays: holidays,
        astrologicalDays: astrologicalDays,
        sabbathInfo: sabbathInfo,
        yatyazaInfo: yatyazaInfo,
        pyathadaInfo: pyathadaInfo,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating widget data with language: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Update the home widget with new data
  Future<void> updateHomeWidget(WidgetData data) async {
    try {
      debugPrint('🔄 Updating home widget...');

      final moonImagePath = await _renderMoonPhaseImage(
        data.moonPhaseValue,
        data.fortnightDay,
      );
      debugPrint('🎨 Moon image path: $moonImagePath');

      // Save data to HomeWidget plugin storage
      // NOTE: Keys are automatically prefixed with 'flutter.' by the plugin
      await HomeWidget.saveWidgetData<String>(
        _myanmarDateKey,
        data.myanmarDate,
      );
      await HomeWidget.saveWidgetData<String>(
        _westernDateKey,
        data.westernDate,
      );
      await HomeWidget.saveWidgetData<String>(_moonPhaseKey, data.moonPhase);
      await HomeWidget.saveWidgetData<String>(
        _moonPhaseEmojiKey,
        data.moonPhaseEmoji,
      );
      await HomeWidget.saveWidgetData<String>(
        _holidaysKey,
        data.holidays.join(', '),
      );
      await HomeWidget.saveWidgetData<String>(
        _sabbathInfoKey,
        data.sabbathInfo ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        _yatyazaInfoKey,
        data.yatyazaInfo ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        _pyathadaInfoKey,
        data.pyathadaInfo ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        _lastUpdatedKey,
        data.lastUpdated.toIso8601String(),
      );

      if (moonImagePath != null && moonImagePath.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>(
          'moon_phase_image_path',
          moonImagePath,
        );
        debugPrint('✅ Moon phase image path saved: $moonImagePath');
      } else {
        debugPrint('⚠️ No moon phase image path to save');
      }

      debugPrint('✅ Widget data saved to SharedPreferences');

      // Trigger widget update
      final result = await HomeWidget.updateWidget(
        androidName:
            'AppHomeWidgetProvider', // Must match your Kotlin class name
        iOSName: 'HomeWidget',
      );

      if (result == true) {
        debugPrint('✅ Widget updated successfully');
      } else {
        debugPrint('⚠️ Widget update returned: $result');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to update widget: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to update widget: $e');
    }
  }

  /// Get widget configuration
  Future<WidgetConfig> getWidgetConfig() async {
    final configJson = sharedPreferences.getString(_configKey);
    if (configJson == null) {
      debugPrint('ℹ️ No saved config found, using defaults');
      return const WidgetConfig.defaults();
    }

    try {
      final config = json.decode(configJson) as Map<String, dynamic>;
      return WidgetConfig.fromJson(config);
    } catch (e) {
      debugPrint('⚠️ Error loading config, using defaults: $e');
      return const WidgetConfig.defaults();
    }
  }

  /// Save widget configuration
  Future<void> saveWidgetConfig(WidgetConfig config) async {
    final configJson = json.encode(config.toJson());
    await sharedPreferences.setString(_configKey, configJson);
    debugPrint('✅ Widget config saved');
  }

  /// Schedule periodic widget updates (daily at 12:01 AM)
  Future<void> scheduleUpdates() async {
    try {
      debugPrint('🔄 Scheduling widget updates...');

      // Cancel any existing tasks
      await Workmanager().cancelByUniqueName(_updateTaskName);

      // Calculate initial delay to reach 12:01 AM
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 1);
      final initialDelay = tomorrow.difference(now);

      debugPrint('⏰ Initial update will run at: $tomorrow');
      debugPrint('⏱️ Initial delay: ${initialDelay.inMinutes} minutes');

      // Schedule periodic task
      // NOTE: WorkManager 0.9.0+ handles initialization automatically
      await Workmanager().registerPeriodicTask(
        _updateTaskName,
        _updateTaskName,
        frequency: const Duration(hours: 24),
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      debugPrint('✅ Widget updates scheduled successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to schedule updates: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Cancel scheduled updates
  Future<void> cancelUpdates() async {
    try {
      await Workmanager().cancelByUniqueName(_updateTaskName);
      debugPrint('✅ Widget updates cancelled');
    } catch (e) {
      debugPrint('⚠️ Error cancelling updates: $e');
    }
  }

  /// Check if widget is active on home screen
  Future<bool> isWidgetActive() async {
    try {
      final widgetIds = await HomeWidget.getInstalledWidgets();

      final isActive = widgetIds.isNotEmpty;
      debugPrint('📊 Widget active: $isActive (${widgetIds.length} instances)');
      return isActive;
    } catch (e) {
      debugPrint('⚠️ Error checking widget status: $e');
      return false;
    }
  }

  /// Check if automatic updates are scheduled
  Future<bool> isUpdateScheduled() async {
    try {
      // WorkManager doesn't provide a direct way to check if a task is scheduled
      // We'll store this info in SharedPreferences
      return sharedPreferences.getBool('widget_updates_scheduled') ?? false;
    } catch (e) {
      debugPrint('⚠️ Error checking update schedule: $e');
      return false;
    }
  }

  /// Mark updates as scheduled
  Future<void> markUpdatesScheduled(bool scheduled) async {
    await sharedPreferences.setBool('widget_updates_scheduled', scheduled);
  }

  // Helper methods
  String _getMoonPhaseName(int moonPhase, Language language) {
    return TranslationService.getMoonPhaseName(moonPhase, language);
  }

  String _getMoonPhaseEmoji(int moonPhase) {
    switch (moonPhase) {
      case 0:
        return '🌒'; // Waxing crescent
      case 1:
        return '🌕'; // Full moon
      case 2:
        return '🌘'; // Waning crescent
      case 3:
        return '🌑'; // New moon
      default:
        return '🌙';
    }
  }

  /// Render moon phase using Flutter widget to PNG
  Future<String?> _renderMoonPhaseImage(int moonPhase, int fortnightDay) async {
    try {
      debugPrint('🎨 Starting moon phase rendering for phase: $moonPhase');

      // Create the moon phase widget
      final moonWidget = Container(
        width: 80,
        height: 80,
        color: Colors.transparent,
        child: MoonPhaseWidget(
          moonPhase: moonPhase,
          size: 80,
          moonColor: const Color(0xFFF5F5DC),
          shadowColor: const Color(0xFF2C2C2C),
          showGlow: true,
        ),
      );

      // Use HomeWidget's renderFlutterWidget
      final imagePath = await HomeWidget.renderFlutterWidget(
        moonWidget,
        key: 'moon_phase_image',
        logicalSize: const Size(80, 80),
        pixelRatio: 3.0,
      );

      if (imagePath.isNotEmpty) {
        debugPrint('✅ Moon phase rendered to: $imagePath');

        // Verify file exists
        final file = File(imagePath);
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('✅ Moon image file exists, size: $fileSize bytes');
        } else {
          debugPrint('⚠️ Moon image file does not exist at path');
        }

        return imagePath;
      } else {
        debugPrint('⚠️ renderFlutterWidget returned null or empty path');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error rendering moon phase: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
