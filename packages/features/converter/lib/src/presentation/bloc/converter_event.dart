import 'package:equatable/equatable.dart';

sealed class ConverterEvent extends Equatable {
  const ConverterEvent();

  @override
  List<Object?> get props => [];
}

// Date Conversion Events
final class ConvertWesternToMyanmarEvent extends ConverterEvent {
  final DateTime date;

  const ConvertWesternToMyanmarEvent(this.date);

  @override
  List<Object?> get props => [date];
}

final class ConvertMyanmarToWesternEvent extends ConverterEvent {
  final int year;
  final int month;
  final int day;

  const ConvertMyanmarToWesternEvent(this.year, this.month, this.day);

  @override
  List<Object?> get props => [year, month, day];
}

// Date Calculation Events
final class CalculateDateDifferenceEvent extends ConverterEvent {
  final DateTime startDate;
  final DateTime endDate;

  const CalculateDateDifferenceEvent(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

// Date Arithmetic Events
final class PerformDateArithmeticEvent extends ConverterEvent {
  final DateTime startDate;
  final String operation; // 'add' or 'subtract'
  final int value;
  final String unit; // 'days', 'weeks', 'months', 'years'

  const PerformDateArithmeticEvent({
    required this.startDate,
    required this.operation,
    required this.value,
    required this.unit,
  });

  @override
  List<Object?> get props => [startDate, operation, value, unit];
}

// Moon Phase Events
final class FindNextMoonPhaseEvent extends ConverterEvent {
  final DateTime startDate;
  final int moonPhase; // 0=waxing, 1=full, 2=waning, 3=new

  const FindNextMoonPhaseEvent(this.startDate, this.moonPhase);

  @override
  List<Object?> get props => [startDate, moonPhase];
}

// Reset Events
final class ResetConverterEvent extends ConverterEvent {}

final class ResetCalculatorEvent extends ConverterEvent {}

final class ResetArithmeticEvent extends ConverterEvent {}

final class ResetMoonPhaseEvent extends ConverterEvent {}
