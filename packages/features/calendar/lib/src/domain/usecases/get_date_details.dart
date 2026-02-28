import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import '../repositories/calendar_repository.dart';

/// Use case to get complete date details
class GetDateDetails {
  final CalendarRepository repository;

  GetDateDetails(this.repository);

  Future<Either<Failure, CompleteDate>> call(DateTime date) async {
    return await repository.getDateDetails(date);
  }
}
