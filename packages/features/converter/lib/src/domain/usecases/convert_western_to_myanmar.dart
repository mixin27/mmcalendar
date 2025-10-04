import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/conversion_result.dart';
import '../repositories/converter_repository.dart';

class ConvertWesternToMyanmar {
  final ConverterRepository repository;

  ConvertWesternToMyanmar(this.repository);

  Either<Failure, ConversionResult> call(DateTime date) {
    return repository.convertWesternToMyanmar(date);
  }
}
