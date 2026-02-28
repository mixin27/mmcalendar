import 'package:equatable/equatable.dart';

class CalendarDayCellModel extends Equatable {
  const CalendarDayCellModel({
    required this.westernDate,
    required this.westernDayLabel,
    required this.myanmarDayLabel,
    required this.isCurrentMonth,
    required this.isPlaceholder,
    required this.isToday,
    required this.isFullMoon,
    required this.isNewMoon,
    required this.moonPhase,
    required this.hasHoliday,
    required this.hasPublicHoliday,
    required this.hasAstrology,
    this.sabbathLabel,
    this.sabbathEveLabel,
    this.yatyazaLabel,
    this.pyathadaLabel,
    this.afternoonPyathadaLabel,
    this.otherAstrologyLabel,
  });

  final DateTime westernDate;
  final String westernDayLabel;
  final String myanmarDayLabel;
  final bool isCurrentMonth;
  final bool isPlaceholder;
  final bool isToday;
  final bool isFullMoon;
  final bool isNewMoon;
  final int moonPhase;
  final bool hasHoliday;
  final bool hasPublicHoliday;
  final bool hasAstrology;
  final String? sabbathLabel;
  final String? sabbathEveLabel;
  final String? yatyazaLabel;
  final String? pyathadaLabel;
  final String? afternoonPyathadaLabel;
  final String? otherAstrologyLabel;

  @override
  List<Object?> get props => [
    westernDate,
    westernDayLabel,
    myanmarDayLabel,
    isCurrentMonth,
    isPlaceholder,
    isToday,
    isFullMoon,
    isNewMoon,
    moonPhase,
    hasHoliday,
    hasPublicHoliday,
    hasAstrology,
    sabbathLabel,
    sabbathEveLabel,
    yatyazaLabel,
    pyathadaLabel,
    afternoonPyathadaLabel,
    otherAstrologyLabel,
  ];
}

class CalendarPageModel extends Equatable {
  const CalendarPageModel({
    required this.year,
    required this.month,
    required this.westernTitle,
    required this.myanmarTitle,
    required this.weekdayLabels,
    required this.dayCells,
  });

  final int year;
  final int month;
  final String westernTitle;
  final String myanmarTitle;
  final List<String> weekdayLabels;
  final List<CalendarDayCellModel> dayCells;

  @override
  List<Object?> get props => [
    year,
    month,
    westernTitle,
    myanmarTitle,
    weekdayLabels,
    dayCells,
  ];
}
