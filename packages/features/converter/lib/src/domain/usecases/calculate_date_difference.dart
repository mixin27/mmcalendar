import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/date_calculation_result.dart';
import '../repositories/converter_repository.dart';

class CalculateDateDifference {
  final ConverterRepository repository;

  CalculateDateDifference(this.repository);

  Either<Failure, DateCalculationResult> call(
    DateTime startDate,
    DateTime endDate,
  ) {
    return repository.calculateDateDifference(startDate, endDate);
  }
}
