import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:integrations_database/integrations_database.dart';

import '../../domain/entities/day_data.dart';
import '../../domain/entities/week_data.dart';
import '../../domain/entities/year_data.dart';
import '../../domain/repositories/views_repository.dart';
import '../datasources/views_local_datasource.dart';

class ViewsRepositoryImpl extends BaseRepository implements ViewsRepository {
  final ViewsLocalDataSource localDataSource;

  ViewsRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, YearData>> getYearData(int year) async {
    try {
      final dates = await localDataSource.getYearDates(year);

      // Group dates by month
      final monthsData = <MonthSummary>[];
      for (int month = 1; month <= 12; month++) {
        final monthDates = dates
            .where((d) => d.western.toDateTime().month == month)
            .toList();

        if (monthDates.isNotEmpty) {
          final firstDay = DateTime(year, month, 1);
          final lastDay = DateTime(year, month + 1, 0);

          monthsData.add(
            MonthSummary(
              monthNumber: month,
              monthName: firstDay.format('MMMM'),
              firstDay: firstDay,
              lastDay: lastDay,
              dates: monthDates,
            ),
          );
        }
      }

      return Right(YearData(year: year, months: monthsData));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeekData>> getWeekData(DateTime date) async {
    try {
      final weekDates = await localDataSource.getWeekDates(date);

      final weekStart = weekDates.first.western.toDateTime();
      final weekEnd = weekDates.last.western.toDateTime();
      final weekNumber = AppDateUtils.getWeekNumber(date);

      return Right(
        WeekData(
          weekStart: weekStart,
          weekEnd: weekEnd,
          weekNumber: weekNumber,
          days: weekDates,
        ),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DayData>> getDayData(DateTime date) async {
    try {
      final completeDate = await localDataSource.getDayDetails(date);
      final weekData = await getWeekData(date);

      return weekData.fold(
        (failure) => Left(failure),
        (week) =>
            Right(DayData(date: date, completeDate: completeDate, week: week)),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
