import 'package:equatable/equatable.dart';

import '../../domain/entities/conversion_result.dart';
import '../../domain/entities/date_arithmetic_result.dart';
import '../../domain/entities/date_calculation_result.dart';
import '../../domain/entities/moon_phase_result.dart';

sealed class ConverterState extends Equatable {
  const ConverterState();

  @override
  List<Object?> get props => [];
}

final class ConverterInitial extends ConverterState {}

// Date Conversion States
final class ConversionLoading extends ConverterState {}

final class ConversionSuccess extends ConverterState {
  final ConversionResult result;

  const ConversionSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

final class ConversionError extends ConverterState {
  final String message;

  const ConversionError(this.message);

  @override
  List<Object?> get props => [message];
}

// Date Calculation States
final class CalculationLoading extends ConverterState {}

final class CalculationSuccess extends ConverterState {
  final DateCalculationResult result;

  const CalculationSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

final class CalculationError extends ConverterState {
  final String message;

  const CalculationError(this.message);

  @override
  List<Object?> get props => [message];
}

// Date Arithmetic States
final class ArithmeticLoading extends ConverterState {}

final class ArithmeticSuccess extends ConverterState {
  final DateArithmeticResult result;

  const ArithmeticSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

final class ArithmeticError extends ConverterState {
  final String message;

  const ArithmeticError(this.message);

  @override
  List<Object?> get props => [message];
}

// Moon Phase States
final class MoonPhaseLoading extends ConverterState {}

final class MoonPhaseSuccess extends ConverterState {
  final MoonPhaseResult result;

  const MoonPhaseSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

final class MoonPhaseError extends ConverterState {
  final String message;

  const MoonPhaseError(this.message);

  @override
  List<Object?> get props => [message];
}
