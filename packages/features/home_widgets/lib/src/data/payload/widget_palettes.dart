import 'package:calendar/calendar.dart'
    show CalendarThemeLook, CalendarThemePalette;
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' show CalendarGridTheme;
import 'package:shared_ui_kit/shared_ui_kit.dart' show AppTokens;

/// A widget style. [app] follows the app's colours; the themes match the
/// home calendar's grid themes of the same name.
enum WidgetStyleId {
  app,
  plain,
  pagoda,
  jade,
  deepField;

  static WidgetStyleId fromName(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => app);
}

/// The colours a native widget paints with, as ARGB ints.
@immutable
class WidgetPalette {
  const WidgetPalette({
    required this.bg,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.holiday,
    required this.moon,
    required this.sabbath,
    required this.soft,
    required this.holidaySoft,
    required this.line,
    required this.shade,
  });

  final Color bg;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color holiday;
  final Color moon;
  final Color sabbath;

  /// Accent wash (today, chips).
  final Color soft;
  final Color holidaySoft;
  final Color line;

  /// The unlit part of the moon.
  final Color shade;

  Map<String, int> toJson() => {
    'bg': bg.toARGB32(),
    'ink': ink.toARGB32(),
    'muted': muted.toARGB32(),
    'accent': accent.toARGB32(),
    'onAccent': onAccent.toARGB32(),
    'holiday': holiday.toARGB32(),
    'moon': moon.toARGB32(),
    'sabbath': sabbath.toARGB32(),
    'soft': soft.toARGB32(),
    'holidaySoft': holidaySoft.toARGB32(),
    'line': line.toARGB32(),
    'shade': shade.toARGB32(),
  };

  factory WidgetPalette.fromJson(Map<String, dynamic> json) {
    Color c(String key) => Color(json[key] as int);
    return WidgetPalette(
      bg: c('bg'),
      ink: c('ink'),
      muted: c('muted'),
      accent: c('accent'),
      onAccent: c('onAccent'),
      holiday: c('holiday'),
      moon: c('moon'),
      sabbath: c('sabbath'),
      soft: c('soft'),
      holidaySoft: c('holidaySoft'),
      line: c('line'),
      shade: c('shade'),
    );
  }

  /// The app's own look, from its design tokens.
  factory WidgetPalette.fromTokens(AppTokens t) => WidgetPalette(
    bg: t.surface,
    ink: t.label,
    muted: t.secondaryLabel,
    accent: t.accent,
    onAccent: t.onAccent,
    holiday: t.holiday,
    moon: t.moon,
    sabbath: t.sabbath,
    soft: t.accentSoft,
    holidaySoft: t.holidaySoft,
    line: t.separator,
    shade: t.fill,
  );

  factory WidgetPalette.fromTheme(
    CalendarThemePalette p, {
    required bool dark,
  }) => WidgetPalette(
    bg: p.paper,
    ink: p.ink,
    muted: p.inkMuted,
    accent: p.accent,
    onAccent: p.onAccent,
    holiday: p.holiday,
    moon: p.moon,
    sabbath: p.sabbath,
    soft: p.accent.withValues(alpha: dark ? .2 : .13),
    holidaySoft: p.holiday.withValues(alpha: dark ? .16 : .11),
    line: p.ink.withValues(alpha: .14),
    shade: p.ink.withValues(alpha: dark ? .16 : .12),
  );
}

/// Light and dark palettes for every style.
abstract final class WidgetPalettes {
  /// Saved by the app whenever its colours change, for the background
  /// refresh to reuse.
  static const appPaletteKey = 'widget_app_palette_v1';

  static const _plainLight = WidgetPalette(
    bg: Color(0xFFFFFFFF),
    ink: Color(0xFF0A0A0A),
    muted: Color(0xFF6E6E6E),
    accent: Color(0xFF0A0A0A),
    onAccent: Color(0xFFFFFFFF),
    holiday: Color(0xFFD0261E),
    moon: Color(0xFF0A0A0A),
    sabbath: Color(0xFF6E6E6E),
    soft: Color(0x12000000),
    holidaySoft: Color(0x1AD0261E),
    line: Color(0x1F000000),
    shade: Color(0x1F000000),
  );

  static const _plainDark = WidgetPalette(
    bg: Color(0xFF000000),
    ink: Color(0xFFFFFFFF),
    muted: Color(0xFF9A9A9A),
    accent: Color(0xFFFFFFFF),
    onAccent: Color(0xFF000000),
    holiday: Color(0xFFFF5A52),
    moon: Color(0xFFFFFFFF),
    sabbath: Color(0xFFBDBDBD),
    soft: Color(0x1FFFFFFF),
    holidaySoft: Color(0x29FF5A52),
    line: Color(0x24FFFFFF),
    shade: Color(0x29FFFFFF),
  );

  static const _themes = {
    WidgetStyleId.pagoda: CalendarGridTheme.pagoda,
    WidgetStyleId.jade: CalendarGridTheme.jade,
    WidgetStyleId.deepField: CalendarGridTheme.deepField,
  };

  /// `{style: {light: palette, dark: palette}}` for the payload. [app]
  /// is the app's light and dark look, or null to fall back to Plain.
  static Map<String, Object> all({
    ({WidgetPalette light, WidgetPalette dark})? app,
  }) {
    Map<String, Object> pair(WidgetPalette light, WidgetPalette dark) => {
      'light': light.toJson(),
      'dark': dark.toJson(),
    };
    return {
      for (final style in WidgetStyleId.values)
        style.name: switch (style) {
          WidgetStyleId.app => pair(
            app?.light ?? _plainLight,
            app?.dark ?? _plainDark,
          ),
          WidgetStyleId.plain => pair(_plainLight, _plainDark),
          _ => () {
            final look = CalendarThemeLook.forTheme(_themes[style]!)!;
            return pair(
              WidgetPalette.fromTheme(look.light, dark: false),
              WidgetPalette.fromTheme(look.dark, dark: true),
            );
          }(),
        },
    };
  }
}
