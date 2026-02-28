import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart' hide CacheException;

import '../../domain/entities/calendar_month.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_local_datasource.dart';
import '../models/calendar_month_model.dart';

/// Implementation of CalendarRepository
class CalendarRepositoryImpl extends BaseRepository
    implements CalendarRepository {
  final CalendarLocalDataSource localDataSource;
  final Map<int, CalendarMonth> _monthCache = <int, CalendarMonth>{};

  CalendarRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, CalendarMonth>> getCalendarMonth(
    DateTime month,
  ) async {
    try {
      // Ensure month is first day
      final firstDayOfMonth = DateTime(month.year, month.month, 1);
      final cacheKey = _monthKey(firstDayOfMonth);

      final cachedMonth = _monthCache[cacheKey];
      if (cachedMonth != null) {
        return Right(cachedMonth);
      }

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

      final entity = calendarMonth.toEntity();
      _monthCache[cacheKey] = entity;
      return Right(entity);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } on InvalidConfigurationException catch (e) {
      return Left(CacheFailure(e.message));
    } on MyanmarCalendarException catch (e) {
      return Left(CacheFailure(e.message));
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
    } on MyanmarCalendarException catch (e) {
      return Left(CacheFailure(e.message));
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
    } on MyanmarCalendarException catch (e) {
      return Left(CacheFailure(e.message));
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
      _monthCache.clear();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } on InvalidConfigurationException catch (e) {
      return Left(CacheFailure(e.message));
    } on MyanmarCalendarException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  int _monthKey(DateTime month) => month.year * 100 + month.month;

  @override
  Future<Either<Failure, bool>> isAstrologyExpanded() async {
    try {
      final isExpanded = await localDataSource.isAstrologyExpanded();
      return Right(isExpanded);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message, e.code));
    } on MyanmarCalendarException catch (e) {
      return Left(CacheFailure(e.message));
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
    } on MyanmarCalendarException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
