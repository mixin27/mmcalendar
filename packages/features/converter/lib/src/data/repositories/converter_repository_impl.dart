import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import '../../domain/entities/conversion_result.dart';
import '../../domain/entities/date_arithmetic_result.dart';
import '../../domain/entities/date_calculation_result.dart';
import '../../domain/entities/moon_phase_result.dart';
import '../../domain/repositories/converter_repository.dart';

class ConverterRepositoryImpl extends BaseRepository
    implements ConverterRepository {
  @override
  Either<Failure, ConversionResult> convertWesternToMyanmar(DateTime date) {
    try {
      final myanmarDateTime = MyanmarCalendar.fromDateTime(date);
      final completeDate = myanmarDateTime.completeDate;

      final formattedMyanmar = myanmarDateTime.formatMyanmar(
        '&y &M &P &f &Yat',
      );
      final formattedWestern = myanmarDateTime.formatWestern('%dd %M %yyyy');

      return Right(
        ConversionResult(
          completeDate: completeDate,
          formattedMyanmar: formattedMyanmar,
          formattedWestern: formattedWestern,
        ),
      );
    } catch (e) {
      return Left(UnknownFailure('Failed to convert Western to Myanmar: $e'));
    }
  }

  @override
  Either<Failure, ConversionResult> convertMyanmarToWestern(
    int year,
    int month,
    int day,
  ) {
    try {
      final myanmarDateTime = MyanmarCalendar.fromMyanmar(year, month, day);
      final completeDate = myanmarDateTime.completeDate;

      final formattedMyanmar = myanmarDateTime.formatMyanmar('&y &M &P &ff');
      final formattedWestern = myanmarDateTime.formatWestern('%dd %M %yyyy');

      return Right(
        ConversionResult(
          completeDate: completeDate,
          formattedMyanmar: formattedMyanmar,
          formattedWestern: formattedWestern,
        ),
      );
    } on InvalidMyanmarDateException catch (e) {
      final suggestion = e.details?['suggestion'];
      final message = suggestion != null
          ? '${e.message}. Suggestion: $suggestion'
          : e.message;
      return Left(DataFailure(message));
    } on DateConversionException catch (e) {
      return Left(DataFailure(e.message));
    } on MyanmarCalendarException catch (e) {
      return Left(DataFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to convert Myanmar to Western: $e'));
    }
  }

  @override
  Either<Failure, DateCalculationResult> calculateDateDifference(
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      final start = MyanmarCalendar.fromDateTime(startDate);
      final end = MyanmarCalendar.fromDateTime(endDate);

      // Calculate total days difference
      final totalDays = MyanmarCalendar.daysBetween(start, end);

      // Calculate years, months, days breakdown
      final years = (totalDays / 365).floor();
      final remainingDaysAfterYears = totalDays - (years * 365);
      final months = (remainingDaysAfterYears / 30).floor();
      final days = remainingDaysAfterYears - (months * 30);
      final weeks = (totalDays / 7).floor();

      // Format the difference string
      final formattedDifference = _formatDateDifference(
        years: years,
        months: months,
        days: days,
        totalDays: totalDays.abs(),
      );

      return Right(
        DateCalculationResult(
          totalDays: totalDays,
          years: years,
          months: months,
          days: days,
          weeks: weeks,
          formattedDifference: formattedDifference,
        ),
      );
    } on MyanmarCalendarException catch (e) {
      return Left(DataFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to calculate date difference: $e'));
    }
  }

  @override
  Either<Failure, DateArithmeticResult> performDateArithmetic(
    DateTime startDate,
    String operation,
    int value,
    String unit,
  ) {
    try {
      if (value < 0) {
        return Left(UnknownFailure('Value must be positive'));
      }

      final myanmarDateTime = MyanmarCalendar.fromDateTime(startDate);
      late MyanmarDateTime resultDateTime;

      // Apply operation
      final actualValue = operation == 'subtract' ? -value : value;

      switch (unit.toLowerCase()) {
        case 'days':
          resultDateTime = myanmarDateTime.addDays(actualValue);
          break;
        case 'weeks':
          resultDateTime = myanmarDateTime.addDays(actualValue * 7);
          break;
        case 'months':
          resultDateTime = MyanmarCalendar.addMonths(
            myanmarDateTime,
            actualValue,
          );
          break;
        case 'years':
          resultDateTime = MyanmarCalendar.addMonths(
            myanmarDateTime,
            actualValue * 12,
          );
          break;
        default:
          return Left(UnknownFailure('Invalid unit: $unit'));
      }

      return Right(
        DateArithmeticResult(
          resultDate: resultDateTime.completeDate,
          operation: operation,
          value: value,
          unit: unit,
        ),
      );
    } on MyanmarCalendarException catch (e) {
      return Left(DataFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to perform date arithmetic: $e'));
    }
  }

  @override
  Either<Failure, MoonPhaseResult> findNextMoonPhase(
    DateTime startDate,
    int moonPhase,
  ) {
    try {
      if (moonPhase < 0 || moonPhase > 3) {
        return Left(
          UnknownFailure('Invalid moon phase: $moonPhase (must be 0-3)'),
        );
      }

      final myanmarDateTime = MyanmarCalendar.fromDateTime(startDate);
      final nextMoonPhaseDate = MyanmarCalendar.findNextMoonPhase(
        myanmarDateTime,
        moonPhase,
      );

      // Calculate days from start
      final daysFromStart = MyanmarCalendar.daysBetween(
        myanmarDateTime,
        nextMoonPhaseDate,
      );

      // Get moon phase name
      final moonPhaseName = _getMoonPhaseName(moonPhase);

      return Right(
        MoonPhaseResult(
          dateFound: nextMoonPhaseDate.completeDate,
          moonPhase: moonPhase,
          moonPhaseName: moonPhaseName,
          daysFromStart: daysFromStart,
        ),
      );
    } on MyanmarCalendarException catch (e) {
      return Left(DataFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to find next moon phase: $e'));
    }
  }

  // Helper methods
  String _formatDateDifference({
    required int years,
    required int months,
    required int days,
    required int totalDays,
  }) {
    if (totalDays == 0) {
      return 'Same date';
    }

    final parts = <String>[];

    if (years > 0) {
      parts.add('$years ${years == 1 ? "year" : "years"}');
    }
    if (months > 0) {
      parts.add('$months ${months == 1 ? "month" : "months"}');
    }
    if (days > 0) {
      parts.add('$days ${days == 1 ? "day" : "days"}');
    }

    if (parts.isEmpty) {
      return '$totalDays ${totalDays == 1 ? "day" : "days"}';
    }

    return parts.join(', ');
  }

  String _getMoonPhaseName(int moonPhase) {
    switch (moonPhase) {
      case 0:
        return 'Waxing';
      case 1:
        return 'Full Moon';
      case 2:
        return 'Waning';
      case 3:
        return 'New Moon';
      default:
        return 'Unknown';
    }
  }
}
