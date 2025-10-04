import 'package:flutter/material.dart';

import '../app_event.dart';

/// Fired when theme mode is changed
class ThemeModeChangedEvent extends AppEvent {
  final ThemeMode themeMode;

  ThemeModeChangedEvent(this.themeMode);
}

/// Fired when custom colors are changed
class CustomColorsChangedEvent extends AppEvent {
  final ColorScheme colorScheme;

  CustomColorsChangedEvent(this.colorScheme);
}

/// Fired when theme preset is selected
class ThemePresetChangedEvent extends AppEvent {
  final String presetId;

  ThemePresetChangedEvent(this.presetId);
}
