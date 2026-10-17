import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'calendar_grid_themes.dart';

/// Calendar meaning colours, read from the app's design tokens plus the two
/// marker hues only the calendar uses. Under a [CalendarThemeScope] with a
/// grid theme, they come from that theme's palette instead.
@immutable
class CalendarColors {
  const CalendarColors._({
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.separator,
    required this.holiday,
    required this.holidaySoft,
    required this.sabbath,
    required this.sabbathSoft,
    required this.anniversary,
    required this.astrology,
    required this.fill,
    required this.surface,
    required this.moon,
    this.paper,
    this.numberFamily,
    this.fontResolver,
  });

  factory CalendarColors.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final look = CalendarThemeScope.lookOf(context);
    if (look != null) {
      return CalendarColors._themed(
        look.of(Theme.of(context).brightness),
        dark: dark,
        numberFamily: look.numberFamily,
        fontResolver: CalendarFontScope.maybeOf(context),
      );
    }
    final t = AppTokens.of(context);
    return CalendarColors._(
      accent: t.accent,
      onAccent: t.onAccent,
      accentSoft: t.accentSoft,
      label: t.label,
      secondaryLabel: t.secondaryLabel,
      tertiaryLabel: t.tertiaryLabel,
      separator: t.separator,
      holiday: t.holiday,
      holidaySoft: t.holidaySoft,
      sabbath: t.sabbath,
      sabbathSoft: t.sabbathSoft,
      anniversary: dark ? const Color(0xFF3CC6C2) : const Color(0xFF0E8C88),
      astrology: dark ? const Color(0xFFA48BFF) : const Color(0xFF7553E0),
      fill: t.fill,
      surface: t.surface,
      moon: t.moon,
    );
  }

  factory CalendarColors._themed(
    CalendarThemePalette p, {
    required bool dark,
    required String numberFamily,
    CalendarFontResolver? fontResolver,
  }) => CalendarColors._(
    accent: p.accent,
    onAccent: p.onAccent,
    accentSoft: p.accent.withValues(alpha: dark ? .24 : .14),
    label: p.ink,
    secondaryLabel: p.inkMuted,
    tertiaryLabel: Color.lerp(p.ink, p.paper, .55)!,
    separator: p.ink.withValues(alpha: .15),
    holiday: p.holiday,
    holidaySoft: p.holiday.withValues(alpha: dark ? .16 : .11),
    sabbath: p.sabbath,
    sabbathSoft: p.moon.withValues(alpha: dark ? .16 : .2),
    anniversary: dark ? const Color(0xFF3CC6C2) : const Color(0xFF0E8C88),
    astrology: dark ? const Color(0xFFA48BFF) : const Color(0xFF7553E0),
    fill: p.ink.withValues(alpha: .08),
    surface: p.surface,
    moon: p.moon,
    paper: p.paper,
    numberFamily: numberFamily,
    fontResolver: fontResolver,
  );

  /// The theme's paper behind the header and grid; null for app colours.
  final Color? paper;

  /// The theme's typeface for day numbers and the month title.
  final String? numberFamily;
  final CalendarFontResolver? fontResolver;

  /// [base] in the theme's number typeface (weight kept), or unchanged for
  /// app colours or when no font resolver is provided.
  ///
  /// The result doesn't inherit: the app's text styles carry the ui_kit font
  /// package, and merging a fully qualified family into them would prefix
  /// it twice. Myanmar glyphs (a Myanmar month title) fall back to Noto Sans
  /// Myanmar, as everywhere else in the app.
  TextStyle numberStyle(TextStyle base) {
    final family = numberFamily;
    final resolve = fontResolver;
    if (family == null || resolve == null) return base;
    final weight = base.fontWeight ?? FontWeight.w400;
    final font = resolve(family, weight);
    return TextStyle(
      inherit: false,
      fontFamily: font.fontFamily,
      fontFamilyFallback: AppTextStyles.qualifiedFallback,
      fontVariations: font.fontVariations,
      fontWeight: weight,
      fontSize: base.fontSize ?? 14,
      height: base.height,
      letterSpacing: base.letterSpacing,
      color: base.color ?? label,
      // Lining figures: some display faces (Cormorant) default to old-style
      // numerals, which look uneven in a grid.
      fontFeatures: [...?base.fontFeatures, const FontFeature.liningFigures()],
      textBaseline: TextBaseline.alphabetic,
      leadingDistribution: base.leadingDistribution,
    );
  }

  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color separator;
  final Color holiday;
  final Color holidaySoft;
  final Color sabbath;
  final Color sabbathSoft;
  final Color anniversary;
  final Color astrology;
  final Color fill;
  final Color surface;
  final Color moon;
}
