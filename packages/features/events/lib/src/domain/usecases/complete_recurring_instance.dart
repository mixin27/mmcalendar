import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';

import '../repositories/events_repository.dart';

class CompleteRecurringInstance
    implements UseCase<void, CompleteRecurringInstanceParams> {
  final EventsRepository repository;

  CompleteRecurringInstance(this.repository);

  @override
  Future<Either<Failure, void>> call(
    CompleteRecurringInstanceParams params,
  ) async {
    return await repository.completeRecurringInstance(
      params.masterEventId,
      params.occurrenceDate,
    );
  }
}

class CompleteRecurringInstanceParams {
  final int masterEventId;
  final DateTime occurrenceDate;

  CompleteRecurringInstanceParams({
    required this.masterEventId,
    required this.occurrenceDate,
  });
}
