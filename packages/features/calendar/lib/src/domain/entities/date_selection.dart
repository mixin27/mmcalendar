import 'package:equatable/equatable.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// Represents a selected date with its complete information
class DateSelection extends Equatable {
  final DateTime date;
  final CompleteDate completeDate;
  final bool isToday;

  const DateSelection({
    required this.date,
    required this.completeDate,
    required this.isToday,
  });

  @override
  List<Object?> get props => [date, completeDate, isToday];
}
