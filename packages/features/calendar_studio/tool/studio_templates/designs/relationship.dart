import '../design.dart';
import '../page_builder.dart';
import 'common.dart';

const _square = StudioFormat.square;

/// Cream paper and kraft: photos framed like stamps, a red wax seal, and a
/// "Dear ___," line each month.
class LoveLetters extends StudioTemplateDesign {
  const LoveLetters();

  @override
  String get id => 'love-letters';
  @override
  String get name => 'Love Letters';
  @override
  String get topic => 'relationship';
  @override
  String get description =>
      'Cream paper and kraft, photos framed like postage stamps, a red wax '
      'seal and a "Dear ___," note to write each month.';
  @override
  StudioFormat get format => _square;
  @override
  String get basePresetId => 'love_relationship';
  @override
  List<String> get moods => const ['Love', 'Calm'];
  @override
  StudioPalette get palette => const StudioPalette(
    paper: 0xFFF6EFE3,
    primary: 0xFFA63A3A,
    accent: 0xFFB08A63,
    ink: 0xFF3B2A20,
    muted: 0xFF8C7B6B,
    line: 0xFFE3D6C3,
    holiday: 0xFFB5651D,
    sabbath: 0xFF6B4E2A,
  );

  static const _letters = [
    'Dear ___, a whole new year with you.',
    'Dear ___, will you be my Valentine?',
    'Dear ___, coffee tastes better with you.',
    'Dear ___, splash me this Thingyan.',
    'Dear ___, let\'s get lost somewhere.',
    'Dear ___, rain sounds better with you.',
    'Dear ___, you make every day sunny.',
    'Dear ___, one more road trip?',
    'Dear ___, I\'d still choose you.',
    'Dear ___, light the night with me.',
    'Dear ___, I made a wish on the full moon.',
    'Dear ___, home is wherever you are.',
  ];

  void _seal(PageBuilder page, double left, double top, double size) => page
    ..squareShape('circle', _square, left, top, size, color: palette.primary)
    ..squareShape(
      'heart',
      _square,
      left + size * .25,
      top + size * .27,
      size * .5,
      color: palette.paper,
    );

  @override
  void cover(PageBuilder page, DesignContext context) {
    page
      ..shape(
        'rectangle',
        [0.18, 0.06, 0.64, 0.54],
        color: palette.accent,
        outline: true,
        strokeWidth: 1,
        rotation: -2,
        name: 'Stamp edge',
      )
      ..photo(
        'Photo · Us',
        [0.2, 0.08, 0.6, 0.5],
        context.photo(),
        border: 9,
        radius: 2,
        rotation: -2,
      );
    _seal(page, 0.73, 0.5, 0.11);
    page
      ..text(
        'Title',
        [0.1, 0.62, 0.8, 0.12],
        'You & Me',
        family: 'Cormorant Garamond',
        size: 56,
        italic: true,
        color: palette.primary,
        align: 'center',
      )
      ..text(
        'Subtitle',
        [0.1, 0.745, 0.8, 0.045],
        'a year of love letters',
        family: 'Spectral',
        size: 16,
        italic: true,
        align: 'center',
      )
      ..text(
        'Myanmar line',
        [0.1, 0.8, 0.8, 0.045],
        'ချစ်ခြင်း စာလွှာများ',
        family: 'Noto Serif Myanmar',
        size: 13,
        weight: 400,
        color: palette.muted,
        align: 'center',
      )
      ..yearText([0.35, 0.88, 0.3, 0.04], align: 'center', size: 13);
  }

  @override
  void month(PageBuilder page, int month, DesignContext context) {
    final letter = pick(context, month, _letters, 'Dear ___,');
    if (month.isOdd) {
      page
        ..shape(
          'rectangle',
          [0.055, 0.055, 0.33, 0.37],
          color: palette.accent,
          outline: true,
          strokeWidth: 1,
          rotation: -3,
          name: 'Stamp edge',
        )
        ..photo(
          'Photo',
          [0.07, 0.07, 0.3, 0.34],
          context.photo(),
          border: 7,
          radius: 2,
          rotation: -3,
        )
        ..squareShape(
          'circle',
          _square,
          0.3,
          0.3,
          0.13,
          color: palette.accent,
          outline: true,
          strokeWidth: 1.2,
          rotation: -12,
        )
        ..yearText(
          [0.3, 0.345, 0.13, 0.04],
          align: 'center',
          size: 9,
          letterSpacing: 2,
          rotation: -12,
        );
      _seal(page, 0.85, 0.06, 0.1);
      page
        ..monthTitle([0.45, 0.07, 0.38, 0.15], size: 40)
        ..rule([0.45, 0.235, 0.25, 0.002])
        ..text(
          'Letter',
          [0.45, 0.25, 0.5, 0.05],
          letter,
          family: 'Spectral',
          size: 14,
          italic: true,
        )
        ..list(
          [0.45, 0.3, 0.49, 0.15],
          'Notes',
          notes: true,
          family: 'Spectral',
        );
    } else {
      page
        ..photo(
          'Photo',
          [0.06, 0.06, 0.58, 0.33],
          context.photo(),
          border: 6,
          radius: 2,
          rotation: 2,
        )
        ..shape(
          'rectangle',
          [0.72, 0.065, 0.16, 0.19],
          color: palette.accent,
          outline: true,
          strokeWidth: 1.2,
          name: 'Stamp',
        )
        ..squareShape(
          'heart',
          _square,
          0.755,
          0.11,
          0.09,
          color: palette.primary,
        )
        ..yearText([0.7, 0.265, 0.2, 0.035], align: 'center', size: 10)
        ..monthTitle([0.66, 0.3, 0.3, 0.12], size: 34)
        ..text(
          'Letter',
          [0.06, 0.405, 0.6, 0.045],
          letter,
          family: 'Spectral',
          size: 14,
          italic: true,
        );
      _seal(page, 0.565, 0.325, 0.075);
    }
    squareGrid(page, numbers: 'Cormorant Garamond');
  }
}

/// Light blue and mint: two round photos, floating hearts and soft dots.
class SweetPastel extends StudioTemplateDesign {
  const SweetPastel();

  @override
  String get id => 'sweet-pastel';
  @override
  String get name => 'Sweet Pastel';
  @override
  String get topic => 'relationship';
  @override
  String get description =>
      'Light blue and mint with a touch of pink: two round photos, floating '
      'hearts and soft dots. Playful and bright.';
  @override
  StudioFormat get format => _square;
  @override
  String get basePresetId => 'love_relationship';
  @override
  List<String> get moods => const ['Love', 'Playful', 'Bright'];

  static const _mint = 0xFF7CCB97;
  static const _pink = 0xFFF2A7B5;

  @override
  StudioPalette get palette => const StudioPalette(
    paper: 0xFFF4FAFD,
    primary: 0xFF4C9BD0,
    accent: _mint,
    ink: 0xFF2D4A5A,
    muted: 0xFF8AA3B0,
    line: 0xFFD6E9F2,
    holiday: 0xFFE07A8B,
    sabbath: 0xFFB08A3E,
  );

  static const _captions = [
    'New year, same us',
    'Be mine, always',
    'Sweet little moments',
    'Splashes & smiles',
    'Little adventures',
    'Cosy rainy days',
    'Sunshine & you',
    'Road trip!',
    'Still choosing you',
    'Festival of lights',
    'Full moon wishes',
    'Home is you',
  ];

  void _dots(PageBuilder page) => page
    ..squareShape(
      'circle',
      _square,
      0.02,
      0.03,
      0.12,
      color: _mint,
      opacity: .35,
    )
    ..squareShape(
      'circle',
      _square,
      0.4,
      0.3,
      0.08,
      color: palette.primary,
      opacity: .25,
    )
    ..squareShape(
      'circle',
      _square,
      0.48,
      0.04,
      0.05,
      color: _pink,
      opacity: .5,
    );

  @override
  void cover(PageBuilder page, DesignContext context) {
    _dots(page);
    page
      ..roundPhoto(
        'Photo · You',
        _square,
        0.08,
        0.08,
        0.42,
        context.photo(),
        ring: 6,
        ringColor: palette.primary,
      )
      ..roundPhoto(
        'Photo · Me',
        _square,
        0.48,
        0.17,
        0.42,
        context.photo(),
        ring: 6,
        ringColor: _mint,
      )
      ..squareShape(
        'heart',
        _square,
        0.44,
        0.08,
        0.08,
        color: _pink,
        rotation: -12,
      )
      ..text(
        'You',
        [0.06, 0.64, 0.36, 0.12],
        'You',
        family: 'Sora',
        size: 52,
        weight: 700,
        color: palette.primary,
        align: 'right',
      )
      ..text(
        '&',
        [0.42, 0.64, 0.16, 0.12],
        '&',
        family: 'Sora',
        size: 44,
        weight: 600,
        color: _pink,
        align: 'center',
      )
      ..text(
        'Me',
        [0.58, 0.64, 0.36, 0.12],
        'Me',
        family: 'Sora',
        size: 52,
        weight: 700,
        color: _mint,
        align: 'left',
      )
      ..text(
        'Subtitle',
        [0.1, 0.77, 0.8, 0.045],
        'our sweet little year',
        family: 'Sora',
        size: 15,
        align: 'center',
      )
      ..text(
        'Myanmar line',
        [0.1, 0.82, 0.8, 0.045],
        'ချစ်ခြင်းလေးတွေနဲ့ တစ်နှစ်',
        size: 13,
        weight: 400,
        color: palette.muted,
        align: 'center',
      )
      ..yearText(
        [0.35, 0.89, 0.3, 0.04],
        family: 'Sora',
        align: 'center',
        size: 13,
        color: palette.primary,
      );
  }

  @override
  void month(PageBuilder page, int month, DesignContext context) {
    final caption = pick(context, month, _captions, 'Our sweet little month');
    final rows = rowsFor(context, month, sharedDates, const ['__ — ________']);
    _dots(page);
    if (month % 2 == 1) {
      page
        ..roundPhoto(
          'Photo · You',
          _square,
          0.07,
          0.08,
          0.24,
          context.photo(),
          ring: 4,
          ringColor: palette.primary,
        )
        ..roundPhoto(
          'Photo · Me',
          _square,
          0.25,
          0.17,
          0.24,
          context.photo(),
          ring: 4,
          ringColor: _mint,
        )
        ..text(
          'You',
          [0.07, 0.325, 0.24, 0.035],
          'You',
          family: 'Sora',
          size: 12,
          weight: 600,
          color: palette.primary,
          align: 'center',
        )
        ..text(
          'Me',
          [0.25, 0.415, 0.24, 0.035],
          'Me',
          family: 'Sora',
          size: 12,
          weight: 600,
          color: _mint,
          align: 'center',
        )
        ..squareShape(
          'heart',
          _square,
          0.22,
          0.07,
          0.05,
          color: _pink,
          rotation: -10,
        )
        ..squareShape(
          'heart',
          _square,
          0.47,
          0.34,
          0.035,
          color: palette.primary,
          rotation: 12,
        );
    } else {
      page
        ..photo(
          'Photo',
          [0.06, 0.06, 0.5, 0.36],
          context.photo(),
          radius: 28,
          border: 5,
        )
        ..squareShape(
          'heart',
          _square,
          0.44,
          0.25,
          0.12,
          color: _mint,
          outline: true,
          strokeWidth: 3,
          rotation: 10,
        )
        ..squareShape(
          'heart',
          _square,
          0.03,
          0.03,
          0.05,
          color: _pink,
          rotation: -14,
        );
    }
    page
      ..monthTitle(
        [0.52, 0.07, 0.42, 0.15],
        family: 'Sora',
        size: 32,
        align: 'right',
      )
      ..text(
        'Caption',
        [0.52, 0.23, 0.42, 0.045],
        caption,
        family: 'Sora',
        size: 13,
        align: 'right',
      )
      ..yearText(
        [0.62, 0.28, 0.32, 0.03],
        family: 'Sora',
        align: 'right',
        size: 10,
        color: palette.primary,
      )
      ..list(
        [0.58, 0.315, 0.36, 0.14],
        'Our plans',
        rows: rows,
        family: 'Sora',
        size: 9.5,
      );
    squareGrid(page, numbers: 'Sora');
  }
}

/// Navy and gold: round "moon" photos, a crescent, and stars on every page.
class Moonlit extends StudioTemplateDesign {
  const Moonlit();

  @override
  String get id => 'moonlit';
  @override
  String get name => 'Moonlit';
  @override
  String get topic => 'relationship';
  @override
  String get description =>
      'Deep navy and gold: round "moon" photos with gold rings, a crescent '
      'and stars on every page. Dreamy and a bit dramatic.';
  @override
  StudioFormat get format => _square;
  @override
  String get basePresetId => 'astrology';
  @override
  List<String> get moods => const ['Love', 'Night', 'Dreamy'];

  static const _cream = 0xFFF4ECDF;
  static const _sky = 0xFF9FC4E8;

  @override
  StudioPalette get palette => const StudioPalette(
    paper: 0xFF1B2340,
    primary: 0xFFD9B26A,
    accent: _sky,
    ink: _cream,
    muted: 0xFF9AA3BF,
    line: 0xFF2F3A5E,
    holiday: 0xFFF2A27E,
    sabbath: 0xFFC9B37E,
  );

  static const _captions = [
    'A new year under the stars',
    'Be my Valentine',
    'Still my favourite hello',
    'Thingyan with you',
    'Moonlight walks',
    'Rainy nights, warm hands',
    'You make it glow',
    'Stargazing season',
    'Still choosing you',
    'Lights for us',
    'Full moon wishes',
    'Home is you',
  ];

  void _stars(PageBuilder page, int seed, {List<double>? avoid}) => page.motif(
    'starField',
    'Stars',
    [0, 0, 1, 1],
    color: palette.primary,
    accent: _cream,
    opacity: .55,
    seed: seed,
    avoid: avoid ?? const [0.03, 0.44, 0.94, 0.53],
  );

  @override
  void cover(PageBuilder page, DesignContext context) {
    _stars(page, 3, avoid: const [0.24, 0.06, 0.52, 0.52]);
    page
      ..motif(
        'crescent',
        'Crescent moon',
        [0.74, 0.05, 0.12, 0.12],
        color: palette.primary,
        rotation: -18,
      )
      ..roundPhoto(
        'Photo · Us',
        _square,
        0.25,
        0.07,
        0.5,
        context.photo(),
        ring: 4,
        ringColor: palette.primary,
      )
      ..squareShape(
        'heart',
        _square,
        0.69,
        0.47,
        0.06,
        color: _sky,
        rotation: 12,
      )
      ..text(
        'Title',
        [0.08, 0.6, 0.84, 0.13],
        'You & Me',
        family: 'Cormorant Garamond',
        size: 60,
        italic: true,
        color: _cream,
        align: 'center',
      )
      ..text(
        'Subtitle',
        [0.1, 0.735, 0.8, 0.05],
        'our year under the stars',
        family: 'Italiana',
        size: 18,
        color: palette.primary,
        align: 'center',
        letterSpacing: 1,
      )
      ..text(
        'Myanmar line',
        [0.1, 0.795, 0.8, 0.045],
        'ကြယ်တွေအောက်က တို့နှစ်ယောက်',
        family: 'Noto Serif Myanmar',
        size: 13,
        weight: 400,
        color: palette.muted,
        align: 'center',
      )
      ..motif(
        'compassStar',
        'Star',
        [0.475, 0.855, 0.05, 0.05],
        color: palette.primary,
        opacity: .9,
      )
      ..yearText(
        [0.35, 0.915, 0.3, 0.045],
        align: 'center',
        size: 14,
        color: palette.primary,
        letterSpacing: 7,
      );
  }

  @override
  void month(PageBuilder page, int month, DesignContext context) {
    final caption = pick(context, month, _captions, 'Under the same moon');
    final rows = rowsFor(context, month, sharedDates, const ['__ — ________']);
    _stars(page, 11 + month);
    switch (month % 3) {
      case 1:
        page
          ..roundPhoto(
            'Photo',
            _square,
            0.08,
            0.075,
            0.31,
            context.photo(),
            ringColor: palette.primary,
          )
          ..motif(
            'crescent',
            'Crescent moon',
            [0.03, 0.035, 0.1, 0.1],
            color: palette.primary,
            rotation: -20,
          )
          ..squareShape(
            'heart',
            _square,
            0.34,
            0.33,
            0.05,
            color: _sky,
            rotation: 14,
          );
      case 2:
        page
          ..roundPhoto(
            'Photo · You',
            _square,
            0.06,
            0.07,
            0.22,
            context.photo(),
            ringColor: palette.primary,
          )
          ..roundPhoto(
            'Photo · Me',
            _square,
            0.235,
            0.17,
            0.22,
            context.photo(),
            ringColor: _sky,
          )
          ..squareShape(
            'heart',
            _square,
            0.225,
            0.075,
            0.05,
            color: palette.primary,
            rotation: -10,
          )
          ..text(
            'You',
            [0.06, 0.3, 0.16, 0.04],
            'You',
            family: 'Italiana',
            size: 14,
            color: palette.primary,
            align: 'center',
          )
          ..text(
            'Me',
            [0.265, 0.4, 0.16, 0.04],
            'Me',
            family: 'Italiana',
            size: 14,
            color: _sky,
            align: 'center',
          );
      default:
        page
          ..photo(
            'Photo',
            [0.06, 0.05, 0.44, 0.38],
            context.photo(),
            radius: 18,
            border: 2,
            borderColor: palette.primary,
          )
          ..motif('compassStar', 'Star', [
            0.44,
            0.02,
            0.08,
            0.08,
          ], color: palette.primary);
    }
    page
      ..monthTitle(
        [0.54, 0.065, 0.4, 0.15],
        family: 'Cormorant Garamond',
        size: 42,
        color: _cream,
        align: 'right',
      )
      ..yearText(
        [0.64, 0.22, 0.3, 0.035],
        align: 'right',
        size: 11,
        color: palette.primary,
        letterSpacing: 5,
      )
      ..text(
        'Caption',
        [0.54, 0.26, 0.4, 0.045],
        caption,
        family: 'Cormorant Garamond',
        size: 16,
        italic: true,
        color: _sky,
        align: 'right',
      )
      ..list(
        [0.6, 0.315, 0.34, 0.14],
        'Our dates',
        rows: rows,
        family: 'Cormorant Garamond',
        size: 10,
        ink: _cream,
        titleColor: palette.primary,
      );
    squareGrid(page, weekend: _sky);
  }
}
