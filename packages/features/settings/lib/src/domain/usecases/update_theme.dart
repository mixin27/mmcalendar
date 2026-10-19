import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' show AppStyle, CustomColors;

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

  Future<Either<Failure, void>> updateAppStyle(AppStyle style) =>
      repository.updateAppStyle(style);

  Future<Either<Failure, void>> updateCustomColors(CustomColors colors) async {
    return await repository.updateCustomColors(colors);
  }
}
