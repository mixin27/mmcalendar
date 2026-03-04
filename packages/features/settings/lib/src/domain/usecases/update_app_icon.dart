import 'package:dartz/dartz.dart';
import 'package:shared_core/shared_core.dart';

import '../repositories/settings_repository.dart';

class UpdateAppIcon {
  final SettingsRepository repository;

  UpdateAppIcon(this.repository);

  Future<Either<Failure, void>> call(String appIconId) async {
    return repository.updateAppIcon(appIconId);
  }
}
