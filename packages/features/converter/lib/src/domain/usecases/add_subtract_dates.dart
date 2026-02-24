import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/date_arithmetic_result.dart';
import '../repositories/converter_repository.dart';

class AddSubtractDates {
  final ConverterRepository repository;

  AddSubtractDates(this.repository);

  Either<Failure, DateArithmeticResult> call(
    DateTime startDate,
    String operation,
    int value,
    String unit,
  ) {
    return repository.performDateArithmetic(startDate, operation, value, unit);
  }
}
