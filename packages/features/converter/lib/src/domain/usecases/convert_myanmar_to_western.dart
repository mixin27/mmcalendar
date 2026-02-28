import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/conversion_result.dart';
import '../repositories/converter_repository.dart';

class ConvertMyanmarToWestern {
  final ConverterRepository repository;

  ConvertMyanmarToWestern(this.repository);

  Either<Failure, ConversionResult> call(int year, int month, int day) {
    return repository.convertMyanmarToWestern(year, month, day);
  }
}
