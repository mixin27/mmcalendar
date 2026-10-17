import 'package:flutter/material.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

/// Calendar meaning colours, read from the app's design tokens plus the two
/// marker hues only the calendar uses.
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
  });

  factory CalendarColors.of(BuildContext context) {
    final t = AppTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
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
