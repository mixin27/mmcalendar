import 'package:equatable/equatable.dart';

class DateCalculationResult extends Equatable {
  final int totalDays;
  final int years;
  final int months;
  final int days;
  final int weeks;
  final String formattedDifference;

  const DateCalculationResult({
    required this.totalDays,
    required this.years,
    required this.months,
    required this.days,
    required this.weeks,
    required this.formattedDifference,
  });

  @override
  List<Object?> get props => [
    totalDays,
    years,
    months,
    days,
    weeks,
    formattedDifference,
  ];
}
