import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/day_data.dart';
import '../entities/week_data.dart';
import '../entities/year_data.dart';

abstract class ViewsRepository {
  Future<Either<Failure, YearData>> getYearData(int year);
  Future<Either<Failure, WeekData>> getWeekData(DateTime date);
  Future<Either<Failure, DayData>> getDayData(DateTime date);
}
