import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import '../repositories/settings_repository.dart';

class UpdateCalendarConfig {
  final SettingsRepository repository;

  UpdateCalendarConfig(this.repository);

  Future<Either<Failure, void>> call(CalendarConfig config) async {
    return await repository.updateCalendarConfig(config);
  }
}
