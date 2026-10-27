import '../design.dart';
import '../page_builder.dart';
import 'common.dart';

const _desk = StudioFormat.a4Landscape;

/// Quarter goals and reviews for the business designs.
const _goals = {
  1: ['Q1 kickoff', 'Goal — ________', 'Goal — ________'],
  3: ['Q1 review', 'Goal — ________'],
  4: ['Thingyan break', 'Q2 kickoff', 'Goal — ________'],
  6: ['Q2 review · mid-year', 'Goal — ________'],
  7: ['Q3 kickoff', 'Goal — ________'],
  9: ['Q3 review', 'Goal — ________'],
  10: ['Q4 kickoff', 'Goal — ________'],
  12: ['Year-end review', 'Plan next year'],
};
const _genericGoals = ['Goal — ________', 'Goal — ________', 'Goal — ________'];

/// White, navy and blue: a side panel with a logo, goals and notes.
class CleanCorporate extends StudioTemplateDesign {
  const CleanCorporate();

  @override
  String get id => 'clean-corporate';
  @override
  String get name => 'Clean Corporate';
  @override
  String get topic => 'business';
  @override
  String get description =>
      'White, navy and blue for the office desk: a side panel with your '
      'logo, monthly goals and notes, and a clean lined grid.';
  @override
  StudioFormat get format => _desk;
  @override
  String get basePresetId => 'minimalist';
  @override
  List<String> get moods => const ['Business', 'Minimal', 'Calm'];

  static const _navy = 0xFF1F3A5F;
  static const _mist = 0xFFEEF3FA;
  static const _blue = 0xFF2F80ED;

  @override
  StudioPalette get palette => const StudioPalette(
    paper: white,
    primary: _navy,
    accent: _blue,
    ink: 0xFF1E2A38,
    muted: 0xFF7A8699,
    line: 0xFFE3E8EF,
    holiday: 0xFFD64545,
    sabbath: 0xFF8A6A2F,
  );

  @override
  void cover(PageBuilder page, DesignContext context) {
    page
      ..shape('rectangle', [0, 0, 1, 1], color: _navy, name: 'Background')
      ..shape('rectangle', [0, 0.82, 1, 0.012], color: _blue, name: 'Stripe')
      ..logo([0.44, 0.13, 0.12, 0.17])
      ..text(
        'Company',
        [0.15, 0.37, 0.7, 0.1],
        'Company name',
        family: 'Sora',
        size: 44,
        weight: 600,
        color: white,
        align: 'center',
      )
      ..text(
        'Tagline',
        [0.2, 0.48, 0.6, 0.05],
        'Your tagline here',
        family: 'Sora',
        size: 16,
        color: 0xFFB8C4D6,
        align: 'center',
      )
      ..yearText(
        [0.35, 0.6, 0.3, 0.08],
        family: 'Sora',
        size: 40,
        align: 'center',
        color: _blue,
        letterSpacing: 8,
      )
      ..text(
        'Calendar',
        [0.35, 0.69, 0.3, 0.04],
        'Calendar · ပြက္ခဒိန်',
        family: 'Sora',
        size: 14,
        color: 0xFFB8C4D6,
        align: 'center',
      );
  }

  @override
  void month(PageBuilder page, int month, DesignContext context) {
    final dark = month.isOdd;
    final ink = dark ? white : _navy;
    final soft = dark ? 0xFFB8C4D6 : palette.muted;
    final rule = dark ? 0xFF35527A : 0xFFD3DDEA;
    final rows = rowsFor(
      context,
      month,
      _goals,
      _genericGoals,
      fallback: _genericGoals,
    );
    page
      ..shape(
        'rectangle',
        [0, 0, 0.3, 1],
        color: dark ? _navy : _mist,
        name: 'Panel',
      )
      ..logo([0.04, 0.06, 0.1, 0.14])
      ..text(
        'Company',
        [0.04, 0.215, 0.22, 0.04],
        'Company name',
        family: 'Sora',
        size: 14,
        weight: 600,
        color: ink,
      )
      ..text(
        'Tagline',
        [0.04, 0.255, 0.22, 0.03],
        'Your tagline here',
        family: 'Sora',
        size: 9,
        color: soft,
      )
      ..monthTitle(
        [0.04, 0.32, 0.22, 0.12],
        family: 'Sora',
        size: 32,
        color: ink,
      )
      ..yearText(
        [0.04, 0.445, 0.22, 0.03],
        family: 'Sora',
        size: 11,
        color: _blue,
      )
      ..list(
        [0.04, 0.51, 0.22, 0.2],
        'Goals',
        rows: rows,
        family: 'Sora',
        size: 9.5,
        ink: ink,
        titleColor: _blue,
        lineColor: rule,
      )
      ..list(
        [0.04, 0.74, 0.22, 0.2],
        'Notes',
        notes: true,
        family: 'Sora',
        size: 9.5,
        ink: ink,
        titleColor: _blue,
        lineColor: rule,
      )
      ..grid(
        [0.34, 0.07, 0.62, 0.82],
        gridLines: 'light',
        numberFamily: 'Space Grotesk',
        weekend: _blue,
        header: _navy,
      )
      ..legend([0.34, 0.925, 0.62, 0.035]);
  }
}

/// Charcoal and amber: a big month number, logo, key dates and deadlines.
class StudioBold extends StudioTemplateDesign {
  const StudioBold();

  @override
  String get id => 'studio-bold';
  @override
  String get name => 'Studio Bold';
  @override
  String get topic => 'business';
  @override
  String get description =>
      'Charcoal and amber for studios and shops: a big month number, your '
      'logo, key dates and deadlines, and a subtle diamond weave.';
  @override
  StudioFormat get format => _desk;
  @override
  String get basePresetId => 'minimalist';
  @override
  List<String> get moods => const ['Business', 'Bold', 'Night'];

  static const _amber = 0xFFF2A541;
  static const _cream = 0xFFF4F1EA;

  @override
  StudioPalette get palette => const StudioPalette(
    paper: 0xFF222428,
    primary: _amber,
    accent: _cream,
    ink: _cream,
    muted: 0xFF9A9DA3,
    line: 0xFF3A3D44,
    holiday: 0xFFE4572E,
    sabbath: 0xFFC9A15A,
  );

  @override
  void cover(PageBuilder page, DesignContext context) {
    page
      ..motif(
        'diamondWeave',
        'Weave',
        [0, 0.78, 1, 0.22],
        color: _amber,
        accent: _amber,
        opacity: .18,
      )
      ..yearText(
        [0.06, 0.08, 0.6, 0.4],
        family: 'Bricolage Grotesque',
        size: 190,
        color: _amber,
        letterSpacing: 0,
      )
      ..text(
        'Company',
        [0.06, 0.5, 0.6, 0.09],
        'Company name',
        family: 'Bricolage Grotesque',
        size: 44,
        weight: 700,
        color: _cream,
      )
      ..text(
        'Tagline',
        [0.06, 0.6, 0.6, 0.05],
        'Key dates · deadlines · notes',
        family: 'Bricolage Grotesque',
        size: 16,
        color: palette.muted,
      )
      ..logo([0.76, 0.12, 0.17, 0.24]);
  }

  @override
  void month(PageBuilder page, int month, DesignContext context) {
    // Panel on the left in odd months, on the right in even ones.
    final left = month.isOdd;
    final panel = left ? 0.04 : 0.68;
    final gridLeft = left ? 0.36 : 0.04;
    final keyDates = context.template
        ? const ['__ — ________', '__ — ________']
        : [...?_goals[month]?.take(1), '__ — Team meeting', '__ — Payday'];
    if (context.template) {
      page.monthTitle(
        [panel, 0.08, 0.28, 0.2],
        family: 'Bricolage Grotesque',
        size: 44,
        color: _amber,
      );
    } else {
      page
        ..text(
          'Number',
          [panel, 0.03, 0.28, 0.27],
          month.toString().padLeft(2, '0'),
          family: 'Bricolage Grotesque',
          size: 150,
          weight: 800,
          color: _amber,
        )
        ..monthTitle(
          [panel, 0.3, 0.28, 0.1],
          family: 'Bricolage Grotesque',
          size: 28,
          color: _cream,
        );
    }
    page
      ..yearText(
        [panel, 0.41, 0.2, 0.03],
        family: 'Bricolage Grotesque',
        size: 11,
        color: _amber,
      )
      ..logo([panel, 0.47, 0.07, 0.1])
      ..text(
        'Company',
        [panel + 0.085, 0.49, 0.195, 0.05],
        'Company name',
        family: 'Bricolage Grotesque',
        size: 13,
        weight: 600,
        color: _cream,
      )
      ..list(
        [panel, 0.6, 0.13, 0.28],
        'Key dates',
        rows: keyDates,
        family: 'Bricolage Grotesque',
        size: 9,
        titleColor: _amber,
      )
      ..list(
        [panel + 0.15, 0.6, 0.13, 0.28],
        'Deadlines',
        rows: const ['__ — ________'],
        family: 'Bricolage Grotesque',
        size: 9,
        titleColor: _amber,
      )
      ..motif(
        'diamondWeave',
        'Weave',
        [panel - 0.04, 0.92, 0.36, 0.08],
        color: _amber,
        accent: _amber,
        opacity: .2,
      )
      ..shape(
        'line',
        [left ? 0.335 : 0.665, 0.07, 0.0015, 0.85],
        color: palette.line,
        strokeWidth: 1,
        name: 'Divider',
      )
      ..grid(
        [gridLeft, 0.07, 0.6, 0.82],
        gridLines: 'lined',
        numberFamily: 'Bricolage Grotesque',
        weekend: _amber,
        header: _amber,
      )
      ..legend([gridLeft, 0.925, 0.6, 0.035]);
  }
}
