import 'package:core/core.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

abstract class ViewsLocalDataSource {
  Future<List<CompleteDate>> getYearDates(int year);
  Future<List<CompleteDate>> getWeekDates(DateTime date);
  Future<CompleteDate> getDayDetails(DateTime date);
}

class ViewsLocalDataSourceImpl implements ViewsLocalDataSource {
  @override
  Future<List<CompleteDate>> getYearDates(int year) async {
    try {
      final dates = <CompleteDate>[];

      for (int month = 1; month <= 12; month++) {
        final firstDay = DateTime(year, month, 1);
        final lastDay = DateTime(year, month + 1, 0);

        for (int day = firstDay.day; day <= lastDay.day; day++) {
          final date = DateTime(year, month, day);
          final completeDate = MyanmarCalendar.getCompleteDate(date);
          dates.add(completeDate);
        }
      }

      return dates;
    } catch (e) {
      throw CacheException('Failed to get year dates: ${e.toString()}');
    }
  }

  @override
  Future<List<CompleteDate>> getWeekDates(DateTime date) async {
    try {
      final weekDates = AppDateUtils.getWeekDates(date, firstDayOfWeek: 1);

      final completeDates = <CompleteDate>[];
      for (final weekDate in weekDates) {
        final completeDate = MyanmarCalendar.getCompleteDate(weekDate);
        completeDates.add(completeDate);
      }

      return completeDates;
    } catch (e) {
      throw CacheException('Failed to get week dates: ${e.toString()}');
    }
  }

  @override
  Future<CompleteDate> getDayDetails(DateTime date) async {
    try {
      return MyanmarCalendar.getCompleteDate(date);
    } catch (e) {
      throw CacheException('Failed to get day details: ${e.toString()}');
    }
  }
}
