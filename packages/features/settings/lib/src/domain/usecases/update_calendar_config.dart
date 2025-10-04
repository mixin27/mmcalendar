import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

import '../repositories/settings_repository.dart';

class UpdateCalendarConfig {
  final SettingsRepository repository;

  UpdateCalendarConfig(this.repository);

  Future<Either<Failure, void>> call(CalendarConfig config) async {
    return await repository.updateCalendarConfig(config);
  }
}
