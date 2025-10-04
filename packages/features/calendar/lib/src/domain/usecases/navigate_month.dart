import 'package:dartz/dartz.dart';
import 'package:core/core.dart';

import '../entities/calendar_month.dart';
import '../repositories/calendar_repository.dart';

/// Use case to navigate to next or previous month
class NavigateMonth {
  final CalendarRepository repository;

  NavigateMonth(this.repository);

  /// Navigate to next month
  Future<Either<Failure, CalendarMonth>> next(DateTime currentMonth) async {
    final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    return await repository.getCalendarMonth(nextMonth);
  }

  /// Navigate to previous month
  Future<Either<Failure, CalendarMonth>> previous(DateTime currentMonth) async {
    final previousMonth = DateTime(
      currentMonth.year,
      currentMonth.month - 1,
      1,
    );
    return await repository.getCalendarMonth(previousMonth);
  }

  /// Navigate to specific month
  Future<Either<Failure, CalendarMonth>> goToMonth(DateTime month) async {
    return await repository.getCalendarMonth(month);
  }

  /// Navigate to today
  Future<Either<Failure, CalendarMonth>> today() async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    return await repository.getCalendarMonth(thisMonth);
  }
}
