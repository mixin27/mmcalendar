import 'package:flutter/material.dart';

/// Calendar meaning colours: one hue per meaning, tuned for light and dark.
///
/// Accent, text and outline come from the app theme; holiday, Sabbath and
/// marker colours are fixed so they read the same in every preset.
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
  });

  factory CalendarColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return CalendarColors._(
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
      accentSoft: scheme.primary.withValues(alpha: dark ? .2 : .11),
      label: scheme.onSurface,
      secondaryLabel: scheme.onSurfaceVariant,
      tertiaryLabel: scheme.onSurfaceVariant.withValues(alpha: .62),
      separator: scheme.outlineVariant.withValues(alpha: dark ? .5 : .7),
      holiday: dark ? const Color(0xFFFF5A5F) : const Color(0xFFE5383B),
      holidaySoft: dark ? const Color(0x29FF5A5F) : const Color(0x1AE5383B),
      sabbath: dark ? const Color(0xFFFFB840) : const Color(0xFFB7700B),
      sabbathSoft: dark ? const Color(0x29FFB840) : const Color(0x24F2A900),
      anniversary: dark ? const Color(0xFF3CC6C2) : const Color(0xFF0E8C88),
      astrology: dark ? const Color(0xFFA48BFF) : const Color(0xFF7553E0),
      fill: scheme.onSurface.withValues(alpha: dark ? .12 : .06),
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
}
