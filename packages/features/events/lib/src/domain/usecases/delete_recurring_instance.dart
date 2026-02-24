import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';

import '../repositories/events_repository.dart';

class DeleteRecurringInstance
    implements UseCase<void, DeleteRecurringInstanceParams> {
  final EventsRepository repository;

  DeleteRecurringInstance(this.repository);

  @override
  Future<Either<Failure, void>> call(
    DeleteRecurringInstanceParams params,
  ) async {
    return await repository.deleteRecurringInstance(
      params.masterEventId,
      params.occurrenceDate,
    );
  }
}

class DeleteRecurringInstanceParams {
  final int masterEventId;
  final DateTime occurrenceDate;

  DeleteRecurringInstanceParams({
    required this.masterEventId,
    required this.occurrenceDate,
  });
}
