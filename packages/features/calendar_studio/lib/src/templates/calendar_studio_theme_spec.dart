import 'dart:math' as math;
import 'dart:ui';

/// Palette roles shared by the round-2 presets
/// (`docs/calendar-studio-theme-presets*.html`).
///
/// Templates take every colour from here instead of hard-coding values, so a
/// preset's grid, legend, titles and decorations stay consistent, and the
/// contrast rules in [contrastIssues] can be checked in tests.
class CalendarStudioThemeSpec {
  const CalendarStudioThemeSpec({
    required this.paper,
    required this.primary,
    required this.accent,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.holiday,
    required this.weekend,
    required this.sabbath,
    int? onPrimary,
    int? onPrimaryMuted,
    int? event,
    int? moon,
  }) : onPrimary = onPrimary ?? paper,
       onPrimaryMuted = onPrimaryMuted ?? onPrimary ?? paper,
       event = event ?? primary,
       moon = moon ?? accent;

  final int paper;
  final int primary;
  final int accent;
  final int ink;
  final int inkMuted;
  final int line;
  final int holiday;
  final int weekend;
  final int sabbath;

  /// Text on [primary] panels and bands.
  final int onPrimary;

  /// Secondary text on [primary] panels (the mockups' inkMuted was unreadable
  /// there).
  final int onPrimaryMuted;
  final int event;
  final int moon;

  /// Calendar grid style keys for this palette.
  Map<String, Object?> gridStyle({
    String gridLines = 'lined',
    bool mini = false,
    int? lineColor,
  }) => {
    'gridLines': gridLines,
    'inkColor': ink,
    'secondaryColor': inkMuted,
    'mutedColor': inkMuted,
    'headerColor': primary,
    'lineColor': lineColor ?? line,
    'holidayColor': holiday,
    'weekendColor': weekend,
    'sabbathColor': sabbath,
    'eventColor': event,
    'numberFont': mini ? 'sans' : 'serif',
    'rows': 'auto',
    'rowHeight': 1.0,
  };

  /// Themed legend style keys.
  Map<String, Object?> legendStyle({
    double fontSize = 10,
    String align = 'left',
    int? inkColor,
  }) => {
    'inkColor': inkColor ?? ink,
    'mutedColor': inkMuted,
    'holidayColor': holiday,
    'sabbathColor': sabbath,
    'moonColor': moon,
    'eventColor': event,
    'fontSize': fontSize,
    'align': align,
  };

  /// Pairs that must stay readable, with the minimum WCAG ratio for each.
  List<String> contrastIssues() {
    final checks = <(String, int, int, double)>[
      ('ink on paper', ink, paper, 4.5),
      ('holiday on paper', holiday, paper, 3),
      ('weekend on paper', weekend, paper, 3),
      ('sabbath on paper', sabbath, paper, 3),
      ('header on paper', primary, paper, 3),
      ('onPrimary on primary', onPrimary, primary, 4.5),
      ('onPrimaryMuted on primary', onPrimaryMuted, primary, 3),
    ];
    return [
      for (final (name, fg, bg, minimum) in checks)
        if (contrastRatio(fg, bg) < minimum)
          '$name is ${contrastRatio(fg, bg).toStringAsFixed(2)}:1 '
              '(needs $minimum:1)',
      if (holiday == weekend) 'holiday and weekend share a colour',
    ];
  }
}

/// WCAG 2.x contrast ratio between two opaque ARGB colours.
double contrastRatio(int a, int b) {
  final la = _luminance(Color(a));
  final lb = _luminance(Color(b));
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

double _luminance(Color color) {
  double channel(double value) => value <= .03928
      ? value / 12.92
      : math.pow((value + .055) / 1.055, 2.4).toDouble();
  return .2126 * channel(color.r) +
      .7152 * channel(color.g) +
      .0722 * channel(color.b);
}
