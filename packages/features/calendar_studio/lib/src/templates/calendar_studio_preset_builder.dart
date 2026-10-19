import 'dart:math' as math;

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import 'calendar_studio_bindings.dart';
import 'calendar_studio_templates.dart';

/// Builds a [CalendarStudioTemplate] from a round-2 preset spec
/// (`calendar_studio_preset_specs.dart`, derived from
/// `docs/calendar-studio-theme-presets*.html`).
///
/// Specs use 0–1 bounds, theme role names for colours and font sizes in the
/// mockup canvas's units; this resolves roles against the preset palette,
/// scales type to the Studio design size, and writes each page's titles for
/// that page's month in the project's language.
abstract final class CalendarStudioPresetBuilder {
  static CalendarStudioTemplate build(Map<String, Object?> spec) {
    final canvasSpec = spec['canvas']! as Map<String, Object?>;
    final preset = canvasSpec['preset']! as String;
    final theme = _Theme(spec['theme']! as Map<String, Object?>);
    final canvas = switch (preset) {
      'a4_landscape' => StudioCanvas(
        width: 297,
        height: 210,
        backgroundColor: theme.color('paper'),
      ),
      'a3_portrait' => StudioCanvas(
        width: 297,
        height: 420,
        backgroundColor: theme.color('paper'),
      ),
      'square' => StudioCanvas(
        width: 600,
        height: 600,
        backgroundColor: theme.color('paper'),
      ),
      'story' => StudioCanvas(
        width: 360,
        height: 640,
        backgroundColor: theme.color('paper'),
      ),
      _ => StudioCanvas(
        width: 210,
        height: 297,
        backgroundColor: theme.color('paper'),
      ),
    };
    final designWidth = switch (preset) {
      'a4_landscape' => 842.0,
      'square' => 600.0,
      'story' => 360.0,
      _ => 595.0,
    };
    final scale = designWidth / (canvasSpec['width']! as num).toDouble();
    final monthly = spec['monthly'] as bool? ?? true;
    final id = spec['id']! as String;
    final name = spec['name']! as String;
    final blocks = (spec['blocks']! as List).cast<Map<String, Object?>>();
    return CalendarStudioTemplate(
      id: id,
      name: name,
      category: spec['label']! as String,
      canvas: canvas,
      monthly: monthly,
      collection: spec['collection'] as String?,
      moods: (spec['moods'] as List?)?.cast<String>() ?? const [],
      palette: [
        for (final role in const [
          'paper',
          'primary',
          'accent',
          'ink',
          'holiday',
        ])
          theme.color(role),
      ],
      create: ({required id, required source, required now}) {
        final pageCount = monthly ? source.pageCount : 1;
        return CalendarStudioProject(
          id: id,
          name: '$name ${source.year}',
          templateId: spec['id']! as String,
          source: source,
          createdAt: now,
          updatedAt: now,
          pages: List.generate(pageCount, (index) {
            final absolute = source.month - 1 + index;
            final year = source.year + absolute ~/ 12;
            final month = absolute % 12 + 1;
            final context = _PageContext(
              theme: theme,
              scale: scale,
              designWidth: designWidth,
              language: source.language,
              year: year,
              month: month,
              fonts:
                  (spec['fonts'] as Map?)?.cast<String, Object?>() ?? const {},
            );
            return CalendarStudioPage(
              id: 'page-$index',
              label: _englishMonths[month - 1],
              year: year,
              month: month,
              canvas: canvas,
              blocks: [
                for (var i = 0; i < blocks.length; i++)
                  ...context.blocks(blocks[i], i),
              ],
            );
          }),
        );
      },
    );
  }
}

class _Theme {
  _Theme(this.roles);
  final Map<String, Object?> roles;

  /// A role name (`primary`) or a literal `#RRGGBB` / `#AARRGGBB`.
  int color(Object? value, [int fallback = 0xFF15201D]) {
    if (value is! String) return fallback;
    final literal = value.startsWith('#') ? value : roles[value];
    if (literal is! String || !literal.startsWith('#')) return fallback;
    final hex = literal.substring(1);
    return int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
  }
}

class _PageContext {
  const _PageContext({
    required this.theme,
    required this.scale,
    required this.designWidth,
    required this.language,
    required this.year,
    required this.month,
    required this.fonts,
  });
  final _Theme theme;
  final double scale;
  final double designWidth;
  final CalendarStudioLanguage language;
  final int year;
  final int month;
  final Map<String, Object?> fonts;

  /// Smallest legible size for small print (legends, lists) on any canvas.
  double get minReadable => designWidth * .014;

  /// Mockup UI faces (Inter, Work Sans, Nunito Sans) map to the app's Myanmar
  /// sans, which also covers Latin; display faces are bundled.
  String family(Object? value) => switch (value) {
    'Inter' || 'Work Sans' || 'Nunito Sans' || null => 'Noto Sans Myanmar',
    final String name => name,
    _ => 'Noto Sans Myanmar',
  };

  StudioRect rect(Object? value) {
    final v = [for (final item in value! as List) (item as num).toDouble()];
    final left = v[0].clamp(0.0, 1.0);
    final top = v[1].clamp(0.0, 1.0);
    return StudioRect(
      left: left,
      top: top,
      width: math.max(.001, math.min(v[2], 1 - left)),
      height: math.max(.001, math.min(v[3], 1 - top)),
    );
  }

  List<CalendarStudioBlock> blocks(Map<String, Object?> spec, int index) {
    final type = spec['type']! as String;
    final id = '$type-$index';
    final rotation =
        ((spec['rotation'] as num?)?.toDouble() ?? 0) * math.pi / 180;
    CalendarStudioBlock block(
      CalendarStudioBlockType kind,
      String name, {
      Map<String, Object?> content = const {},
      Map<String, Object?> style = const {},
    }) => CalendarStudioBlock(
      id: id,
      type: kind,
      name: name,
      bounds: rect(spec['bounds']),
      rotation: rotation,
      zIndex: index,
      content: content,
      style: style,
    );
    return switch (type) {
      'text' => [_text(spec, block)],
      'shape' => [_shape(spec, block)],
      'decoration' => [
        block(
          CalendarStudioBlockType.decoration,
          spec['name'] as String? ?? _motifNames[spec['motif']] ?? 'Decoration',
          content: {
            'kind': spec['motif'],
            if (spec['avoid'] != null) 'avoid': spec['avoid'],
          },
          style: {
            'color': theme.color(spec['color']),
            'accent': theme.color(
              spec['accent'] ??
                  (spec['color'] == 'accent' ? 'primary' : 'accent'),
            ),
            'opacity': (spec['opacity'] as num?)?.toDouble() ?? 1,
          },
        ),
      ],
      'image' => [
        block(
          CalendarStudioBlockType.image,
          spec['name'] as String? ?? 'Photo',
          style: const {'imageFit': 'crop'},
        ),
      ],
      'calendarGrid' => [_grid(spec, block)],
      'annualGrid' => _annual(spec, index),
      'holidayLegend' => [_legend(spec, block)],
      'eventList' => [_list(spec, block)],
      _ => const [],
    };
  }

  CalendarStudioBlock _text(
    Map<String, Object?> spec,
    CalendarStudioBlock Function(
      CalendarStudioBlockType,
      String, {
      Map<String, Object?> content,
      Map<String, Object?> style,
    })
    block,
  ) {
    final style = (spec['style'] as Map?)?.cast<String, Object?>() ?? const {};
    final binding = spec['binding'] as String? ?? 'custom';
    final italic = style['fontStyle'] == 'italic';
    final bound = CalendarStudioBinding.tryParse(binding);
    final String text;
    final String? subtitle;
    final String name;
    if (bound == CalendarStudioBinding.monthTitle ||
        bound == CalendarStudioBinding.yearTitle) {
      (text, subtitle) = CalendarStudioBindings.resolve(
        bound!,
        language: language,
        year: year,
        month: month,
      );
      name = bound == CalendarStudioBinding.monthTitle ? 'Month title' : 'Year';
    } else {
      (text, subtitle) = (spec['text'] as String? ?? '', null);
      name = spec['name'] as String? ?? 'Text';
    }
    // Myanmar-script lines get more leading and are never slanted.
    final myanmar =
        bound != null &&
        RegExp('[\u1000-\u109F\uA9E0-\uA9FF\uAA60-\uAA7F]').hasMatch(text);
    return block(
      CalendarStudioBlockType.text,
      name,
      content: {
        'text': text,
        'subtitle': ?subtitle,
        if (binding == 'monthTitle' || binding == 'yearTitle')
          CalendarStudioBindings.key: binding,
        if (binding == 'monthTitle') CalendarStudioBindings.subtitleKey: true,
      },
      style: {
        'color': theme.color(style['color']),
        'fontSize': ((style['fontSize'] as num?)?.toDouble() ?? 20) * scale,
        'fontFamily': family(style['fontFamily'] ?? fonts['display']),
        'fontWeight': style['weight'] as int? ?? 600,
        'align': switch (style['align']) {
          'end' => 'right',
          'center' => 'center',
          _ => 'left',
        },
        'vAlign': style['vAlign'] == 'top' ? 'top' : 'center',
        // Never slant Myanmar script; the English line keeps the italic.
        'italic': italic && !myanmar,
        'subtitleItalic': italic,
        'subtitleColor': theme.color(style['subtitleColor'] ?? 'inkMuted'),
        if (myanmar) 'lineHeight': 1.5,
      },
    );
  }

  CalendarStudioBlock _shape(
    Map<String, Object?> spec,
    CalendarStudioBlock Function(
      CalendarStudioBlockType,
      String, {
      Map<String, Object?> content,
      Map<String, Object?> style,
    })
    block,
  ) {
    final shape = switch (spec['shape']) {
      'ellipse' => 'oval',
      'line' => 'line',
      _ => 'rectangle',
    };
    final fill = spec['fill'];
    final stroke = spec['stroke'];
    final strokeWidth =
        ((spec['strokeWidth'] as num?)?.toDouble() ?? 0) * scale;
    return block(
      CalendarStudioBlockType.shape,
      spec['name'] as String? ??
          switch (shape) {
            'line' => 'Rule',
            'oval' => 'Ellipse',
            _ => 'Panel',
          },
      content: {'shape': shape},
      style: {
        'color': theme.color(shape == 'line' ? stroke : fill ?? stroke),
        'strokeColor': theme.color(stroke ?? fill),
        'strokeWidth': shape == 'line'
            ? math.max(1.0, strokeWidth)
            : strokeWidth,
        'opacity': (spec['opacity'] as num?)?.toDouble() ?? 1,
        if (fill == null && shape != 'line') 'fill': 'none',
      },
    );
  }

  Map<String, Object?> _gridStyle(
    Map<String, Object?> style, {
    bool mini = false,
  }) => {
    'gridLines': switch (style['cellStyle']) {
      'boxed' => 'boxed',
      'lined' => 'lined',
      _ => 'none',
    },
    'inkColor': theme.color(style['textColor'] ?? 'ink'),
    'secondaryColor': theme.color(style['mutedColor'] ?? 'inkMuted'),
    'mutedColor': theme.color(style['mutedColor'] ?? 'inkMuted'),
    'weekendColor': theme.color(style['weekendColor'] ?? 'primary'),
    'holidayColor': theme.color(style['holidayColor'] ?? 'holiday'),
    'headerColor': theme.color(style['headerColor'] ?? 'primary'),
    'lineColor': theme.color(style['lineColor'] ?? 'line'),
    'sabbathColor': theme.color(
      style['sabbathColor'] ?? 'sabbath',
      theme.color('primary'),
    ),
    'eventColor': theme.color(style['eventColor'] ?? 'primary'),
    'numberFont': mini ? 'sans' : 'serif',
    'numberFamily': ?(mini
        ? null
        : family(fonts['numbers'] ?? fonts['display'])),
    'rows': 'auto',
    'rowHeight': 1.0,
  };

  CalendarStudioBlock _grid(
    Map<String, Object?> spec,
    CalendarStudioBlock Function(
      CalendarStudioBlockType,
      String, {
      Map<String, Object?> content,
      Map<String, Object?> style,
    })
    block,
  ) {
    final content =
        (spec['content'] as Map?)?.cast<String, Object?>() ?? const {};
    final mini = content['mini'] == true;
    return block(
      CalendarStudioBlockType.calendarGrid,
      'Calendar grid',
      content: {'mini': mini, 'calendarStyle': 'standard'},
      style: _gridStyle({
        ...?(spec['style'] as Map?)?.cast<String, Object?>(),
        'cellStyle': content['cellStyle'],
      }, mini: mini),
    );
  }

  /// One sheet with all twelve months as labelled mini grids.
  List<CalendarStudioBlock> _annual(Map<String, Object?> spec, int index) {
    final area = rect(spec['bounds']);
    final columns = spec['columns'] as int? ?? 3;
    final rows = (12 / columns).ceil();
    const gap = .03;
    final cellWidth = (area.width - gap * (columns - 1)) / columns;
    final cellHeight = (area.height - gap * (rows - 1)) / rows;
    final style = (spec['style'] as Map?)?.cast<String, Object?>() ?? const {};
    final labelColor = theme.color(style['labelColor'] ?? 'primary');
    return [
      for (var m = 0; m < 12; m++) ...[
        CalendarStudioBlock(
          id: 'month-label-$index-$m',
          type: CalendarStudioBlockType.text,
          name: '${_englishMonths[m]} title',
          bounds: StudioRect(
            left: area.left + (m % columns) * (cellWidth + gap),
            top: area.top + (m ~/ columns) * (cellHeight + gap),
            width: cellWidth,
            height: cellHeight * .2,
          ),
          zIndex: index,
          content: {
            'text': language.usesPackageText
                ? CalendarStudioBindings.resolve(
                    CalendarStudioBinding.monthTitle,
                    language: language,
                    year: year,
                    month: m + 1,
                  ).$1
                : language == CalendarStudioLanguage.english
                ? _englishMonths[m]
                : _myanmarMonths[m],
            if (language == CalendarStudioLanguage.both)
              'subtitle': _englishMonths[m],
          },
          style: {
            'color': labelColor,
            'fontSize': 13.0,
            'fontFamily': family(fonts['display']),
            'fontWeight': 600,
            'align': 'left',
            'subtitleScale': .62,
            'subtitleColor': theme.color('inkMuted'),
            'lineHeight': 1.4,
          },
        ),
        CalendarStudioBlock(
          id: 'month-grid-$index-$m',
          type: CalendarStudioBlockType.calendarGrid,
          name: '${_englishMonths[m]} grid',
          bounds: StudioRect(
            left: area.left + (m % columns) * (cellWidth + gap),
            top:
                area.top +
                (m ~/ columns) * (cellHeight + gap) +
                cellHeight * .22,
            width: cellWidth,
            height: cellHeight * .78,
          ),
          zIndex: index,
          content: {'mini': true, 'calendarStyle': 'standard', 'month': m + 1},
          style: _gridStyle(style, mini: true),
        ),
      ],
    ];
  }

  CalendarStudioBlock _legend(
    Map<String, Object?> spec,
    CalendarStudioBlock Function(
      CalendarStudioBlockType,
      String, {
      Map<String, Object?> content,
      Map<String, Object?> style,
    })
    block,
  ) {
    final style = (spec['style'] as Map?)?.cast<String, Object?>() ?? const {};
    final items =
        (spec['items'] as List?)?.cast<String>() ??
        [
          if (spec['publicHoliday'] != false) 'holiday',
          if (spec['fullMoon'] != false) 'fullMoon',
          if (spec['newMoon'] != false) 'newMoon',
          if (spec['sabbath'] != false) 'sabbath',
          if (spec['events'] != false) 'events',
        ];
    return block(
      CalendarStudioBlockType.holidayLegend,
      'Legend',
      content: {'kind': 'themed', 'items': items},
      style: {
        'inkColor': theme.color(style['color'] ?? 'inkMuted'),
        'mutedColor': theme.color('inkMuted'),
        'holidayColor': theme.color('holiday'),
        'sabbathColor': theme.color('sabbath', theme.color('primary')),
        'moonColor': theme.color('moon', theme.color('accent')),
        'eventColor': theme.color('primary'),
        'fontSize': math.max(
          ((style['fontSize'] as num?)?.toDouble() ?? 10) * scale,
          minReadable,
        ),
        'fontFamily': family(style['fontFamily']),
        'align': switch (style['align']) {
          'center' => 'center',
          'end' => 'right',
          _ => 'left',
        },
      },
    );
  }

  CalendarStudioBlock _list(
    Map<String, Object?> spec,
    CalendarStudioBlock Function(
      CalendarStudioBlockType,
      String, {
      Map<String, Object?> content,
      Map<String, Object?> style,
    })
    block,
  ) {
    final style = (spec['style'] as Map?)?.cast<String, Object?>() ?? const {};
    final notes = spec['kind'] == 'notes';
    return block(
      CalendarStudioBlockType.eventList,
      notes ? 'Notes' : 'Event list',
      content: {
        'title': spec['title'] as String? ?? (notes ? 'Notes' : 'This month'),
        if (notes) 'kind': 'notes',
        if (spec['placeholder'] case final List rows) 'placeholder': rows,
      },
      style: {
        'inkColor': theme.color(style['color'] ?? 'ink'),
        'titleColor': theme.color(
          style['titleColor'] ?? style['color'] ?? 'ink',
        ),
        'mutedColor': theme.color(style['mutedColor'] ?? 'inkMuted'),
        'lineColor': theme.color(style['lineColor'] ?? 'line'),
        'fontSize': math.max(
          ((style['fontSize'] as num?)?.toDouble() ?? 10) * scale,
          minReadable,
        ),
        'fontFamily': family(style['fontFamily']),
      },
    );
  }
}

const _motifNames = {
  'ringsLinked': 'Linked rings',
  'frame': 'Photo frame',
  'paperLantern': 'Paper lanterns',
  'halftoneBurst': 'Halftone burst',
  'leafSprig': 'Leaf sprig',
  'crescent': 'Crescent moon',
  'ghostWisp': 'Ghost',
  'horizonWave': 'Horizon wave',
  'diamondWeave': 'Diamond weave',
  'starField': 'Star field',
  'zodiacWheel': 'Zodiac wheel',
  'stupa': 'Stupa',
  'sunRays': 'Sun rays',
  'steamCurl': 'Steam',
  'compassStar': 'Compass star',
};

const _myanmarMonths = [
  'ဇန်နဝါရီ',
  'ဖေဖော်ဝါရီ',
  'မတ်',
  'ဧပြီ',
  'မေ',
  'ဇွန်',
  'ဇူလိုင်',
  'ဩဂုတ်',
  'စက်တင်ဘာ',
  'အောက်တိုဘာ',
  'နိုဝင်ဘာ',
  'ဒီဇင်ဘာ',
];

const _englishMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
