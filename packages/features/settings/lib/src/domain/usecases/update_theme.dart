import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';

import '../repositories/settings_repository.dart';

class UpdateTheme {
  final SettingsRepository repository;

  UpdateTheme(this.repository);

  Future<Either<Failure, void>> updateMode(ThemeMode mode) async {
    return await repository.updateThemeMode(mode);
  }

  Future<Either<Failure, void>> updatePreset(String presetId) async {
    return await repository.updateThemePreset(presetId);
  }

  Future<Either<Failure, void>> updateCustomColors(ColorScheme colors) async {
    return await repository.updateCustomColors(colors);
  }
}
