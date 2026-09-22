import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';

class CalendarStudioTemplate {
  const CalendarStudioTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.canvas,
    required this.monthly,
    required this.create,
  });
  final String id;
  final String name;
  final String category;
  final StudioCanvas canvas;
  final bool monthly;
  final CalendarStudioProject Function({
    required String id,
    required CalendarStudioSource source,
    required DateTime now,
  })
  create;
}

abstract final class CalendarStudioTemplates {
  static final all = <CalendarStudioTemplate>[
    _template(
      'blank',
      'Blank canvas',
      'Any size',
      const StudioCanvas(width: 210, height: 297),
      blocks: const [],
    ),
    _template(
      'jade-wall',
      'Jade wall',
      'Wall · A4 portrait',
      const StudioCanvas(width: 210, height: 297),
      blocks: _wallBlocks,
    ),
    _template(
      'ledger-desk',
      'Ledger desk',
      'Desk · A4 landscape',
      const StudioCanvas(width: 297, height: 210),
      blocks: _deskBlocks,
    ),
    _template(
      'annual',
      'Year at a glance',
      'Year · A3 landscape',
      const StudioCanvas(width: 420, height: 297),
      blocks: _annualBlocks,
    ),
    _template(
      'square',
      'Full moon post',
      'Social · Square',
      const StudioCanvas(width: 1080, height: 1080),
      blocks: _wallBlocks,
    ),
    _template(
      'story',
      'Festival story',
      'Social · Story',
      const StudioCanvas(width: 1080, height: 1920),
      blocks: _wallBlocks,
    ),
  ];
  static CalendarStudioTemplate byId(String id) =>
      all.firstWhere((template) => template.id == id, orElse: () => all.first);
  static CalendarStudioTemplate _template(
    String templateId,
    String name,
    String category,
    StudioCanvas canvas, {
    required List<CalendarStudioBlock> blocks,
  }) => CalendarStudioTemplate(
    id: templateId,
    name: name,
    category: category,
    canvas: canvas,
    monthly: true,
    create: ({required id, required source, required now}) =>
        CalendarStudioProject(
          id: id,
          name: '$name ${source.year}',
          templateId: templateId,
          source: source,
          createdAt: now,
          updatedAt: now,
          pages: List.generate(
            source.pageCount,
            (index) => CalendarStudioPage(
              id: 'page-$index',
              label: _monthName(source.month + index),
              year: source.year + ((source.month - 1 + index) ~/ 12),
              month: ((source.month - 1 + index) % 12) + 1,
              canvas: canvas,
              blocks: blocks,
            ),
          ),
        ),
  );
  static String _monthName(int month) => const [
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
  ][(month - 1) % 12];
  static const _wallBlocks = [
    CalendarStudioBlock(
      id: 'hero',
      type: CalendarStudioBlockType.shape,
      name: 'Header',
      bounds: StudioRect(left: 0, top: 0, width: 1, height: .34),
      zIndex: 0,
      style: {'color': 0xFF0E6B5C},
    ),
    CalendarStudioBlock(
      id: 'title',
      type: CalendarStudioBlockType.text,
      name: 'Title',
      bounds: StudioRect(left: .08, top: .08, width: .84, height: .13),
      zIndex: 1,
      content: {'text': 'Myanmar Calendar'},
      style: {
        'color': 0xFFFFFFFF,
        'fontSize': 28.0,
        'align': 'center',
        'fontId': 'noto-sans-myanmar',
        'fontFamily': 'Noto Sans Myanmar',
      },
    ),
    CalendarStudioBlock(
      id: 'grid',
      type: CalendarStudioBlockType.calendarGrid,
      name: 'Calendar grid',
      bounds: StudioRect(left: .08, top: .42, width: .84, height: .48),
      zIndex: 2,
    ),
  ];
  static const _deskBlocks = [
    CalendarStudioBlock(
      id: 'title',
      type: CalendarStudioBlockType.text,
      name: 'Title',
      bounds: StudioRect(left: .08, top: .08, width: .38, height: .14),
      content: {'text': 'Myanmar Calendar'},
      style: {
        'fontSize': 24.0,
        'fontId': 'noto-sans-myanmar',
        'fontFamily': 'Noto Sans Myanmar',
      },
    ),
    CalendarStudioBlock(
      id: 'grid',
      type: CalendarStudioBlockType.calendarGrid,
      name: 'Calendar grid',
      bounds: StudioRect(left: .48, top: .08, width: .44, height: .82),
    ),
  ];
  static const _annualBlocks = [
    CalendarStudioBlock(
      id: 'title',
      type: CalendarStudioBlockType.text,
      name: 'Title',
      bounds: StudioRect(left: .08, top: .04, width: .84, height: .08),
      content: {'text': 'Myanmar Calendar'},
      style: {
        'fontSize': 25.0,
        'align': 'center',
        'fontId': 'noto-sans-myanmar',
        'fontFamily': 'Noto Sans Myanmar',
      },
    ),
    CalendarStudioBlock(
      id: 'grid',
      type: CalendarStudioBlockType.calendarGrid,
      name: 'Year grid',
      bounds: StudioRect(left: .06, top: .16, width: .88, height: .76),
    ),
  ];
}
