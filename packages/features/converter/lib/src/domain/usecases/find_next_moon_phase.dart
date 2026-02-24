import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/moon_phase_result.dart';
import '../repositories/converter_repository.dart';

class FindNextMoonPhase {
  final ConverterRepository repository;

  FindNextMoonPhase(this.repository);

  Either<Failure, MoonPhaseResult> call(DateTime startDate, int moonPhase) {
    return repository.findNextMoonPhase(startDate, moonPhase);
  }
}
