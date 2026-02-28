import 'package:equatable/equatable.dart';

class CalendarDayCellModel extends Equatable {
  const CalendarDayCellModel({
    required this.westernDate,
    required this.westernDayLabel,
    required this.myanmarDayLabel,
    required this.isCurrentMonth,
    required this.isToday,
    required this.hasHoliday,
    required this.hasAstrology,
  });

  final DateTime westernDate;
  final String westernDayLabel;
  final String myanmarDayLabel;
  final bool isCurrentMonth;
  final bool isToday;
  final bool hasHoliday;
  final bool hasAstrology;

  @override
  List<Object?> get props => [
    westernDate,
    westernDayLabel,
    myanmarDayLabel,
    isCurrentMonth,
    isToday,
    hasHoliday,
    hasAstrology,
  ];
}

class CalendarPageModel extends Equatable {
  const CalendarPageModel({
    required this.year,
    required this.month,
    required this.title,
    required this.weekdayLabels,
    required this.dayCells,
  });

  final int year;
  final int month;
  final String title;
  final List<String> weekdayLabels;
  final List<CalendarDayCellModel> dayCells;

  @override
  List<Object?> get props => [year, month, title, weekdayLabels, dayCells];
}
