import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import '../../domain/entities/calendar_month.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_local_datasource.dart';
import '../models/calendar_month_model.dart';

/// Implementation of CalendarRepository
class CalendarRepositoryImpl extends BaseRepository
    implements CalendarRepository {
  final CalendarLocalDataSource localDataSource;

  CalendarRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, CalendarMonth>> getCalendarMonth(
    DateTime month,
  ) async {
    try {
      // Ensure month is first day
      final firstDayOfMonth = DateTime(month.year, month.month, 1);

      // Get dates for the month
      final dates = await localDataSource.getMonthDates(firstDayOfMonth);

      // Get calendar grid dates (including prev/next month)
      final gridDates = await localDataSource.getCalendarGridDates(
        firstDayOfMonth,
      );

      final calendarMonth = CalendarMonthModel.fromDates(
        month: firstDayOfMonth,
        dates: dates,
        gridDates: gridDates,
      );

      return Right(calendarMonth.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CompleteDate>> getDateDetails(DateTime date) async {
    try {
      final completeDate = await localDataSource.getDateDetails(date);
      return Right(completeDate);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CalendarConfig>> getCalendarConfig() async {
    try {
      final config = await localDataSource.getCalendarConfig();
      return Right(config);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCalendarConfig(
    CalendarConfig config,
  ) async {
    try {
      await localDataSource.updateCalendarConfig(config);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAstrologyExpanded() async {
    try {
      final isExpanded = await localDataSource.isAstrologyExpanded();
      return Right(isExpanded);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleAstrologyExpansion(
    bool isExpanded,
  ) async {
    try {
      await localDataSource.setAstrologyExpanded(isExpanded);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
