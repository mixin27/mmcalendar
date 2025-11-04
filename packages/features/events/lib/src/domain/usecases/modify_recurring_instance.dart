import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../repositories/events_repository.dart';

class ModifyRecurringInstance
    implements UseCase<void, ModifyRecurringInstanceParams> {
  final EventsRepository repository;

  ModifyRecurringInstance(this.repository);

  @override
  Future<Either<Failure, void>> call(
    ModifyRecurringInstanceParams params,
  ) async {
    return await repository.modifyRecurringInstance(
      masterEventId: params.masterEventId,
      occurrenceDate: params.occurrenceDate,
      modifiedTitle: params.modifiedTitle,
      modifiedDescription: params.modifiedDescription,
      modifiedDate: params.modifiedDate,
      modifiedTime: params.modifiedTime,
      modifiedLocation: params.modifiedLocation,
    );
  }
}

class ModifyRecurringInstanceParams {
  final int masterEventId;
  final DateTime occurrenceDate;
  final String? modifiedTitle;
  final String? modifiedDescription;
  final DateTime? modifiedDate;
  final DateTime? modifiedTime;
  final String? modifiedLocation;

  ModifyRecurringInstanceParams({
    required this.masterEventId,
    required this.occurrenceDate,
    this.modifiedTitle,
    this.modifiedDescription,
    this.modifiedDate,
    this.modifiedTime,
    this.modifiedLocation,
  });
}
