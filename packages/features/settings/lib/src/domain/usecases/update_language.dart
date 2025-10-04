import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

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
