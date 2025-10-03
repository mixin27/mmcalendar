import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/day_data.dart';
import '../repositories/views_repository.dart';

class GetDayView {
  final ViewsRepository repository;

  GetDayView(this.repository);

  Future<Either<Failure, DayData>> call(DateTime date) async {
    return await repository.getDayData(date);
  }
}
