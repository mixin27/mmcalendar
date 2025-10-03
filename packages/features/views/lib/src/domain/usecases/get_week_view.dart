import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../entities/week_data.dart';
import '../repositories/views_repository.dart';

class GetWeekView {
  final ViewsRepository repository;

  GetWeekView(this.repository);

  Future<Either<Failure, WeekData>> call(DateTime date) async {
    return await repository.getWeekData(date);
  }
}
