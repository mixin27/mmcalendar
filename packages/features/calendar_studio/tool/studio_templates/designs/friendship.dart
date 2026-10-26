import '../design.dart';
import '../page_builder.dart';
import 'common.dart';

const _square = StudioFormat.square;

/// Pop colours: tilted polaroids, star stickers and a halftone burst.
class GoodTimes extends StudioTemplateDesign {
  const GoodTimes();

  @override
  String get id => 'good-times';
  @override
  String get name => 'Good Times';
  @override
  String get topic => 'friendship';
  @override
  String get description =>
      'Coral, sunshine and teal: tilted polaroids, star stickers and a '
      'halftone burst, with a plans list for the crew.';
  @override
  StudioFormat get format => _square;
  @override
  String get basePresetId => 'anime';
  @override
  List<String> get moods => const ['Friends', 'Playful', 'Bold'];

  static const _sun = 0xFFFFC93C;
  static const _teal = 0xFF2EC4B6;

  @override
  StudioPalette get palette => const StudioPalette(
    paper: 0xFFFFF6EE,
    primary: 0xFFFF6B5B,
    accent: _sun,
    ink: 0xFF1F2A44,
    muted: 0xFF8A8FA3,
    line: 0xFFFFE1D2,
    holiday: 0xFFE84855,
    sabbath: 0xFFB07D2B,
  );

  static const _captions = [
    'New year, same crew',
    'Movie marathon',
    'Brunch club',
    'Thingyan water fights',
    'Road trip season',
    'Rainy-day game night',
    'Beach, please',
    'Karaoke night',
    'Birthday squad',
    'Lantern festival',
    'Full-moon picnic',
    'Year-end party',
  ];

  void _stars(PageBuilder page) => page
    ..squareShape('star', _square, 0.04, 0.37, 0.06, color: _sun, rotation: -12)
    ..squareShape('star', _square, 0.55, 0.05, 0.05, color: _teal, rotation: 10)
    ..squareShape(
      'star',
      _square,
      0.5,
      0.37,
      0.04,
      color: palette.primary,
      outline: true,
      strokeWidth: 2,
    );

  void _polaroids(
    PageBuilder page,
    DesignContext context,
    double scale,
    double left,
    double top,
  ) {
    const offsets = [(0.0, 0.04, -8.0), (0.16, 0.0, 4.0), (0.32, 0.06, -3.0)];
    for (final (dx, dy, turn) in offsets) {
      page.photo(
        'Photo',
        [left + dx * scale, top + dy * scale, .2 * scale, .24 * scale],
        context.photo(),
        border: 6 * scale,
        radius: 2,
        rotation: turn,
      );
    }
  }

  @override
  void cover(PageBuilder page, DesignContext context) {
    page.motif(
      'halftoneBurst',
      'Burst',
      [0.25, 0.0, 0.5, 0.5],
      color: palette.primary,
      accent: _sun,
      opacity: .3,
    );
    _polaroids(page, context, 1.6, 0.12, 0.08);
    page
      ..squareShape(
        'star',
        _square,
        0.08,
        0.05,
        0.08,
        color: _sun,
        rotation: -12,
      )
      ..squareShape(
        'star',
        _square,
        0.84,
        0.48,
        0.07,
        color: _teal,
        rotation: 14,
      )
      ..text(
        'Title',
        [0.06, 0.6, 0.88, 0.14],
        'Good Times',
        family: 'Space Grotesk',
        size: 64,
        weight: 700,
        align: 'center',
      )
      ..text(
        'Subtitle',
        [0.1, 0.745, 0.8, 0.045],
        'with my favourite people',
        family: 'Space Grotesk',
        size: 17,
        color: palette.primary,
        align: 'center',
      )
      ..text(
        'Myanmar line',
        [0.1, 0.8, 0.8, 0.045],
        'သူငယ်ချင်းတွေနဲ့ တစ်နှစ်',
        size: 13,
        weight: 400,
        color: palette.muted,
        align: 'center',
      )
      ..yearText(
        [0.35, 0.87, 0.3, 0.05],
        family: 'Space Grotesk',
        align: 'center',
        size: 18,
        color: _teal,
        letterSpacing: 6,
      );
  }

  @override
  void month(PageBuilder page, int month, DesignContext context) {
    final caption = pick(context, month, _captions, 'Good times only');
    final rows = rowsFor(
      context,
      month,
      const {
        4: ['Thingyan crew meet-up', '__ — ________'],
        9: ['__ — ________\'s birthday', '__ — ________'],
        12: ['31 — Countdown party', '__ — ________'],
      },
      const ['__ — ________', '__ — ________'],
      fallback: const ['__ — Group dinner', '__ — ________'],
    );
    if (month.isOdd) {
      page.motif(
        'halftoneBurst',
        'Burst',
        [0.0, 0.0, 0.55, 0.5],
        color: palette.primary,
        accent: _sun,
        opacity: .2,
      );
      _polaroids(page, context, 1, 0.05, 0.05);
    } else {
      page
        ..motif(
          'halftoneBurst',
          'Burst',
          [0.0, 0.0, 0.55, 0.5],
          color: _teal,
          accent: _sun,
          opacity: .2,
        )
        ..photo(
          'Photo',
          [0.06, 0.06, 0.44, 0.36],
          context.photo(),
          border: 8,
          radius: 2,
          rotation: -3,
        );
    }
    _stars(page);
    page
      ..monthTitle(
        [0.6, 0.07, 0.34, 0.14],
        family: 'Space Grotesk',
        size: 32,
        weight: 700,
        color: palette.ink,
        align: 'right',
      )
      ..text(
        'Caption',
        [0.6, 0.22, 0.34, 0.045],
        caption,
        family: 'Space Grotesk',
        size: 13,
        color: palette.primary,
        align: 'right',
      )
      ..yearText(
        [0.7, 0.27, 0.24, 0.03],
        family: 'Space Grotesk',
        align: 'right',
        size: 10,
        color: _teal,
      )
      ..list(
        [0.62, 0.31, 0.32, 0.14],
        'Plans',
        rows: rows,
        family: 'Space Grotesk',
        size: 9.5,
      );
    squareGrid(page, gridLines: 'light', numbers: 'Space Grotesk');
  }
}

/// Sky blue and sand: postcard photos, stamps, postmarks and a compass.
class Postcards extends StudioTemplateDesign {
  const Postcards();

  @override
  String get id => 'postcards';
  @override
  String get name => 'Postcards';
  @override
  String get topic => 'friendship';
  @override
  String get description =>
      'Sky blue and sand for friends who travel: postcard photos, stamps, '
      'a compass and a next-trip list.';
  @override
  StudioFormat get format => _square;
  @override
  String get basePresetId => 'ocean';
  @override
  List<String> get moods => const ['Friends', 'Travel', 'Calm'];
  @override
  StudioPalette get palette => const StudioPalette(
    paper: 0xFFF4EFE6,
    primary: 0xFF2F7FB5,
    accent: 0xFFE0A458,
    ink: 0xFF1F3A4D,
    muted: 0xFF7D8A92,
    line: 0xFFE3D8C6,
    holiday: 0xFFC8553D,
    sabbath: 0xFF8A6A2F,
  );

  static const _captions = [
    'Next stop: ___',
    'Weekend escape',
    'Mountain air',
    'Thingyan by the sea',
    'Temple trails',
    'Monsoon roads',
    'Island hopping',
    'City lights',
    'Sunrise over Bagan',
    'Inle Lake days',
    'Lantern nights',
    'Home for the holidays',
  ];

  void _stamp(PageBuilder page, double left, double top, double width) => page
    ..shape(
      'rectangle',
      [left, top, width, width * 1.15],
      color: palette.primary,
      outline: true,
      strokeWidth: 1.4,
      name: 'Stamp',
    )
    ..motif('compassStar', 'Compass', [
      left + width * .2,
      top + width * .2,
      width * .6,
      width * .7,
    ], color: palette.accent);

  void _postmark(PageBuilder page, double left, double top, double size) => page
    ..squareShape(
      'circle',
      _square,
      left,
      top,
      size,
      color: palette.muted,
      outline: true,
      strokeWidth: 1.2,
      rotation: -15,
    )
    ..yearText(
      [left, top + size * .36, size, size * .3],
      align: 'center',
      size: 9,
      color: palette.muted,
      letterSpacing: 2,
      rotation: -15,
    );

  @override
  void cover(PageBuilder page, DesignContext context) {
    page
      ..motif(
        'horizonWave',
        'Sea',
        [0.0, 0.5, 1.0, 0.12],
        color: palette.primary,
        accent: palette.primary,
        opacity: .18,
      )
      ..photo(
        'Photo',
        [0.08, 0.07, 0.66, 0.46],
        context.photo(),
        border: 9,
        radius: 2,
        rotation: -2,
      );
    _stamp(page, 0.77, 0.08, 0.16);
    _postmark(page, 0.7, 0.42, 0.16);
    page
      ..text(
        'Title',
        [0.06, 0.6, 0.88, 0.13],
        'Postcards from Us',
        family: 'Libre Caslon Text',
        size: 48,
        color: palette.primary,
        align: 'center',
      )
      ..text(
        'Subtitle',
        [0.1, 0.735, 0.8, 0.045],
        'a year of trips with friends',
        family: 'Libre Caslon Text',
        size: 15,
        italic: true,
        align: 'center',
      )
      ..text(
        'Myanmar line',
        [0.1, 0.79, 0.8, 0.045],
        'သူငယ်ချင်းတွေနဲ့ ခရီးများ',
        family: 'Noto Serif Myanmar',
        size: 13,
        weight: 400,
        color: palette.muted,
        align: 'center',
      )
      ..yearText(
        [0.35, 0.87, 0.3, 0.045],
        align: 'center',
        size: 16,
        letterSpacing: 6,
      );
  }

  @override
  void month(PageBuilder page, int month, DesignContext context) {
    final caption = pick(context, month, _captions, 'Next stop: ___');
    final rows = context.template
        ? const ['__ — ________']
        : [month == 4 ? 'Thingyan trip' : '__ — ________'];
    page.motif(
      'horizonWave',
      'Sea',
      [0.0, 0.36, 1.0, 0.07],
      color: palette.primary,
      accent: palette.primary,
      opacity: .16,
    );
    if (month.isOdd) {
      page.photo(
        'Photo',
        [0.06, 0.07, 0.5, 0.32],
        context.photo(),
        border: 7,
        radius: 2,
        rotation: -2,
      );
      _stamp(page, 0.64, 0.07, 0.15);
      _postmark(page, 0.78, 0.15, 0.12);
    } else {
      page
        ..roundPhoto(
          'Photo',
          _square,
          0.07,
          0.07,
          0.24,
          context.photo(),
          ring: 5,
          ringColor: palette.paper,
        )
        ..roundPhoto(
          'Photo',
          _square,
          0.33,
          0.15,
          0.22,
          context.photo(),
          ring: 5,
          ringColor: palette.paper,
        );
      for (var i = 0; i < 4; i++) {
        page.squareShape(
          'circle',
          _square,
          0.27 + i * 0.022,
          0.31 - i * 0.012,
          0.008,
          color: palette.accent,
        );
      }
      _stamp(page, 0.64, 0.07, 0.15);
      _postmark(page, 0.78, 0.15, 0.12);
    }
    page
      ..monthTitle(
        [0.62, 0.27, 0.32, 0.1],
        family: 'Libre Caslon Text',
        size: 30,
      )
      ..text(
        'Caption',
        [0.62, 0.37, 0.32, 0.035],
        caption,
        family: 'Libre Caslon Text',
        size: 12,
        italic: true,
      )
      ..list(
        [0.06, 0.4, 0.5, 0.065],
        'Next trip',
        rows: rows,
        family: 'Libre Caslon Text',
        size: 9,
      );
    squareGrid(page, numbers: 'Libre Caslon Text');
  }
}
