import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart' as mm;

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';
import '../models/calendar_studio_user_template.dart';
import 'calendar_studio_bindings.dart';
import 'calendar_studio_preset_builder.dart';
import 'calendar_studio_preset_specs.dart';

typedef CalendarStudioBlockBuilder =
    List<CalendarStudioBlock> Function(int year, int month);

class CalendarStudioTemplate {
  const CalendarStudioTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.canvas,
    required this.monthly,
    required this.create,
    this.collection,
    this.moods = const [],
    this.palette = const [],
    this.user,
  });
  final String id;
  final String name;
  final String category;
  final StudioCanvas canvas;
  final bool monthly;

  /// Preset collection, e.g. "Vol 1", for the gallery's "New" rail.
  final String? collection;

  /// Mood keywords for gallery chips and search.
  final List<String> moods;

  /// Swatches shown on the gallery card (paper, primary, accent, ink, holiday).
  final List<int> palette;

  /// The saved design, for templates the user made or imported.
  final CalendarStudioUserTemplate? user;
  final CalendarStudioProject Function({
    required String id,
    required CalendarStudioSource source,
    required DateTime now,
  })
  create;
}

/// The preset documents are direct translations of the layer coordinates,
/// typography and artwork declared in `calendar-studio-mockups.html`.
abstract final class CalendarStudioTemplates {
  static final all = <CalendarStudioTemplate>[
    _template(
      'blank',
      'Blank canvas',
      'Any size',
      const StudioCanvas(width: 210, height: 297),
      blocks: (_, _) => const [],
    ),
    _template(
      'jade-wall',
      'Jade wall',
      'Wall · A4 portrait',
      const StudioCanvas(width: 210, height: 297),
      blocks: _jadeBlocks,
    ),
    _template(
      'ledger-desk',
      'Ledger desk',
      'Desk · A4 landscape',
      const StudioCanvas(width: 297, height: 210),
      blocks: _ledgerBlocks,
    ),
    _template(
      'plain',
      'Plain planner',
      'Print · A4 portrait',
      const StudioCanvas(width: 210, height: 297),
      blocks: _plainBlocks,
    ),
    _template(
      'annual',
      'Year at a glance',
      'Annual · one sheet',
      const StudioCanvas(width: 210, height: 297),
      monthly: false,
      blocks: _annualBlocks,
    ),
    _template(
      'square',
      'Moonlight post',
      'Social · square',
      const StudioCanvas(width: 600, height: 600),
      blocks: _moonBlocks,
    ),
    _template(
      'story',
      'Lacquer story',
      'Story · 9:16',
      const StudioCanvas(width: 360, height: 640),
      blocks: _storyBlocks,
    ),
    // Round-2 presets (docs/calendar-studio-theme-presets*.html).
    for (final spec in calendarStudioPresetSpecs)
      CalendarStudioPresetBuilder.build(spec),
  ];

  static CalendarStudioTemplate byId(String id) =>
      all.firstWhere((template) => template.id == id, orElse: () => all.first);

  /// The built-in template with [id], or null (user templates are not here).
  static CalendarStudioTemplate? byIdOrNull(String id) {
    for (final template in all) {
      if (template.id == id) return template;
    }
    return null;
  }

  static CalendarStudioTemplate _template(
    String templateId,
    String name,
    String category,
    StudioCanvas canvas, {
    required CalendarStudioBlockBuilder blocks,
    bool monthly = true,
  }) => CalendarStudioTemplate(
    id: templateId,
    name: name,
    category: category,
    canvas: canvas,
    monthly: monthly,
    create: ({required id, required source, required now}) {
      final pageCount = monthly ? source.pageCount : 1;
      return CalendarStudioProject(
        id: id,
        name: '$name ${source.year}',
        templateId: templateId,
        source: source,
        createdAt: now,
        updatedAt: now,
        pages: List.generate(pageCount, (index) {
          final absoluteMonth = source.month - 1 + index;
          final year = source.year + absoluteMonth ~/ 12;
          final month = absoluteMonth % 12 + 1;
          return CalendarStudioPage(
            id: 'page-$index',
            label: _englishMonths[month - 1],
            year: year,
            month: month,
            canvas: canvas,
            blocks: blocks(year, month),
          );
        }),
      );
    },
  );

  static List<CalendarStudioBlock> _jadeBlocks(int year, int month) {
    const w = 595.0;
    const h = 842.0;
    return [
      _decoration('hero', 'Temple landscape', 0, 0, 595, 292, w, h, 'jadeHero'),
      _decoration(
        'logo',
        'Calendar seal',
        36,
        28,
        64,
        64,
        w,
        h,
        'jadeLogo',
        z: 1,
      ),
      _text(
        'month-mm',
        'Myanmar month',
        36,
        304,
        330,
        58,
        w,
        h,
        _myanmarMonths[month - 1],
        size: 44,
        weight: 700,
        z: 2,
      ),
      _text(
        'month-en',
        'English month',
        36,
        364,
        300,
        30,
        w,
        h,
        '${_englishMonths[month - 1]} $year',
        size: 19,
        family: 'Georgia',
        spacing: .4,
        z: 2,
      ),
      _text(
        'year-mm',
        'Myanmar numerals year',
        365,
        312,
        194,
        48,
        w,
        h,
        _myanmarNumber(year),
        size: 34,
        align: 'right',
        weight: 700,
        z: 2,
      ),
      _text(
        'era',
        'Myanmar era',
        330,
        366,
        229,
        28,
        w,
        h,
        CalendarStudioBindings.eraLine(year, month),
        binding: CalendarStudioBinding.eraLine,
        color: 0xFF0E6B5C,
        size: 10,
        align: 'right',
        z: 2,
      ),
      _grid('grid', 'Calendar grid', 36, 410, 523, 344, w, h, z: 3),
      _legend('legend', 'Holiday legend', 36, 766, 523, 40, w, h, z: 4),
    ];
  }

  static List<CalendarStudioBlock> _ledgerBlocks(int year, int month) {
    const w = 842.0;
    const h = 595.0;
    return [
      _shape('panel', 'Dark side panel', 0, 0, 262, 595, w, h, 0xFF151B19),
      _text(
        'month-number',
        'Month number',
        30,
        26,
        210,
        110,
        w,
        h,
        month.toString().padLeft(2, '0'),
        color: 0xFFD9A93A,
        size: 108,
        family: 'Georgia',
        weight: 600,
        z: 1,
      ),
      _text(
        'month-mm',
        'Myanmar month',
        30,
        142,
        210,
        54,
        w,
        h,
        _myanmarMonths[month - 1],
        color: 0xFFFFFFFF,
        size: 32,
        weight: 700,
        z: 1,
      ),
      _text(
        'month-en',
        'English month',
        30,
        202,
        210,
        25,
        w,
        h,
        '${_englishMonths[month - 1]} $year',
        color: 0xD9FFFFFF,
        size: 15,
        family: 'Georgia',
        spacing: .5,
        z: 1,
      ),
      _text(
        'era',
        'Myanmar era',
        30,
        233,
        210,
        30,
        w,
        h,
        CalendarStudioBindings.eraLine(year, month),
        binding: CalendarStudioBinding.eraLine,
        color: 0xFFD9A93A,
        size: 10,
        z: 1,
      ),
      _text(
        'notes-title',
        'Notes title',
        30,
        292,
        210,
        20,
        w,
        h,
        'မှတ်စု  Notes',
        color: 0xCCFFFFFF,
        size: 10,
        weight: 700,
        z: 1,
      ),
      _decoration(
        'notes',
        'Notes lines',
        30,
        318,
        210,
        156,
        w,
        h,
        'notesDark',
        z: 1,
      ),
      _text(
        'legend',
        'Legend',
        30,
        520,
        210,
        48,
        w,
        h,
        '● အများပြည်သူ ပိတ်ရက်  Public holiday\n● လပြည့်  Full moon',
        color: 0xCCFFFFFF,
        size: 9,
        z: 1,
      ),
      _grid(
        'grid',
        'Calendar grid',
        290,
        34,
        518,
        527,
        w,
        h,
        gridLines: 'full',
        calendarStyle: 'boxed',
        z: 2,
      ),
    ];
  }

  static List<CalendarStudioBlock> _plainBlocks(int year, int month) {
    const w = 595.0;
    const h = 842.0;
    return [
      _text(
        'month-mm',
        'Myanmar month and year',
        36,
        34,
        350,
        56,
        w,
        h,
        '${_myanmarMonths[month - 1]} ${_myanmarNumber(year)}',
        size: 36,
        weight: 700,
      ),
      _text(
        'month-en',
        'English month and year',
        390,
        52,
        169,
        30,
        w,
        h,
        '${_englishMonths[month - 1]} $year',
        size: 18,
        family: 'Georgia',
        align: 'right',
      ),
      _decoration(
        'header-rule',
        'Header rule',
        36,
        96,
        523,
        2,
        w,
        h,
        'inkRule',
      ),
      _grid(
        'grid',
        'Calendar grid',
        36,
        110,
        523,
        520,
        w,
        h,
        gridLines: 'full',
        holidayColor: 0xFF111111,
        calendarStyle: 'plain',
      ),
      _text(
        'notes-title',
        'Notes title',
        36,
        650,
        523,
        20,
        w,
        h,
        'မှတ်စု  Notes',
        size: 11,
        weight: 700,
      ),
      _decoration(
        'notes',
        'Notes lines',
        36,
        676,
        523,
        150,
        w,
        h,
        'notesLight',
      ),
    ];
  }

  static List<CalendarStudioBlock> _annualBlocks(int year, int _) {
    const w = 595.0;
    const h = 842.0;
    final blocks = <CalendarStudioBlock>[
      _text(
        'year-mm',
        'Myanmar numerals year',
        36,
        30,
        300,
        88,
        w,
        h,
        _myanmarNumber(year),
        color: 0xFF0E6B5C,
        size: 60,
        weight: 700,
      ),
      _text(
        'era',
        'Myanmar era range',
        36,
        116,
        350,
        25,
        w,
        h,
        'မြန်မာနှစ် ${_eraYears(year)}  Myanmar Era',
        size: 13,
        weight: 600,
      ),
      _text(
        'year-en',
        'English year',
        360,
        38,
        199,
        84,
        w,
        h,
        '$year',
        color: 0xFFD9A93A,
        size: 84,
        family: 'Georgia',
        align: 'right',
        weight: 600,
      ),
      _decoration('gold-rule', 'Gold rule', 36, 145, 523, 3, w, h, 'goldRule'),
    ];
    for (var month = 1; month <= 12; month++) {
      final column = (month - 1) % 3;
      final row = (month - 1) ~/ 3;
      final x = 36 + column * (162.3 + 18.4);
      final y = (158 + row * (152 + 14)).toDouble();
      blocks
        ..add(
          _text(
            'month-title-$month',
            '${_englishMonths[month - 1]} title',
            x,
            y,
            162,
            25,
            w,
            h,
            '${_myanmarMonths[month - 1]}   ${_englishMonths[month - 1]}',
            color: 0xFF0E6B5C,
            size: 10,
            weight: 700,
            z: 1,
          ),
        )
        ..add(
          _grid(
            'month-grid-$month',
            '${_englishMonths[month - 1]} grid',
            x,
            y + 30,
            162,
            118,
            w,
            h,
            month: month,
            mini: true,
            z: 1,
          ),
        );
    }
    return blocks;
  }

  static List<CalendarStudioBlock> _moonBlocks(int year, int month) {
    const w = 600.0;
    const h = 600.0;
    return [
      _decoration(
        'backdrop',
        'Night sky',
        0,
        0,
        600,
        600,
        w,
        h,
        'moonBackdrop',
      ),
      _text(
        'month-mm',
        'Myanmar month',
        40,
        34,
        390,
        92,
        w,
        h,
        _myanmarMonths[month - 1],
        color: 0xFFFFFFFF,
        size: 54,
        weight: 700,
        z: 1,
      ),
      _text(
        'month-en',
        'English month',
        40,
        126,
        390,
        34,
        w,
        h,
        '${_englishMonths[month - 1].toUpperCase()} $year',
        color: 0xD9FFFFFF,
        size: 17,
        family: 'Georgia',
        spacing: 2.4,
        z: 1,
      ),
      _grid(
        'grid',
        'Calendar grid',
        34,
        196,
        532,
        310,
        w,
        h,
        inkColor: 0xFFFFFFFF,
        secondaryColor: 0xCCFFFFFF,
        lineColor: 0x47FFFFFF,
        holidayColor: 0xFFF2857B,
        calendarStyle: 'moonlight',
        z: 2,
      ),
      _text(
        'moon-legend',
        'Moon phase legend',
        40,
        528,
        520,
        34,
        w,
        h,
        '● လပြည့် Full moon     ○ လကွယ် New moon     ဥပုသ် Sabbath',
        color: 0xEBFFFFFF,
        size: 11.5,
        align: 'center',
        z: 2,
      ),
    ];
  }

  static List<CalendarStudioBlock> _storyBlocks(int year, int month) {
    const w = 360.0;
    const h = 640.0;
    return [
      _decoration(
        'backdrop',
        'Lacquer backdrop',
        0,
        0,
        360,
        640,
        w,
        h,
        'lacquerBackdrop',
      ),
      _text(
        'year',
        'Year',
        28,
        44,
        304,
        28,
        w,
        h,
        _myanmarNumber(year),
        color: 0xE6FFFFFF,
        size: 16,
        z: 1,
      ),
      _text(
        'month-mm',
        'Myanmar month',
        28,
        72,
        304,
        92,
        w,
        h,
        _myanmarMonths[month - 1],
        color: 0xFFFFFFFF,
        size: 62,
        weight: 700,
        z: 1,
      ),
      _text(
        'month-en',
        'English month',
        28,
        164,
        304,
        30,
        w,
        h,
        _englishMonths[month - 1].toUpperCase(),
        color: 0xE6FFFFFF,
        size: 18,
        family: 'Georgia',
        spacing: 3.4,
        z: 1,
      ),
      _decoration(
        'events',
        'Featured dates',
        28,
        218,
        304,
        220,
        w,
        h,
        'storyEvents',
        z: 2,
      ),
      _grid(
        'mini-grid',
        'Mini calendar',
        28,
        470,
        304,
        136,
        w,
        h,
        mini: true,
        inkColor: 0xFFFFFFFF,
        secondaryColor: 0xD9FFFFFF,
        lineColor: 0x47FFFFFF,
        holidayColor: 0xFFF7D98A,
        z: 2,
      ),
    ];
  }

  static CalendarStudioBlock _text(
    String id,
    String name,
    double x,
    double y,
    double width,
    double height,
    double designWidth,
    double designHeight,
    String text, {
    int color = 0xFF15201D,
    double size = 20,
    String family = 'Noto Sans Myanmar',
    String align = 'left',
    int weight = 500,
    double spacing = 0,
    int z = 0,
    CalendarStudioBinding? binding,
  }) => CalendarStudioBlock(
    id: id,
    type: CalendarStudioBlockType.text,
    name: name,
    bounds: _rect(x, y, width, height, designWidth, designHeight),
    zIndex: z,
    content: {'text': text, CalendarStudioBindings.key: ?binding?.name},
    style: {
      'color': color,
      'fontSize': size,
      'fontFamily': family,
      'fontId': family == 'Noto Sans Myanmar'
          ? 'noto-sans-myanmar'
          : 'template-serif',
      'align': align,
      'fontWeight': weight,
      'letterSpacing': spacing,
    },
  );

  static CalendarStudioBlock _grid(
    String id,
    String name,
    double x,
    double y,
    double width,
    double height,
    double designWidth,
    double designHeight, {
    int? month,
    bool mini = false,
    String gridLines = 'light',
    int inkColor = 0xFF15201D,
    int secondaryColor = 0xB315201D,
    int lineColor = 0x2415201D,
    int holidayColor = 0xFFB8322A,
    String calendarStyle = 'standard',
    int z = 0,
  }) => CalendarStudioBlock(
    id: id,
    type: CalendarStudioBlockType.calendarGrid,
    name: name,
    bounds: _rect(x, y, width, height, designWidth, designHeight),
    zIndex: z,
    content: _gridContent(month, mini, calendarStyle),
    style: {
      'gridLines': gridLines,
      'inkColor': inkColor,
      'secondaryColor': secondaryColor,
      'lineColor': lineColor,
      'holidayColor': holidayColor,
      'numberFont': mini ? 'sans' : 'serif',
      'sabbathColor': 0xFF8A6210,
      'rowHeight': 1.0,
    },
  );

  static CalendarStudioBlock _shape(
    String id,
    String name,
    double x,
    double y,
    double width,
    double height,
    double designWidth,
    double designHeight,
    int color,
  ) => CalendarStudioBlock(
    id: id,
    type: CalendarStudioBlockType.shape,
    name: name,
    bounds: _rect(x, y, width, height, designWidth, designHeight),
    style: {'color': color},
  );

  static Map<String, Object?> _gridContent(
    int? month,
    bool mini,
    String calendarStyle,
  ) {
    final content = <String, Object?>{
      'mini': mini,
      'calendarStyle': calendarStyle,
    };
    if (month != null) content['month'] = month;
    return content;
  }

  static CalendarStudioBlock _decoration(
    String id,
    String name,
    double x,
    double y,
    double width,
    double height,
    double designWidth,
    double designHeight,
    String kind, {
    int z = 0,
  }) => CalendarStudioBlock(
    id: id,
    type: CalendarStudioBlockType.decoration,
    name: name,
    bounds: _rect(x, y, width, height, designWidth, designHeight),
    zIndex: z,
    content: {'kind': kind},
  );

  static CalendarStudioBlock _legend(
    String id,
    String name,
    double x,
    double y,
    double width,
    double height,
    double designWidth,
    double designHeight, {
    int z = 0,
  }) => CalendarStudioBlock(
    id: id,
    type: CalendarStudioBlockType.holidayLegend,
    name: name,
    bounds: _rect(x, y, width, height, designWidth, designHeight),
    zIndex: z,
    content: const {'kind': 'jadeLegend'},
  );

  static StudioRect _rect(
    double x,
    double y,
    double width,
    double height,
    double designWidth,
    double designHeight,
  ) => StudioRect(
    left: x / designWidth,
    top: y / designHeight,
    width: width / designWidth,
    height: height / designHeight,
  );

  static String _eraYears(int year) {
    final first = mm.MyanmarCalendar.getCompleteDate(DateTime(year, 1, 1));
    final last = mm.MyanmarCalendar.getCompleteDate(DateTime(year, 12, 31));
    return CalendarStudioBindings.eraYearsBetween(first.myanmar, last.myanmar);
  }

  static String _myanmarNumber(Object value) =>
      CalendarStudioBindings.myanmarNumber(value);

  static const _myanmarMonths = CalendarStudioBindings.myanmarMonths;
  static const _englishMonths = CalendarStudioBindings.englishMonths;
}
