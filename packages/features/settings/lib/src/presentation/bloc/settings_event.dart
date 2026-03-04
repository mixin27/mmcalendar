import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

final class ChangeThemeMode extends SettingsEvent {
  final ThemeMode themeMode;

  const ChangeThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

final class ChangeThemePreset extends SettingsEvent {
  final String presetId;

  const ChangeThemePreset(this.presetId);

  @override
  List<Object?> get props => [presetId];
}

final class ChangeAppIcon extends SettingsEvent {
  final String appIconId;

  const ChangeAppIcon(this.appIconId);

  @override
  List<Object?> get props => [appIconId];
}

final class ChangeAppLanguage extends SettingsEvent {
  final String languageCode;

  const ChangeAppLanguage(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

final class ChangeCalendarLanguage extends SettingsEvent {
  final Language language;

  const ChangeCalendarLanguage(this.language);

  @override
  List<Object?> get props => [language];
}

final class UpdateCalendarConfiguration extends SettingsEvent {
  final CalendarConfig config;

  const UpdateCalendarConfiguration(this.config);

  @override
  List<Object?> get props => [config];
}

final class ToggleDisplayPreference extends SettingsEvent {
  final String key;
  final bool value;

  const ToggleDisplayPreference(this.key, this.value);

  @override
  List<Object?> get props => [key, value];
}

final class ResetAllSettings extends SettingsEvent {
  const ResetAllSettings();
}

// Settings Bloc Event for custom colors
final class UpdateCustomColors extends SettingsEvent {
  final ColorScheme colorScheme;

  const UpdateCustomColors(this.colorScheme);

  @override
  List<Object?> get props => [colorScheme];
}

final class UpdateAnalyticsConsent extends SettingsEvent {
  final bool enableAnalytics;

  const UpdateAnalyticsConsent(this.enableAnalytics);

  @override
  List<Object?> get props => [enableAnalytics];
}

final class UpdateCrashlyticsConsent extends SettingsEvent {
  final bool enableCrashlytics;

  const UpdateCrashlyticsConsent(this.enableCrashlytics);

  @override
  List<Object?> get props => [enableCrashlytics];
}

final class MarkConsentDialogShown extends SettingsEvent {
  const MarkConsentDialogShown();

  @override
  List<Object?> get props => [];
}

final class ShowConsentDialogIfNeeded extends SettingsEvent {
  const ShowConsentDialogIfNeeded();

  @override
  List<Object?> get props => [];
}
