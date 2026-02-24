import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';
import '../entities/date_selection.dart';
import '../repositories/calendar_repository.dart';

/// Use case to select a date
class SelectDate {
  final CalendarRepository repository;

  SelectDate(this.repository);

  Future<Either<Failure, DateSelection>> call(DateTime date) async {
    final result = await repository.getDateDetails(date);

    return result.fold((failure) => Left(failure), (completeDate) {
      final now = DateTime.now();
      final isToday =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      return Right(
        DateSelection(date: date, completeDate: completeDate, isToday: isToday),
      );
    });
  }
}
