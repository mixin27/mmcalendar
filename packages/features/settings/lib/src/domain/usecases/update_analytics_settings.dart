import 'package:core/core.dart';
import 'package:dartz/dartz.dart';

import '../repositories/settings_repository.dart';

class UpdateAnalyticsSettings {
  final SettingsRepository repository;

  UpdateAnalyticsSettings(this.repository);

  Future<Either<Failure, void>> call({bool enable = true}) async {
    return await repository.updateAnalyticsConsent(enable);
  }
}
