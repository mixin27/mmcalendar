import 'package:equatable/equatable.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

class YearData extends Equatable {
  final int year;
  final List<MonthSummary> months;

  const YearData({required this.year, required this.months});

  @override
  List<Object?> get props => [year, months];
}

class MonthSummary extends Equatable {
  final int monthNumber;
  final String monthName;
  final DateTime firstDay;
  final DateTime lastDay;
  final List<CompleteDate> dates;

  const MonthSummary({
    required this.monthNumber,
    required this.monthName,
    required this.firstDay,
    required this.lastDay,
    required this.dates,
  });

  @override
  List<Object?> get props => [monthNumber, monthName, firstDay, lastDay, dates];
}
