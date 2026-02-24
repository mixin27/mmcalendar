import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/conversion_result.dart';
import '../entities/date_arithmetic_result.dart';
import '../entities/date_calculation_result.dart';
import '../entities/moon_phase_result.dart';

abstract class ConverterRepository {
  /// Convert Western date to Myanmar date
  Either<Failure, ConversionResult> convertWesternToMyanmar(DateTime date);

  /// Convert Myanmar date to Western date
  Either<Failure, ConversionResult> convertMyanmarToWestern(
    int year,
    int month,
    int day,
  );

  /// Calculate difference between two dates
  Either<Failure, DateCalculationResult> calculateDateDifference(
    DateTime startDate,
    DateTime endDate,
  );

  /// Add or subtract time from a date
  Either<Failure, DateArithmeticResult> performDateArithmetic(
    DateTime startDate,
    String operation, // 'add' or 'subtract'
    int value,
    String unit, // 'days', 'weeks', 'months', 'years'
  );

  /// Find next occurrence of a moon phase
  Either<Failure, MoonPhaseResult> findNextMoonPhase(
    DateTime startDate,
    int moonPhase, // 0=waxing, 1=full, 2=waning, 3=new
  );
}
