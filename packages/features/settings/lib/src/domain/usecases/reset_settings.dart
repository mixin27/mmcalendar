import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';

import '../repositories/settings_repository.dart';

class ResetSettings {
  final SettingsRepository repository;

  ResetSettings(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.resetSettings();
  }
}
