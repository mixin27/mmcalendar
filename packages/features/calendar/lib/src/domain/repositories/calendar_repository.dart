import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import '../entities/calendar_month.dart';

/// Repository interface for calendar operations
abstract class CalendarRepository {
  /// Get calendar month data
  Future<Either<Failure, CalendarMonth>> getCalendarMonth(DateTime month);

  /// Get complete date information
  Future<Either<Failure, CompleteDate>> getDateDetails(DateTime date);

  /// Get calendar configuration
  Future<Either<Failure, CalendarConfig>> getCalendarConfig();

  /// Update calendar configuration
  Future<Either<Failure, void>> updateCalendarConfig(CalendarConfig config);

  /// Check if astrology card is expanded
  Future<Either<Failure, bool>> isAstrologyExpanded();

  /// Toggle astrology card expansion
  Future<Either<Failure, void>> toggleAstrologyExpansion(bool isExpanded);
}
