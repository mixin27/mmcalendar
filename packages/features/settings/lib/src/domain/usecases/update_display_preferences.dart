import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';

import '../repositories/settings_repository.dart';

class UpdateDisplayPreferences {
  final SettingsRepository repository;

  UpdateDisplayPreferences(this.repository);

  Future<Either<Failure, void>> call(String key, bool value) async {
    return await repository.updateDisplayPreference(key, value);
  }

  Future<Either<Failure, void>> gridStyle(CalendarGridStyle style) =>
      repository.updateCalendarGridStyle(style);

  Future<Either<Failure, void>> gridTheme(CalendarGridTheme theme) =>
      repository.updateCalendarGridTheme(theme);
}
