import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// Represents a calendar month with all its dates
class CalendarMonth extends Equatable {
  final DateTime month;
  final List<CompleteDate> dates;
  final List<CompleteDate> gridDates; // Includes previous/next month dates

  const CalendarMonth({
    required this.month,
    required this.dates,
    required this.gridDates,
  });

  int get year => month.year;
  int get monthNumber => month.month;

  @override
  List<Object?> get props => [month, dates, gridDates];
}
