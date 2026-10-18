import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'custom_colors.dart';

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
      name: 'Blue',
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

  /// The light and dark schemes for a preset, or for the user's custom
  /// colours (an accent plus any hand-set slots per brightness).
  static ({ColorScheme light, ColorScheme dark}) schemesFor(
    String presetId, {
    CustomColors? custom,
  }) {
    if (presetId == 'custom' && custom != null) {
      return (
        light: custom.scheme(Brightness.light),
        dark: custom.scheme(Brightness.dark),
      );
    }
    final preset = getPreset(presetId);
    return (light: preset.lightColors, dark: preset.darkColors);
  }

  static ThemePreset getPreset(String id) {
    return presets[id] ?? presets['modern']!;
  }

  static List<ThemePreset> getAllPresets() {
    return presets.values.toList();
  }
}
