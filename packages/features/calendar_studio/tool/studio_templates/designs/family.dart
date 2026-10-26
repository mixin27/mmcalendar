import '../design.dart';
import '../page_builder.dart';
import 'common.dart';

const _a4 = StudioFormat.a4Portrait;

/// The A4 grid with a notes strip and legend under it.
void _wallGrid(
  PageBuilder page, {
  String gridLines = 'light',
  String numbers = 'Fraunces',
  String notesFamily = 'Noto Sans Myanmar',
  String notesTitle = 'Notes',
}) {
  page
    ..grid(
      [0.06, 0.47, 0.88, 0.38],
      gridLines: gridLines,
      numberFamily: numbers,
    )
    ..list(
      [0.06, 0.865, 0.88, 0.075],
      notesTitle,
      notes: true,
      family: notesFamily,
      size: 9,
    )
    ..legend([0.06, 0.952, 0.88, 0.022], size: 8);
}

/// Who each month's sample birthday row is for.
const _relatives = [
  'Grandma',
  'Dad',
  'Big sister',
  'Grandpa',
  'Mum',
  'Little brother',
  'Auntie',
  'Uncle',
  'Cousin',
  'Baby',
  'Grandma & Grandpa\'s anniversary',
  'Our family day',
];

/// Warm linen, a three-photo collage, leaf sprigs and a birthday list.
class FamilyAlbum extends StudioTemplateDesign {
  const FamilyAlbum();

  @override
  String get id => 'family-album';
  @override
  String get name => 'Family Album';
  @override
  String get topic => 'family';
  @override
  String get description =>
      'Warm linen and olive leaves: a three-photo collage, a family '
      'birthday list and a notes strip on every month.';
  @override
  StudioFormat get format => _a4;
  @override
  String get basePresetId => 'family';
  @override
  List<String> get moods => const ['Family', 'Warm', 'Calm'];
  @override
  StudioPalette get palette => const StudioPalette(
    paper: 0xFFF7F1E8,
    primary: 0xFF6B4F3A,
    accent: 0xFF8A9A5B,
    ink: 0xFF3A2E26,
    muted: 0xFF8C7F72,
    line: 0xFFE2D6C6,
    holiday: 0xFFB5543C,
    sabbath: 0xFF8A6A2F,
  );

  static const _captions = [
    'New year, all together',
    'Love lives here',
    'Spring cleaning & giggles',
    'Thingyan splashes',
    'Garden days',
    'Rainy-day games',
    'Summer stories',
    'Weekend picnics',
    'Back to school',
    'Lights at Thadingyut',
    'Tazaungdaing nights',
    'Home for the holidays',
  ];

  void _sprig(PageBuilder page, List<double> bounds, double rotation) =>
      page.motif(
        'leafSprig',
        'Leaves',
        bounds,
        color: palette.accent,
        accent: palette.accent,
        rotation: rotation,
      );

  @override
  void cover(PageBuilder page, DesignContext context) {
    page
      ..photo(
        'Photo · Family',
        [0.08, 0.06, 0.84, 0.36],
        context.photo(),
        border: 10,
        radius: 3,
        rotation: -1.5,
      )
      ..photo(
        'Photo',
        [0.1, 0.41, 0.38, 0.18],
        context.photo(),
        border: 8,
        radius: 3,
        rotation: 3,
      )
      ..photo(
        'Photo',
        [0.52, 0.42, 0.38, 0.18],
        context.photo(),
        border: 8,
        radius: 3,
        rotation: -2.5,
      );
    _sprig(page, [0.0, 0.6, 0.2, 0.08], -12);
    _sprig(page, [0.8, 0.02, 0.2, 0.08], 160);
    page
      ..text(
        'Title',
        [0.1, 0.66, 0.8, 0.09],
        'Our Family',
        family: 'Lora',
        size: 58,
        weight: 600,
        color: palette.primary,
        align: 'center',
      )
      ..text(
        'Subtitle',
        [0.1, 0.755, 0.8, 0.035],
        'a year of little moments',
        family: 'Lora',
        size: 18,
        italic: true,
        align: 'center',
      )
      ..text(
        'Myanmar line',
        [0.1, 0.795, 0.8, 0.03],
        'ကျွန်ုပ်တို့ မိသားစု',
        family: 'Noto Serif Myanmar',
        size: 15,
        weight: 400,
        color: palette.muted,
        align: 'center',
      )
      ..rule([0.42, 0.84, 0.16, 0.0015])
      ..yearText(
        [0.35, 0.855, 0.3, 0.03],
        align: 'center',
        size: 16,
        letterSpacing: 6,
      );
  }

  @override
  void month(PageBuilder page, int month, DesignContext context) {
    final caption = pick(context, month, _captions, 'Our family, this month');
    final rows = context.template
        ? const ['__ — ________', '__ — ________']
        : ['__ — ${_relatives[month - 1]}\'s birthday', '__ — ________'];
    if (month.isOdd) {
      page
        ..photo(
          'Photo',
          [0.07, 0.05, 0.52, 0.27],
          context.photo(),
          border: 8,
          radius: 3,
          rotation: -2,
        )
        ..photo(
          'Photo',
          [0.62, 0.055, 0.31, 0.135],
          context.photo(),
          border: 6,
          radius: 3,
          rotation: 3,
        )
        ..photo(
          'Photo',
          [0.62, 0.2, 0.31, 0.135],
          context.photo(),
          border: 6,
          radius: 3,
          rotation: -2,
        );
      _sprig(page, [0.0, 0.28, 0.16, 0.06], -10);
    } else {
      page.photo('Photo', [0.07, 0.05, 0.86, 0.27], context.photo(), radius: 6);
      _sprig(page, [0.8, 0.285, 0.16, 0.06], 165);
    }
    page
      ..monthTitle([0.07, 0.34, 0.55, 0.075], family: 'Lora', size: 38)
      ..text(
        'Caption',
        [0.07, 0.415, 0.55, 0.03],
        caption,
        family: 'Lora',
        size: 14,
        italic: true,
      )
      ..yearText([0.64, 0.335, 0.3, 0.02], size: 10, align: 'left')
      ..list(
        [0.64, 0.36, 0.3, 0.1],
        'Family birthdays',
        rows: rows,
        family: 'Lora',
        size: 9.5,
      );
    _wallGrid(page, numbers: 'Lora', notesFamily: 'Lora');
  }
}

/// Sunny yellow and teal: a little house drawn from shapes, with a photo in
/// the window, balloons, and a chores list. Fun for kids.
class LittleHome extends StudioTemplateDesign {
  const LittleHome();

  @override
  String get id => 'little-home';
  @override
  String get name => 'Little Home';
  @override
  String get topic => 'family';
  @override
  String get description =>
      'Sunny yellow and teal: a little house with a photo in the window, '
      'balloons, and a chores & celebrations list. Fun for kids.';
  @override
  StudioFormat get format => _a4;
  @override
  String get basePresetId => 'family';
  @override
  List<String> get moods => const ['Family', 'Playful', 'Bright'];

  static const _grass = 0xFF8CC084;
  static const _sun = 0xFFF4B942;

  @override
  StudioPalette get palette => const StudioPalette(
    paper: 0xFFFFF8E7,
    primary: 0xFF2A9D8F,
    accent: _sun,
    ink: 0xFF264653,
    muted: 0xFF7A8B8F,
    line: 0xFFF0E2BF,
    holiday: 0xFFE76F51,
    sabbath: 0xFF8D6A2B,
  );

  static const _captions = [
    'Hello, new year!',
    'Hugs for everyone',
    'Kites & sunshine',
    'Water fight time',
    'Ice cream days',
    'Puddle jumping',
    'Summer fun',
    'Our big adventure',
    'New school bags',
    'Paper lanterns',
    'Full-moon treats',
    'Cosy & together',
  ];

  static const _chores = [
    'Sun — Family movie night',
    'Sat — Clean our rooms',
    'Wed — Water the plants',
  ];

  /// A house: roof, chimney, walls and a photo for a window.
  void _house(
    PageBuilder page,
    DesignContext context,
    double left,
    double top,
    double width,
    double height,
  ) {
    page
      ..shape(
        'rectangle',
        [left + width * .7, top - height * .05, width * .1, height * .3],
        color: palette.holiday,
        name: 'Chimney',
      )
      ..shape(
        'triangle',
        [left - width * .06, top, width * 1.12, height * .45],
        color: palette.holiday,
        name: 'Roof',
      )
      ..shape(
        'rectangle',
        [left, top + height * .42, width, height * .58],
        color: palette.primary,
        name: 'House',
      )
      ..photo(
        'Photo',
        [left + width * .07, top + height * .48, width * .86, height * .46],
        context.photo(),
        radius: 8,
        border: 3,
        borderColor: palette.paper,
      )
      ..motif(
        'horizonWave',
        'Grass',
        [left - width * .12, top + height * .9, width * 1.24, height * .14],
        color: _grass,
        accent: _grass,
      );
  }

  void _balloons(PageBuilder page, double left, double top) {
    const colors = [0xFFE76F51, _sun, 0xFF2A9D8F];
    for (var i = 0; i < 3; i++) {
      final x = left + i * .06;
      final y = top + (i == 1 ? 0 : .02);
      page
        ..shape(
          'line',
          [x + .025, y + .05, 0.0015, .07],
          color: 0xFF9AA5A8,
          strokeWidth: 1,
          name: 'String',
        )
        ..squareShape('oval', _a4, x, y, .05, color: colors[i]);
    }
  }

  @override
  void cover(PageBuilder page, DesignContext context) {
    page.squareShape('circle', _a4, 0.78, 0.04, 0.14, color: _sun);
    _house(page, context, 0.14, 0.1, 0.72, 0.5);
    _balloons(page, 0.04, 0.05);
    page
      ..text(
        'Title',
        [0.08, 0.66, 0.84, 0.09],
        'Our Little Home',
        family: 'Bricolage Grotesque',
        size: 54,
        weight: 700,
        color: palette.primary,
        align: 'center',
      )
      ..text(
        'Subtitle',
        [0.1, 0.75, 0.8, 0.035],
        'chores, cheers & celebrations',
        family: 'Bricolage Grotesque',
        size: 17,
        align: 'center',
      )
      ..text(
        'Myanmar line',
        [0.1, 0.79, 0.8, 0.03],
        'ကျွန်ုပ်တို့ရဲ့ အိမ်လေး',
        size: 15,
        weight: 400,
        color: palette.muted,
        align: 'center',
      )
      ..yearText(
        [0.35, 0.845, 0.3, 0.035],
        family: 'Bricolage Grotesque',
        align: 'center',
        size: 20,
        color: palette.holiday,
        letterSpacing: 4,
      );
  }

  @override
  void month(PageBuilder page, int month, DesignContext context) {
    final caption = pick(context, month, _captions, 'Our month at home');
    final rows = context.template
        ? const ['__ — ________', '__ — ________']
        : [_chores[month % 3], '__ — ________', '__ — ________'];
    if (month.isOdd) {
      page.squareShape('circle', _a4, 0.36, 0.02, 0.08, color: _sun);
      _house(page, context, 0.08, 0.06, 0.34, 0.32);
    } else {
      page.photo(
        'Photo',
        [0.07, 0.07, 0.4, 0.3],
        context.photo(),
        radius: 24,
        border: 5,
        borderColor: palette.primary,
      );
      page
        ..squareShape('circle', _a4, 0.39, 0.035, 0.09, color: _sun)
        ..squareShape(
          'star',
          _a4,
          0.4,
          0.3,
          0.06,
          color: palette.holiday,
          rotation: -12,
        )
        ..squareShape(
          'star',
          _a4,
          0.03,
          0.04,
          0.05,
          color: palette.primary,
          rotation: 10,
        );
    }
    page
      ..monthTitle(
        [0.5, 0.08, 0.44, 0.08],
        family: 'Bricolage Grotesque',
        size: 36,
      )
      ..text(
        'Caption',
        [0.5, 0.165, 0.44, 0.03],
        caption,
        family: 'Bricolage Grotesque',
        size: 14,
        color: palette.holiday,
      )
      ..yearText(
        [0.5, 0.2, 0.2, 0.022],
        family: 'Bricolage Grotesque',
        size: 10,
      )
      ..list(
        [0.5, 0.24, 0.44, 0.17],
        'Chores & celebrations',
        rows: rows,
        family: 'Bricolage Grotesque',
        size: 10,
      );
    _wallGrid(
      page,
      gridLines: 'lined',
      numbers: 'Bricolage Grotesque',
      notesFamily: 'Bricolage Grotesque',
      notesTitle: 'Stickers & stars',
    );
  }
}
