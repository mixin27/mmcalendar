import 'package:dartz/dartz.dart';
import 'package:core/core.dart';

import '../entities/calendar_month.dart';
import '../repositories/calendar_repository.dart';

/// Use case to get calendar month data
class GetCalendarMonth {
  final CalendarRepository repository;

  GetCalendarMonth(this.repository);

  Future<Either<Failure, CalendarMonth>> call(DateTime month) async {
    return await repository.getCalendarMonth(month);
  }
}
