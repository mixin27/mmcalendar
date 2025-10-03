import 'package:equatable/equatable.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

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
