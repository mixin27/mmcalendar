import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import 'week_data.dart';

class DayData extends Equatable {
  final DateTime date;
  final CompleteDate completeDate;
  final WeekData week;

  const DayData({
    required this.date,
    required this.completeDate,
    required this.week,
  });

  @override
  List<Object?> get props => [date, completeDate, week];
}
