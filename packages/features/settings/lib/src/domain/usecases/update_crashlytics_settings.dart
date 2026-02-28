import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';

import '../repositories/settings_repository.dart';

class UpdateCrashlyticsSettings {
  final SettingsRepository repository;

  UpdateCrashlyticsSettings(this.repository);

  Future<Either<Failure, void>> call({bool enable = true}) async {
    return await repository.updateCrashlyticsConsent(enable);
  }
}
