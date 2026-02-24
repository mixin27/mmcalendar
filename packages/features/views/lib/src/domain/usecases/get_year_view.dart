import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';

import '../entities/year_data.dart';
import '../repositories/views_repository.dart';

class GetYearView {
  final ViewsRepository repository;

  GetYearView(this.repository);

  Future<Either<Failure, YearData>> call(int year) async {
    return await repository.getYearData(year);
  }
}
