import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import '../../domain/entities/calendar_month.dart';

/// Data model for CalendarMonth entity
class CalendarMonthModel extends CalendarMonth {
  const CalendarMonthModel({
    required super.month,
    required super.dates,
    required super.gridDates,
  });

  factory CalendarMonthModel.fromDates({
    required DateTime month,
    required List<CompleteDate> dates,
    required List<CompleteDate> gridDates,
  }) {
    return CalendarMonthModel(month: month, dates: dates, gridDates: gridDates);
  }

  CalendarMonth toEntity() {
    return CalendarMonth(month: month, dates: dates, gridDates: gridDates);
  }
}
