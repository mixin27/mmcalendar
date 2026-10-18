import '../models/calendar_studio_project_theme.dart';

/// A named text look (Title, Body…) built from the project theme, for the
/// Add panel and the text inspector.
class CalendarStudioTextStyle {
  const CalendarStudioTextStyle({
    required this.id,
    required this.label,
    required this.sample,
    required this.height,
    required this.build,
  });
  final String id;
  final String label;

  /// Text a new block starts with.
  final String sample;

  /// A sensible block height, as a fraction of the page.
  final double height;

  /// Style keys for [theme]; alignment is left to the block.
  final Map<String, Object?> Function(CalendarStudioProjectTheme theme) build;

  static final all = <CalendarStudioTextStyle>[
    CalendarStudioTextStyle(
      id: 'title',
      label: 'Title',
      sample: 'Title',
      height: .1,
      build: (t) => {
        'fontFamily': t.displayFont ?? 'Fraunces',
        'fontSize': 44,
        'fontWeight': 700,
        'color': t.color('primary'),
        'lineHeight': 1.1,
      },
    ),
    CalendarStudioTextStyle(
      id: 'heading',
      label: 'Heading',
      sample: 'Heading',
      height: .07,
      build: (t) => {
        'fontFamily': t.displayFont ?? 'Fraunces',
        'fontSize': 28,
        'fontWeight': 600,
        'color': t.color('ink'),
        'lineHeight': 1.2,
      },
    ),
    CalendarStudioTextStyle(
      id: 'body',
      label: 'Body',
      sample: 'Add a note for this month',
      height: .06,
      build: (t) => {
        'fontFamily': t.bodyFont ?? 'Noto Sans Myanmar',
        'fontSize': 16,
        'fontWeight': 400,
        'color': t.color('ink'),
        'lineHeight': 1.4,
      },
    ),
    CalendarStudioTextStyle(
      id: 'caption',
      label: 'Caption',
      sample: 'CAPTION',
      height: .04,
      build: (t) => {
        'fontFamily': t.bodyFont ?? 'Noto Sans Myanmar',
        'fontSize': 12,
        'fontWeight': 600,
        'letterSpacing': 1.5,
        'color': t.color('inkMuted'),
      },
    ),
    CalendarStudioTextStyle(
      id: 'myanmar-title',
      label: 'Myanmar title',
      sample: 'မြန်မာ ပြက္ခဒိန်',
      height: .1,
      build: (t) => {
        'fontFamily': 'Noto Serif Myanmar',
        'fontSize': 36,
        'fontWeight': 700,
        'color': t.color('primary'),
        // Myanmar marks stack above and below the line.
        'lineHeight': 1.7,
      },
    ),
  ];

  /// [style] with this look applied, keeping alignment and anything the look
  /// doesn't set.
  Map<String, Object?> applyTo(
    Map<String, Object?> style,
    CalendarStudioProjectTheme theme,
  ) {
    const reset = ['letterSpacing', 'lineHeight', 'italic'];
    return {
      for (final entry in style.entries)
        if (!reset.contains(entry.key)) entry.key: entry.value,
      ...build(theme),
    };
  }
}
