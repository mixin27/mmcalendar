import 'package:flutter/material.dart';

extension ColorExtension on Color {
  /// Convert color to hex string
  String toHex({bool includeAlpha = false}) {
    if (includeAlpha) {
      return '#${((a * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
          '${((r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
          '${((g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
          '${((b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}';
    }
    return '#${((r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
        '${((g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
        '${((b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}';
  }

  /// Get a darker shade of this color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }

  /// Get a lighter shade of this color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lightened.toColor();
  }

  /// Check if color is dark
  bool get isDark => computeLuminance() < 0.5;

  /// Check if color is light
  bool get isLight => !isDark;

  /// Get contrasting text color (black or white)
  Color get contrastingTextColor => isDark ? Colors.white : Colors.black;
}
