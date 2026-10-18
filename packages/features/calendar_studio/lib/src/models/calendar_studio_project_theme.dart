import 'package:equatable/equatable.dart';

import '../templates/calendar_studio_preset_specs.dart';
import 'calendar_studio_document.dart';
import 'calendar_studio_types.dart';

/// A project's colours and fonts by role. Elements keep literal colours (so
/// the renderer and export never change), and switching theme rewrites every
/// colour that matched a role of the old theme to the same role of the new.
class CalendarStudioProjectTheme extends Equatable {
  const CalendarStudioProjectTheme({
    required this.id,
    required this.name,
    required this.colors,
    this.displayFont,
    this.bodyFont,
  });

  /// Colour roles, in the order the UI lists them.
  static const roles = [
    'paper',
    'primary',
    'accent',
    'ink',
    'inkMuted',
    'line',
    'holiday',
    'sabbath',
  ];

  static const roleLabels = {
    'paper': 'Paper',
    'primary': 'Primary',
    'accent': 'Accent',
    'ink': 'Ink',
    'inkMuted': 'Muted',
    'line': 'Lines',
    'holiday': 'Holiday',
    'sabbath': 'Sabbath',
  };

  final String id;
  final String name;

  /// Role → ARGB colour. Missing roles fall back to [color]'s defaults.
  final Map<String, int> colors;

  /// Headings (month titles); null keeps the elements' own fonts.
  final String? displayFont;
  final String? bodyFont;

  int color(String role) => colors[role] ?? _fallback(role);

  int _fallback(String role) => switch (role) {
    'paper' => 0xFFFFFFFF,
    'inkMuted' =>
      colors['ink'] != null
          ? (colors['ink']! & 0x00FFFFFF) | 0x99000000
          : 0xFF6B6B73,
    'line' => 0xFFDDDDDD,
    'holiday' => colors['primary'] ?? 0xFFC0392B,
    'sabbath' => colors['accent'] ?? 0xFF8A6A1F,
    'accent' => colors['primary'] ?? 0xFF2F5BEA,
    _ => 0xFF15201D,
  };

  CalendarStudioProjectTheme copyWith({
    String? id,
    String? name,
    Map<String, int>? colors,
    String? displayFont,
    String? bodyFont,
  }) => CalendarStudioProjectTheme(
    id: id ?? this.id,
    name: name ?? this.name,
    colors: colors ?? this.colors,
    displayFont: displayFont ?? this.displayFont,
    bodyFont: bodyFont ?? this.bodyFont,
  );

  /// This theme with one role changed; it becomes a custom theme.
  CalendarStudioProjectTheme withColor(String role, int value) => copyWith(
    id: 'custom',
    name: id == 'custom' ? name : '$name (custom)',
    colors: {...colors, role: value},
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'colors': colors,
    if (displayFont != null) 'displayFont': displayFont,
    if (bodyFont != null) 'bodyFont': bodyFont,
  };

  static CalendarStudioProjectTheme? fromJson(Object? value) {
    if (value is! Map) return null;
    final colors = value['colors'];
    if (colors is! Map) return null;
    return CalendarStudioProjectTheme(
      id: value['id'] as String? ?? 'custom',
      name: value['name'] as String? ?? 'Custom',
      colors: {
        for (final MapEntry(:key, :value) in colors.entries)
          if (value is int) key as String: value,
      },
      displayFont: value['displayFont'] as String?,
      bodyFont: value['bodyFont'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, colors, displayFont, bodyFont];
}

/// Built-in themes and the theme a project uses.
abstract final class CalendarStudioProjectThemes {
  /// Every preset's theme, plus a few plain ones, for the theme picker.
  static final List<CalendarStudioProjectTheme> library = [
    for (final spec in calendarStudioPresetSpecs) ?_fromSpec(spec),
    ..._extras,
  ];

  static final _extras = [
    _named('jade', 'Jade', {
      'paper': 0xFFF3F7F4,
      'primary': 0xFF0E6B5C,
      'accent': 0xFFC9A15A,
      'ink': 0xFF14211D,
      'holiday': 0xFFB23A2E,
    }),
    _named('lacquer', 'Lacquer', {
      'paper': 0xFFF7EDE2,
      'primary': 0xFF9B2D1F,
      'accent': 0xFFD9A441,
      'ink': 0xFF2A120D,
      'holiday': 0xFF9B2D1F,
    }),
    _named('indigo', 'Indigo', {
      'paper': 0xFFEEF1F8,
      'primary': 0xFF2F3E8C,
      'accent': 0xFFE0A040,
      'ink': 0xFF141A33,
      'holiday': 0xFFC0392B,
    }),
    _named('saffron', 'Saffron', {
      'paper': 0xFFFFF6E6,
      'primary': 0xFFD9822B,
      'accent': 0xFF7A4E1E,
      'ink': 0xFF2E1C0C,
      'holiday': 0xFFB23A2E,
    }),
    _named('mono', 'Mono', {
      'paper': 0xFFFFFFFF,
      'primary': 0xFF111111,
      'accent': 0xFF888888,
      'ink': 0xFF111111,
      'holiday': 0xFF111111,
    }),
  ];

  static CalendarStudioProjectTheme _named(
    String id,
    String name,
    Map<String, int> colors,
  ) => CalendarStudioProjectTheme(
    id: id,
    name: name,
    colors: {
      ...colors,
      'inkMuted': (colors['ink']! & 0x00FFFFFF) | 0x99000000,
      'line': (colors['primary']! & 0x00FFFFFF) | 0x33000000,
      'sabbath': colors['accent']!,
    },
  );

  static CalendarStudioProjectTheme? _fromSpec(Map<String, Object?> spec) {
    final theme = spec['theme'];
    if (theme is! Map) return null;
    final fonts = spec['fonts'] as Map?;
    return CalendarStudioProjectTheme(
      id: spec['id']! as String,
      name: spec['name']! as String,
      colors: {
        for (final role in CalendarStudioProjectTheme.roles)
          role: ?_hex(theme[role]),
      },
      displayFont: fonts?['display'] as String?,
      bodyFont: fonts?['ui'] as String?,
    );
  }

  static int? _hex(Object? value) {
    if (value is! String || !value.startsWith('#')) return null;
    final hex = value.substring(1);
    return int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  }

  /// The theme [project] uses: the stored one, else its preset's, else one
  /// read from its calendar grid's colours.
  static CalendarStudioProjectTheme of(CalendarStudioProject project) =>
      project.theme ??
      library.where((t) => t.id == project.templateId).firstOrNull ??
      infer(project);

  /// A theme from the colours a project already uses (older templates
  /// predate stored themes).
  static CalendarStudioProjectTheme infer(CalendarStudioProject project) {
    final page = project.pages.isEmpty ? null : project.pages.first;
    final colors = <String, int>{};
    if (page != null) {
      colors['paper'] = page.canvas.backgroundColor;
      final grid = page.blocks
          .where((b) => b.type == CalendarStudioBlockType.calendarGrid)
          .firstOrNull;
      void take(String role, Object? value) {
        if (value is int) colors.putIfAbsent(role, () => value);
      }

      if (grid != null) {
        take('ink', grid.style['inkColor']);
        take('primary', grid.style['headerColor']);
        take('primary', grid.style['weekendColor']);
        take('inkMuted', grid.style['mutedColor']);
        take('inkMuted', grid.style['secondaryColor']);
        take('line', grid.style['lineColor']);
        take('holiday', grid.style['holidayColor']);
        take('sabbath', grid.style['sabbathColor']);
      }
      for (final b in page.blocks) {
        if (b.type == CalendarStudioBlockType.text) {
          take('ink', b.style['color']);
        }
        if (b.type == CalendarStudioBlockType.shape ||
            b.type == CalendarStudioBlockType.decoration) {
          final fill = b.style['fill'] ?? b.style['color'];
          if (fill is int && !colors.containsValue(fill)) take('accent', fill);
        }
      }
      // Without a coloured header, the first heading that isn't body ink
      // carries the brand colour.
      for (final b in page.blocks) {
        final color = b.style['color'];
        if (b.type == CalendarStudioBlockType.text &&
            color is int &&
            color != colors['ink']) {
          take('primary', color);
        }
      }
      take('primary', colors['accent']);
    }
    return CalendarStudioProjectTheme(
      id: project.templateId,
      name: 'Original',
      colors: colors,
    );
  }
}

/// Switching a project from one theme to another.
abstract final class CalendarStudioRetheme {
  /// Style keys that hold colours.
  static bool isColorKey(String key) =>
      key == 'color' ||
      key == 'fill' ||
      key == 'accent' ||
      key.endsWith('Color');

  /// [project] with every colour that matched a role of [from] changed to
  /// that role in [to], every heading in [from]'s display font set to
  /// [to]'s, and [to] stored as the project theme.
  static CalendarStudioProject apply(
    CalendarStudioProject project,
    CalendarStudioProjectTheme from,
    CalendarStudioProjectTheme to,
  ) {
    // Old colour → role; earlier roles win when two share a colour.
    final roleOf = <int, String>{};
    for (final role in CalendarStudioProjectTheme.roles.reversed) {
      if (from.colors[role] case final c?) roleOf[c] = role;
    }
    int map(int value) {
      final role = roleOf[value];
      return role == null ? value : to.color(role);
    }

    Map<String, Object?> mapStyle(Map<String, Object?> style) {
      var changed = false;
      final out = <String, Object?>{};
      for (final MapEntry(:key, :value) in style.entries) {
        Object? next = value;
        if (value is int && isColorKey(key)) {
          next = map(value);
        } else if (key == 'fontFamily' &&
            value is String &&
            from.displayFont != null &&
            to.displayFont != null &&
            value == from.displayFont) {
          next = to.displayFont;
        }
        if (next != value) changed = true;
        out[key] = next;
      }
      return changed ? out : style;
    }

    return project.copyWith(
      theme: to,
      pages: [
        for (final page in project.pages)
          page.copyWith(
            canvas: page.canvas.copyWith(
              backgroundColor: map(page.canvas.backgroundColor),
            ),
            blocks: [
              for (final block in page.blocks)
                block.copyWith(style: mapStyle(block.style)),
            ],
          ),
      ],
    );
  }
}
