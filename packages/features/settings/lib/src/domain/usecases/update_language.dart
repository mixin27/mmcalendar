import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

import '../repositories/settings_repository.dart';

class UpdateLanguage {
  final SettingsRepository repository;

  UpdateLanguage(this.repository);

  Future<Either<Failure, void>> updateAppLanguage(String languageCode) async {
    return await repository.updateAppLanguage(languageCode);
  }

  Future<Either<Failure, void>> updateCalendarLanguage(
    Language language,
  ) async {
    return await repository.updateCalendarLanguage(language);
  }
}
