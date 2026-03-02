import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

class WeekData extends Equatable {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int weekNumber;
  final List<CompleteDate> days;

  const WeekData({
    required this.weekStart,
    required this.weekEnd,
    required this.weekNumber,
    required this.days,
  });

  @override
  List<Object?> get props => [weekStart, weekEnd, weekNumber, days];
}
