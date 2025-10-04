import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'color_schemes.dart';

class ThemePreset extends Equatable {
  final String id;
  final String name;
  final ColorScheme lightColors;
  final ColorScheme darkColors;
  final String? icon;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.lightColors,
    required this.darkColors,
    this.icon,
  });

  @override
  List<Object?> get props => [id, name, lightColors, darkColors, icon];
}

class ThemePresets {
  static const Map<String, ThemePreset> presets = {
    'modern': ThemePreset(
      id: 'modern',
      name: 'Modern',
      lightColors: AppColorSchemes.modernLight,
      darkColors: AppColorSchemes.modernDark,
      icon: '🎨',
    ),
    'traditional': ThemePreset(
      id: 'traditional',
      name: 'Traditional Myanmar',
      lightColors: AppColorSchemes.traditionalLight,
      darkColors: AppColorSchemes.traditionalDark,
      icon: '🏛️',
    ),
    'ocean': ThemePreset(
      id: 'ocean',
      name: 'Ocean Blue',
      lightColors: AppColorSchemes.oceanLight,
      darkColors: AppColorSchemes.oceanDark,
      icon: '🌊',
    ),
    'forest': ThemePreset(
      id: 'forest',
      name: 'Forest Green',
      lightColors: AppColorSchemes.forestLight,
      darkColors: AppColorSchemes.forestDark,
      icon: '🌳',
    ),
  };

  static ThemePreset getPreset(String id) {
    return presets[id] ?? presets['modern']!;
  }

  static List<ThemePreset> getAllPresets() {
    return presets.values.toList();
  }
}
