import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:home_widgets/src/domain/entities/widget_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../domain/entities/widget_config.dart';
import '../services/myanmar_month_widget_service.dart';
import '../services/widget_update_service.dart';

class WidgetLocalDataSource {
  static const String _configKey = 'widget_config';
  static const String _updateTaskName = 'widget_update_task';

  final SharedPreferences sharedPreferences;

  WidgetLocalDataSource(this.sharedPreferences);

  /// Update widget with custom configuration
  Future<void> updateWidgetWithConfig(
    WidgetData data,
    WidgetConfig config,
  ) async {
    await WidgetUpdateService.updateAllWidgets(data, config);

    await MyanmarMonthWidgetService.updateMyanmarMonthWidget(
      DateTime.now(),
      config,
    );
  }

  /// Generate widget data with specific language
  Future<WidgetData> generateWidgetDataWithLanguage(
    DateTime date,
    String languageCode,
  ) async {
    try {
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
      final yat = TranslationService.translate('Yat');
      final myanmarDate =
          '${myanmarDateTime.formatMyanmar('&y &M &P &f')} $yat';
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

      final weekdayNames = _getWeekdayNames(targetLanguage);
      final moonPhaseNames = _getMoonPhaseNames(targetLanguage);

      final nextMoonPhase = _findNextMoonPhase(myanmarDateTime, targetLanguage);
      final fortnightDayText = myanmarDateTime.formatMyanmar(
        "&ff",
        targetLanguage,
      );

      return WidgetData(
        myanmarDate: myanmarDate,
        westernDate: westernDate,
        moonPhase: moonPhase,
        moonPhaseValue: myanmarDateTime.moonPhase,
        moonPhaseEmoji: moonPhaseEmoji,
        fortnightDay: myanmarDateTime.fortnightDay,
        fortnightDayText: fortnightDayText,
        holidays: holidays,
        astrologicalDays: astrologicalDays,
        sabbathInfo: sabbathInfo,
        yatyazaInfo: yatyazaInfo,
        pyathadaInfo: pyathadaInfo,
        lastUpdated: DateTime.now(),
        weekdayNames: weekdayNames,
        moonPhaseNames: moonPhaseNames,
        nextMoonPhase: nextMoonPhase,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating widget data with language: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
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

  List<String> _getWeekdayNames(Language language) {
    List<String> items = List.empty(growable: true);
    for (var i = 0; i < 7; i++) {
      final myanmarWeekdayIndex = (1 + i) % 7;
      final weekdayName = TranslationService.getShortWeekdayName(
        myanmarWeekdayIndex,
        language,
      );
      items.add(weekdayName);
    }

    return items;
  }

  List<String> _getMoonPhaseNames(Language language) {
    List<String> items = List.empty(growable: true);
    for (var i = 0; i < 4; i++) {
      final name = _getMoonPhaseName(i, language);
      items.add(name);
    }
    return items;
  }

  String _findNextMoonPhase(MyanmarDateTime date, Language language) {
    final nextFullMoonPhaseDate = MyanmarCalendar.findNextMoonPhase(date, 1);

    final nextNewMoonPhaseDate = MyanmarCalendar.findNextMoonPhase(date, 3);

    // Calculate days from start
    var daysFromStart = 0;
    var moonPhaseName = TranslationService.translateTo("Full Moon", language);
    if (date.moonPhase == 0) {
      daysFromStart = MyanmarCalendar.daysBetween(date, nextFullMoonPhaseDate);
    } else if (date.moonPhase == 2) {
      daysFromStart = MyanmarCalendar.daysBetween(date, nextNewMoonPhaseDate);
      moonPhaseName = TranslationService.translateTo('New Moon', language);
    }

    return "$moonPhaseName in ${daysFromStart}d";
  }
}
