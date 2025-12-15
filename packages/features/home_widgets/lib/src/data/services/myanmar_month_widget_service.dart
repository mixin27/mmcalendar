import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/widget_config.dart';

class MyanmarMonthWidgetService {
  /// Update Myanmar month widget with calendar grid data
  static Future<void> updateMyanmarMonthWidget(
    DateTime date,
    WidgetConfig config,
  ) async {
    try {
      debugPrint('📅 Generating Myanmar month data for: $date');

      // Generate Myanmar month data
      final monthData = await _generateMyanmarMonthData(date, config.language);

      // Convert to JSON
      final jsonData = _convertToJson(monthData);

      // Save to SharedPreferences
      await HomeWidget.saveWidgetData<String>('myanmar_month_data', jsonData);

      debugPrint('✅ Myanmar month data saved');

      // Trigger widget update
      await HomeWidget.updateWidget(
        androidName: 'MyanmarMonthWidgetProvider',
        iOSName: 'MyanmarMonthWidget',
      );

      debugPrint('✅ Myanmar month widget updated');
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating Myanmar month widget: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate Myanmar month calendar data
  static Future<MyanmarMonthData> _generateMyanmarMonthData(
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

      // Get Myanmar date for the given date
      final myanmarDate = MyanmarCalendar.fromWestern(
        date.year,
        date.month,
        date.day,
      );

      final myanmarYear = myanmarDate.myanmarYear;
      final myanmarMonth = myanmarDate.myanmarMonth;

      // Get all dates in this Myanmar month
      final myanmarDates = MyanmarCalendar.getMyanmarMonth(
        myanmarYear,
        myanmarMonth,
      );

      debugPrint('📅 Myanmar Month: $myanmarYear/$myanmarMonth');
      debugPrint('📅 Total days in month: ${myanmarDates.length}');

      // Get corresponding Western dates
      final westernDates = MyanmarCalendar.getWesternDatesForMyanmarMonth(
        myanmarYear,
        myanmarMonth,
      );

      // Get first day's weekday to determine grid start
      final firstWesternDate = westernDates.first;
      final firstWeekday =
          firstWesternDate.weekday % 7; // 0=Sunday, 1=Monday, etc.

      debugPrint('📅 First weekday: $firstWeekday');

      // Build calendar grid (42 cells = 6 weeks × 7 days)
      final gridDays = <MyanmarDayData>[];

      // Add previous month days if needed
      if (firstWeekday > 0) {
        final prevMonthDays = _getPreviousMonthDays(
          myanmarYear,
          myanmarMonth,
          firstWeekday,
          languageCode,
        );
        gridDays.addAll(prevMonthDays);
      }

      // Add current month days
      for (var i = 0; i < myanmarDates.length; i++) {
        final mmDate = myanmarDates[i];
        final westernDate = westernDates[i];
        final isToday = _isToday(westernDate);
        final myanmarDateTime = MyanmarDateTime.fromMyanmarDate(mmDate);

        final year = targetLanguage == Language.shan
            ? myanmarDateTime.shanDate.year
            : mmDate.year;

        gridDays.add(
          MyanmarDayData(
            westernYear: westernDate.year,
            westernMonth: westernDate.month,
            westernDay: westernDate.day,
            myanmarYear: year,
            myanmarMonth: mmDate.month,
            myanmarMonthName: mmDate.format(pattern: '&M'),
            moonPhase: mmDate.moonPhase,
            fortnightDay: mmDate.fortnightDay,
            hasHoliday: myanmarDateTime.allHolidays.isNotEmpty,
            isToday: isToday,
            isCurrentMonth: true,
          ),
        );
      }

      // Add next month days to fill the grid to 42 cells
      final remainingCells = 42 - gridDays.length;
      if (remainingCells > 0) {
        final nextMonthDays = _getNextMonthDays(
          myanmarYear,
          myanmarMonth,
          remainingCells,
          languageCode,
        );
        gridDays.addAll(nextMonthDays);
      }

      debugPrint('📅 Total grid cells: ${gridDays.length}');

      // Get month names
      final myanmarMonthName = myanmarDate.formatMyanmar("&M");
      final westernMonthName = DateFormat('MMMM').format(firstWesternDate);

      return MyanmarMonthData(
        myanmarYear: myanmarYear,
        myanmarMonth: myanmarMonth,
        myanmarMonthName: myanmarMonthName,
        westernYear: firstWesternDate.year,
        westernMonth: firstWesternDate.month,
        westernMonthName: westernMonthName,
        days: gridDays,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating Myanmar month data: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get previous month days to fill grid
  static List<MyanmarDayData> _getPreviousMonthDays(
    int currentYear,
    int currentMonth,
    int count,
    String languageCode,
  ) {
    try {
      // Temporarily set language
      final currentLanguage = MyanmarCalendar.currentLanguage;
      final targetLanguage = Language.fromCode(languageCode);

      if (currentLanguage != targetLanguage) {
        MyanmarCalendar.setLanguage(targetLanguage);
      }

      // Calculate previous Myanmar month
      int prevYear = currentYear;
      int prevMonth = currentMonth - 1;

      if (prevMonth < 1) {
        prevYear--;
        prevMonth = 14; // Last month of Myanmar year
      }

      // Get previous month's dates
      final prevMonthDates = MyanmarCalendar.getMyanmarMonth(
        prevYear,
        prevMonth,
      );

      final prevWesternDates = MyanmarCalendar.getWesternDatesForMyanmarMonth(
        prevYear,
        prevMonth,
      );

      // Get last 'count' days from previous month
      final startIndex = prevMonthDates.length - count;
      final days = <MyanmarDayData>[];

      for (var i = startIndex; i < prevMonthDates.length; i++) {
        final mmDate = prevMonthDates[i];
        final westernDate = prevWesternDates[i];
        final myanmarDateTime = MyanmarDateTime.fromMyanmarDate(mmDate);

        final year = targetLanguage == Language.shan
            ? myanmarDateTime.shanDate.year
            : mmDate.year;

        days.add(
          MyanmarDayData(
            westernYear: westernDate.year,
            westernMonth: westernDate.month,
            westernDay: westernDate.day,
            myanmarYear: year,
            myanmarMonth: mmDate.month,
            myanmarMonthName: mmDate.format(pattern: '&M'),
            moonPhase: mmDate.moonPhase,
            fortnightDay: mmDate.fortnightDay,
            hasHoliday: myanmarDateTime.allHolidays.isNotEmpty,
            isToday: false,
            isCurrentMonth: false,
          ),
        );
      }

      return days;
    } catch (e) {
      debugPrint('⚠️ Error getting previous month days: $e');
      return [];
    }
  }

  /// Get next month days to fill grid
  static List<MyanmarDayData> _getNextMonthDays(
    int currentYear,
    int currentMonth,
    int count,
    String languageCode,
  ) {
    try {
      // Temporarily set language
      final currentLanguage = MyanmarCalendar.currentLanguage;
      final targetLanguage = Language.fromCode(languageCode);

      if (currentLanguage != targetLanguage) {
        MyanmarCalendar.setLanguage(targetLanguage);
      }

      // Calculate next Myanmar month
      int nextYear = currentYear;
      int nextMonth = currentMonth + 1;

      if (nextMonth > 14) {
        nextYear++;
        nextMonth = 1;
      }

      // Get next month's dates
      final nextMonthDates = MyanmarCalendar.getMyanmarMonth(
        nextYear,
        nextMonth,
      );

      final nextWesternDates = MyanmarCalendar.getWesternDatesForMyanmarMonth(
        nextYear,
        nextMonth,
      );

      // Get first 'count' days from next month
      final days = <MyanmarDayData>[];

      for (var i = 0; i < count && i < nextMonthDates.length; i++) {
        final mmDate = nextMonthDates[i];
        final westernDate = nextWesternDates[i];
        final myanmarDateTime = MyanmarDateTime.fromMyanmarDate(mmDate);

        final year = targetLanguage == Language.shan
            ? myanmarDateTime.shanDate.year
            : mmDate.year;

        days.add(
          MyanmarDayData(
            westernYear: westernDate.year,
            westernMonth: westernDate.month,
            westernDay: westernDate.day,
            myanmarYear: year,
            myanmarMonth: mmDate.month,
            myanmarMonthName: mmDate.format(pattern: '&M'),
            moonPhase: mmDate.moonPhase,
            fortnightDay: mmDate.fortnightDay,
            hasHoliday: myanmarDateTime.allHolidays.isNotEmpty,
            isToday: false,
            isCurrentMonth: false,
          ),
        );
      }

      return days;
    } catch (e) {
      debugPrint('⚠️ Error getting next month days: $e');
      return [];
    }
  }

  /// Check if date is today
  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Convert month data to JSON
  static String _convertToJson(MyanmarMonthData monthData) {
    final map = {
      'myanmar_year': monthData.myanmarYear,
      'myanmar_month': monthData.myanmarMonth,
      'myanmar_month_name': monthData.myanmarMonthName,
      'western_year': monthData.westernYear,
      'western_month': monthData.westernMonth,
      'western_month_name': monthData.westernMonthName,
      'days': monthData.days
          .map(
            (day) => {
              'western_year': day.westernYear,
              'western_month': day.westernMonth,
              'western_day': day.westernDay,
              'myanmar_year': day.myanmarYear,
              'myanmar_month': day.myanmarMonth,
              'myanmar_month_name': day.myanmarMonthName,
              'moon_phase': day.moonPhase,
              'fortnight_day': day.fortnightDay,
              'has_holiday': day.hasHoliday,
              'is_today': day.isToday,
              'is_current_month': day.isCurrentMonth,
            },
          )
          .toList(),
    };

    return json.encode(map);
  }
}

// ============================================
// DATA CLASSES
// ============================================

class MyanmarMonthData {
  final int myanmarYear;
  final int myanmarMonth;
  final String myanmarMonthName;
  final int westernYear;
  final int westernMonth;
  final String westernMonthName;
  final List<MyanmarDayData> days;

  MyanmarMonthData({
    required this.myanmarYear,
    required this.myanmarMonth,
    required this.myanmarMonthName,
    required this.westernYear,
    required this.westernMonth,
    required this.westernMonthName,
    required this.days,
  });
}

class MyanmarDayData {
  final int westernYear;
  final int westernMonth;
  final int westernDay;
  final int myanmarYear;
  final int myanmarMonth;
  final String myanmarMonthName;
  final int moonPhase;
  final int fortnightDay;
  final bool hasHoliday;
  final bool isToday;
  final bool isCurrentMonth;

  MyanmarDayData({
    required this.westernYear,
    required this.westernMonth,
    required this.westernDay,
    required this.myanmarYear,
    required this.myanmarMonth,
    required this.myanmarMonthName,
    required this.moonPhase,
    required this.fortnightDay,
    required this.hasHoliday,
    required this.isToday,
    required this.isCurrentMonth,
  });
}
