part of 'app_bloc.dart';

sealed class AppState extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

final class AppInitializing extends AppState {
  const AppInitializing();
}

final class AppInitialized extends AppState {
  final ThemeMode themeMode;
  final String themePreset;
  final ColorScheme? themeColors;

  const AppInitialized({
    required this.themeMode,
    required this.themePreset,
    this.themeColors,
  });

  AppInitialized copyWith({
    ThemeMode? themeMode,
    String? themePreset,
    ColorScheme? themeColors,
  }) {
    return AppInitialized(
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      themeColors: themeColors ?? this.themeColors,
    );
  }

  @override
  List<Object?> get props => [themeMode, themePreset, themeColors];
}

final class AppError extends AppState {
  final String message;

  const AppError(this.message);

  @override
  List<Object?> get props => [message];
}
