import 'package:equatable/equatable.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

class DateArithmeticResult extends Equatable {
  final CompleteDate resultDate;
  final String operation;
  final int value;
  final String unit; // days, weeks, months, years

  const DateArithmeticResult({
    required this.resultDate,
    required this.operation,
    required this.value,
    required this.unit,
  });

  @override
  List<Object?> get props => [resultDate, operation, value, unit];
}
