import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';

import '../repositories/settings_repository.dart';

class MarkAsConsentDialogShown {
  final SettingsRepository repository;

  MarkAsConsentDialogShown(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.markConsentDialogShown();
  }
}
