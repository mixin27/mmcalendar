import 'package:flutter/material.dart';

import 'app_style.dart';

/// The design tokens every screen reads: surfaces, text, the one accent and
/// the calendar meaning colours, resolved for a style and a colour scheme.
///
/// Clear uses fixed iOS-like neutrals (grouped grey on white, true black in
/// dark); Material derives its neutrals from the theme's colour scheme.
/// Both take the accent from the scheme, so theme presets still apply.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.style,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.fill,
    required this.separator,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.holiday,
    required this.holidaySoft,
    required this.moon,
    required this.sabbath,
    required this.sabbathSoft,
    required this.success,
    required this.bar,
    required this.groupRadius,
    required this.controlRadius,
    required this.sheetRadius,
  });

  /// [style] must be resolved (not [AppStyle.automatic]).
  factory AppTokens.resolve({
    required AppStyle style,
    required ColorScheme scheme,
  }) {
    final dark = scheme.brightness == Brightness.dark;
    final clear = style == AppStyle.clear;
    final accent = scheme.primary;
    // Tonal containers from the primary, so presets without container
    // roles still get visible groups and bars.
    Color tone(double light, double darkAmount) => Color.alphaBlend(
      accent.withValues(alpha: dark ? darkAmount : light),
      scheme.surface,
    );
    return AppTokens(
      style: clear ? AppStyle.clear : AppStyle.material,
      background: clear
          ? (dark ? const Color(0xFF000000) : const Color(0xFFF2F2F7))
          : scheme.surface,
      surface: clear
          ? (dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF))
          : tone(.05, .08),
      surfaceRaised: clear
          ? (dark ? const Color(0xFF2C2C2E) : const Color(0xFFF7F7FA))
          : tone(.08, .12),
      fill: clear
          ? (dark ? const Color(0x42767680) : const Color(0x1F767680))
          : tone(.12, .18),
      separator: clear
          ? (dark ? const Color(0x9E545458) : const Color(0x293C3C43))
          : scheme.outlineVariant,
      label: clear
          ? (dark ? const Color(0xFFF5F5F7) : const Color(0xFF0A0A0F))
          : scheme.onSurface,
      secondaryLabel: clear
          ? (dark ? const Color(0xFFA1A1A8) : const Color(0xFF6B6B73))
          : scheme.onSurfaceVariant,
      tertiaryLabel: clear
          ? (dark ? const Color(0xFF6C6C72) : const Color(0xFFA1A1A8))
          : scheme.onSurfaceVariant.withValues(alpha: .6),
      accent: accent,
      onAccent: scheme.onPrimary,
      accentSoft: accent.withValues(alpha: dark ? .2 : .11),
      holiday: dark ? const Color(0xFFFF5A5F) : const Color(0xFFE5383B),
      holidaySoft: dark ? const Color(0x29FF5A5F) : const Color(0x1AE5383B),
      moon: dark ? const Color(0xFFFFC530) : const Color(0xFFF2A900),
      sabbath: dark ? const Color(0xFFFFB840) : const Color(0xFFB7700B),
      sabbathSoft: dark ? const Color(0x29FFB840) : const Color(0x24F2A900),
      success: dark ? const Color(0xFF34C77B) : const Color(0xFF1F9D63),
      bar: clear
          ? (dark ? const Color(0xDB161618) : const Color(0xDBF9F9FB))
          : tone(.08, .11),
      groupRadius: clear ? 14 : 16,
      controlRadius: clear ? 14 : 24,
      sheetRadius: clear ? 14 : 28,
    );
  }

  /// The tokens of the nearest theme, or Material ones derived from it.
  static AppTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppTokens>() ??
        AppTokens.resolve(style: AppStyle.material, scheme: theme.colorScheme);
  }

  final AppStyle style;
  bool get isClear => style == AppStyle.clear;

  /// Page background (grouped grey in Clear).
  final Color background;

  /// Groups, cards and sheets.
  final Color surface;
  final Color surfaceRaised;

  /// Fields, segmented tracks, chips.
  final Color fill;
  final Color separator;
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;

  /// Holidays, Sundays and destructive actions.
  final Color holiday;
  final Color holidaySoft;
  final Color moon;

  /// Sabbath labels (readable on white).
  final Color sabbath;
  final Color sabbathSoft;
  final Color success;

  /// Tab bar / navigation bar background.
  final Color bar;
  final double groupRadius;
  final double controlRadius;
  final double sheetRadius;

  @override
  AppTokens copyWith({AppStyle? style}) => style == null || style == this.style
      ? this
      : AppTokens(
          style: style,
          background: background,
          surface: surface,
          surfaceRaised: surfaceRaised,
          fill: fill,
          separator: separator,
          label: label,
          secondaryLabel: secondaryLabel,
          tertiaryLabel: tertiaryLabel,
          accent: accent,
          onAccent: onAccent,
          accentSoft: accentSoft,
          holiday: holiday,
          holidaySoft: holidaySoft,
          moon: moon,
          sabbath: sabbath,
          sabbathSoft: sabbathSoft,
          success: success,
          bar: bar,
          groupRadius: groupRadius,
          controlRadius: controlRadius,
          sheetRadius: sheetRadius,
        );

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    double d(double a, double b) => a + (b - a) * t;
    return AppTokens(
      style: t < .5 ? style : other.style,
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      fill: c(fill, other.fill),
      separator: c(separator, other.separator),
      label: c(label, other.label),
      secondaryLabel: c(secondaryLabel, other.secondaryLabel),
      tertiaryLabel: c(tertiaryLabel, other.tertiaryLabel),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      accentSoft: c(accentSoft, other.accentSoft),
      holiday: c(holiday, other.holiday),
      holidaySoft: c(holidaySoft, other.holidaySoft),
      moon: c(moon, other.moon),
      sabbath: c(sabbath, other.sabbath),
      sabbathSoft: c(sabbathSoft, other.sabbathSoft),
      success: c(success, other.success),
      bar: c(bar, other.bar),
      groupRadius: d(groupRadius, other.groupRadius),
      controlRadius: d(controlRadius, other.controlRadius),
      sheetRadius: d(sheetRadius, other.sheetRadius),
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => AppTokens.of(this);
  bool get isClearStyle => AppTokens.of(this).isClear;
}
