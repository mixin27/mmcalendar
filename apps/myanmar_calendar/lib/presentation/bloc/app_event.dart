part of 'app_bloc.dart';

sealed class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

final class InitializeApp extends AppEvent {
  const InitializeApp();
}

final class ChangeThemeMode extends AppEvent {
  final ThemeMode themeMode;

  const ChangeThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

final class ChangeThemePreset extends AppEvent {
  final String presetId;

  const ChangeThemePreset(this.presetId);

  @override
  List<Object?> get props => [presetId];
}
