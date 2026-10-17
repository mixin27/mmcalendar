import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_motifs/shared_motifs.dart';

/// Nine base colours of a grid theme in one brightness. Every softer tone
/// (selected tint, holiday wash, rules) derives from these.
@immutable
class CalendarThemePalette {
  const CalendarThemePalette({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.accent,
    required this.onAccent,
    required this.holiday,
    required this.moon,
    required this.sabbath,
  });

  /// Behind the header, weekday row and grid.
  final Color paper;

  /// Raised cells (Tiles) and cards on the paper.
  final Color surface;
  final Color ink;
  final Color inkMuted;

  /// Today's disc, the selected tint and the header controls.
  final Color accent;
  final Color onAccent;
  final Color holiday;
  final Color moon;

  /// Sabbath labels; often the moon's gold, darker on light paper.
  final Color sabbath;
}

/// Where the motif sits in the header corner: square art, or a wide band
/// for art that repeats sideways (waves, weave, lanterns).
enum CalendarMotifShape { square, wide }

/// A grid theme: palettes for both brightnesses, the typeface for day
/// numbers and the month title, and a motif for the header corner.
@immutable
class CalendarThemeLook {
  const CalendarThemeLook({
    required this.light,
    required this.dark,
    required this.motif,
    required this.numberFamily,
    this.motifShape = CalendarMotifShape.square,
  });

  final CalendarThemePalette light;
  final CalendarThemePalette dark;

  /// A [MotifPainter] kind.
  final String motif;
  final CalendarMotifShape motifShape;

  /// A display family Calendar Studio bundles, resolved through
  /// [CalendarFontScope]. Myanmar text keeps Noto Sans Myanmar.
  final String numberFamily;

  CalendarThemePalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// The look for [theme], or null for the app's own colours.
  static CalendarThemeLook? forTheme(CalendarGridTheme theme) => _looks[theme];

  static const _looks = <CalendarGridTheme, CalendarThemeLook>{
    // Myanmar heritage
    CalendarGridTheme.pagoda: CalendarThemeLook(
      motif: 'stupa',
      numberFamily: 'Crimson Pro',
      light: CalendarThemePalette(
        paper: Color(0xFFF7F0DE),
        surface: Color(0xFFFFFAEE),
        ink: Color(0xFF2E1B12),
        inkMuted: Color(0xFF6E5640),
        accent: Color(0xFF6B1F23),
        onAccent: Color(0xFFFFF7E6),
        holiday: Color(0xFFB8322A),
        moon: Color(0xFFC9A227),
        sabbath: Color(0xFF8A6210),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF1E1610),
        surface: Color(0xFF2A2018),
        ink: Color(0xFFF3E8D2),
        inkMuted: Color(0xFFC2AE8E),
        accent: Color(0xFFE0B34A),
        onAccent: Color(0xFF2A1A08),
        holiday: Color(0xFFF07468),
        moon: Color(0xFFE8C25A),
        sabbath: Color(0xFFE8C25A),
      ),
    ),
    CalendarGridTheme.jade: CalendarThemeLook(
      motif: 'seal',
      numberFamily: 'Libre Caslon Text',
      light: CalendarThemePalette(
        paper: Color(0xFFF3F7F4),
        surface: Color(0xFFFFFFFF),
        ink: Color(0xFF10241F),
        inkMuted: Color(0xFF4E6660),
        accent: Color(0xFF0E6B5C),
        onAccent: Color(0xFFFFFFFF),
        holiday: Color(0xFFB23A3A),
        moon: Color(0xFFC99A2E),
        sabbath: Color(0xFF8A6A1A),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF0D1A17),
        surface: Color(0xFF15241F),
        ink: Color(0xFFE6F1EC),
        inkMuted: Color(0xFF9DB8AF),
        accent: Color(0xFF4FC2A6),
        onAccent: Color(0xFF04201A),
        holiday: Color(0xFFF07A72),
        moon: Color(0xFFE5C268),
        sabbath: Color(0xFFE5C268),
      ),
    ),
    CalendarGridTheme.lacquer: CalendarThemeLook(
      motif: 'diamondWeave',
      motifShape: CalendarMotifShape.wide,
      numberFamily: 'Fraunces',
      light: CalendarThemePalette(
        paper: Color(0xFFF4ECE4),
        surface: Color(0xFFFBF5EF),
        ink: Color(0xFF1F1311),
        inkMuted: Color(0xFF6A4F47),
        accent: Color(0xFF1F1311),
        onAccent: Color(0xFFF6E3C4),
        holiday: Color(0xFFA3221A),
        moon: Color(0xFFC08A1E),
        sabbath: Color(0xFF8E6413),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF140C0A),
        surface: Color(0xFF21130F),
        ink: Color(0xFFF2E3D0),
        inkMuted: Color(0xFFC1A58C),
        accent: Color(0xFFD9A440),
        onAccent: Color(0xFF1F1206),
        holiday: Color(0xFFEE6A55),
        moon: Color(0xFFE3B455),
        sabbath: Color(0xFFE3B455),
      ),
    ),
    CalendarGridTheme.thadingyut: CalendarThemeLook(
      motif: 'paperLantern',
      motifShape: CalendarMotifShape.wide,
      numberFamily: 'Bricolage Grotesque',
      light: CalendarThemePalette(
        paper: Color(0xFFFBF3E2),
        surface: Color(0xFFFFF9EE),
        ink: Color(0xFF2A1A10),
        inkMuted: Color(0xFF6F5643),
        accent: Color(0xFFB04812),
        onAccent: Color(0xFFFFF6EC),
        holiday: Color(0xFFA4243B),
        moon: Color(0xFFD99A1E),
        sabbath: Color(0xFF9A6510),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF12142A),
        surface: Color(0xFF1C1F3A),
        ink: Color(0xFFF6EBD8),
        inkMuted: Color(0xFFB9B2C9),
        accent: Color(0xFFF2A54A),
        onAccent: Color(0xFF2A1505),
        holiday: Color(0xFFFF7A6E),
        moon: Color(0xFFF6C760),
        sabbath: Color(0xFFF6C760),
      ),
    ),
    CalendarGridTheme.thingyan: CalendarThemeLook(
      motif: 'padauk',
      numberFamily: 'Bitter',
      light: CalendarThemePalette(
        paper: Color(0xFFEEF6FA),
        surface: Color(0xFFFFFFFF),
        ink: Color(0xFF0F2A3A),
        inkMuted: Color(0xFF4D6878),
        accent: Color(0xFF0B6FA4),
        onAccent: Color(0xFFFFFFFF),
        holiday: Color(0xFFC2412D),
        moon: Color(0xFFE0A800),
        sabbath: Color(0xFF8F6700),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF0A1A24),
        surface: Color(0xFF112634),
        ink: Color(0xFFE4F2F9),
        inkMuted: Color(0xFF95B3C3),
        accent: Color(0xFF5EC1F0),
        onAccent: Color(0xFF04202E),
        holiday: Color(0xFFFF7F6A),
        moon: Color(0xFFFFD042),
        sabbath: Color(0xFFFFD042),
      ),
    ),
    // Nature and seasons
    CalendarGridTheme.botanical: CalendarThemeLook(
      motif: 'leafSprig',
      numberFamily: 'Spectral',
      light: CalendarThemePalette(
        paper: Color(0xFFF4F1E8),
        surface: Color(0xFFFBF9F2),
        ink: Color(0xFF2B2A22),
        inkMuted: Color(0xFF66644F),
        accent: Color(0xFF3F5E3A),
        onAccent: Color(0xFFFFFFFF),
        holiday: Color(0xFFA1453F),
        moon: Color(0xFFB58A2E),
        sabbath: Color(0xFF866420),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF141712),
        surface: Color(0xFF1D211A),
        ink: Color(0xFFE9EADF),
        inkMuted: Color(0xFFA9AC98),
        accent: Color(0xFF9CC48F),
        onAccent: Color(0xFF15210F),
        holiday: Color(0xFFE58A7E),
        moon: Color(0xFFDDB65E),
        sabbath: Color(0xFFDDB65E),
      ),
    ),
    CalendarGridTheme.monsoon: CalendarThemeLook(
      motif: 'rain',
      numberFamily: 'Newsreader',
      light: CalendarThemePalette(
        paper: Color(0xFFEDF1F3),
        surface: Color(0xFFFFFFFF),
        ink: Color(0xFF26343F),
        inkMuted: Color(0xFF5E6E7A),
        accent: Color(0xFF46586B),
        onAccent: Color(0xFFFFFFFF),
        holiday: Color(0xFFB5482F),
        moon: Color(0xFFD98B3F),
        sabbath: Color(0xFF9A5A22),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF12181D),
        surface: Color(0xFF1B232A),
        ink: Color(0xFFE3E9ED),
        inkMuted: Color(0xFF9AA8B3),
        accent: Color(0xFF9DB4CC),
        onAccent: Color(0xFF0F1A24),
        holiday: Color(0xFFF0876E),
        moon: Color(0xFFF0A65E),
        sabbath: Color(0xFFF0A65E),
      ),
    ),
    CalendarGridTheme.tidewater: CalendarThemeLook(
      motif: 'horizonWave',
      motifShape: CalendarMotifShape.wide,
      numberFamily: 'Lora',
      light: CalendarThemePalette(
        paper: Color(0xFFEAF4F4),
        surface: Color(0xFFFFFFFF),
        ink: Color(0xFF0E2A33),
        inkMuted: Color(0xFF4C6870),
        accent: Color(0xFF1A716C),
        onAccent: Color(0xFFFFFFFF),
        holiday: Color(0xFFC1572E),
        moon: Color(0xFFD49A2A),
        sabbath: Color(0xFF8E6414),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF071D24),
        surface: Color(0xFF0E2A33),
        ink: Color(0xFFE2F2F1),
        inkMuted: Color(0xFF94B7B8),
        accent: Color(0xFF5CC9C0),
        onAccent: Color(0xFF032421),
        holiday: Color(0xFFFF8A62),
        moon: Color(0xFFF2C25C),
        sabbath: Color(0xFFF2C25C),
      ),
    ),
    CalendarGridTheme.morningPour: CalendarThemeLook(
      motif: 'steamCurl',
      numberFamily: 'Petrona',
      light: CalendarThemePalette(
        paper: Color(0xFFF5EDE1),
        surface: Color(0xFFFBF6EE),
        ink: Color(0xFF2E1D16),
        inkMuted: Color(0xFF6E574A),
        accent: Color(0xFF5C3D2E),
        onAccent: Color(0xFFFBF1E6),
        holiday: Color(0xFFA8402F),
        moon: Color(0xFFC08552),
        sabbath: Color(0xFF8A5530),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF19120E),
        surface: Color(0xFF241A15),
        ink: Color(0xFFF1E4D6),
        inkMuted: Color(0xFFBFA894),
        accent: Color(0xFFD9A47A),
        onAccent: Color(0xFF2A1810),
        holiday: Color(0xFFEE7B66),
        moon: Color(0xFFE3B07E),
        sabbath: Color(0xFFE3B07E),
      ),
    ),
    // Night and sky
    CalendarGridTheme.deepField: CalendarThemeLook(
      motif: 'starField',
      motifShape: CalendarMotifShape.wide,
      numberFamily: 'Space Grotesk',
      light: CalendarThemePalette(
        paper: Color(0xFFECEBF5),
        surface: Color(0xFFF8F7FC),
        ink: Color(0xFF1B1C3A),
        inkMuted: Color(0xFF575A7C),
        accent: Color(0xFF5B47A0),
        onAccent: Color(0xFFFFFFFF),
        holiday: Color(0xFFC8434E),
        moon: Color(0xFFC99A2E),
        sabbath: Color(0xFF8C6A1C),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF0A0E27),
        surface: Color(0xFF141938),
        ink: Color(0xFFF2F4FA),
        inkMuted: Color(0xFFA9AEC9),
        accent: Color(0xFFA994E0),
        onAccent: Color(0xFF120C2A),
        holiday: Color(0xFFFF8A7A),
        moon: Color(0xFFF4D27A),
        sabbath: Color(0xFFF4D27A),
      ),
    ),
    CalendarGridTheme.moonlight: CalendarThemeLook(
      motif: 'crescent',
      numberFamily: 'Cormorant Garamond',
      light: CalendarThemePalette(
        paper: Color(0xFFF1F3F8),
        surface: Color(0xFFFFFFFF),
        ink: Color(0xFF1A1E2C),
        inkMuted: Color(0xFF565D73),
        accent: Color(0xFF35466F),
        onAccent: Color(0xFFFFFFFF),
        holiday: Color(0xFFC0453A),
        moon: Color(0xFFD8A62A),
        sabbath: Color(0xFF8E6A12),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF0E1220),
        surface: Color(0xFF171C2E),
        ink: Color(0xFFEEF1F8),
        inkMuted: Color(0xFFA3ABC2),
        accent: Color(0xFFB9C7EA),
        onAccent: Color(0xFF121A30),
        holiday: Color(0xFFFF8475),
        moon: Color(0xFFF5D88A),
        sabbath: Color(0xFFF5D88A),
      ),
    ),
    CalendarGridTheme.nightChart: CalendarThemeLook(
      motif: 'zodiacWheel',
      numberFamily: 'Sora',
      light: CalendarThemePalette(
        paper: Color(0xFFF3EFE6),
        surface: Color(0xFFFBF8F1),
        ink: Color(0xFF241B3D),
        inkMuted: Color(0xFF62577A),
        accent: Color(0xFF5A3F8C),
        onAccent: Color(0xFFFFFFFF),
        holiday: Color(0xFFB8433C),
        moon: Color(0xFFB88E3A),
        sabbath: Color(0xFF86621E),
      ),
      dark: CalendarThemePalette(
        paper: Color(0xFF1A1430),
        surface: Color(0xFF241B3D),
        ink: Color(0xFFEDE6D6),
        inkMuted: Color(0xFFB3A8C6),
        accent: Color(0xFFD4AF6A),
        onAccent: Color(0xFF241B3D),
        holiday: Color(0xFFF08A7A),
        moon: Color(0xFFD4AF6A),
        sabbath: Color(0xFFD4AF6A),
      ),
    ),
  };
}

/// Hands the chosen grid theme to the header, weekday row and cells below.
/// Without a scope (or with [CalendarGridTheme.app]) they use app colours.
class CalendarThemeScope extends InheritedWidget {
  const CalendarThemeScope({
    super.key,
    required this.theme,
    this.showMotif = true,
    required super.child,
  });

  final CalendarGridTheme theme;
  final bool showMotif;

  static CalendarThemeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CalendarThemeScope>();

  /// The active look, or null for the app's colours.
  static CalendarThemeLook? lookOf(BuildContext context) {
    final scope = maybeOf(context);
    return scope == null ? null : CalendarThemeLook.forTheme(scope.theme);
  }

  @override
  bool updateShouldNotify(CalendarThemeScope oldWidget) =>
      theme != oldWidget.theme || showMotif != oldWidget.showMotif;
}

/// Re-themes Material colours below it with the active grid theme, so
/// widgets that read the colour scheme (the Classic cell, icon buttons, the
/// weekday row) follow the theme too. Passes [child] through for app colours.
class CalendarThemedRegion extends StatelessWidget {
  const CalendarThemedRegion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final look = CalendarThemeScope.lookOf(context);
    if (look == null) return child;
    final theme = Theme.of(context);
    final p = look.of(theme.brightness);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: p.accent,
          onPrimary: p.onAccent,
          primaryContainer: Color.alphaBlend(
            p.accent.withValues(alpha: .16),
            p.paper,
          ),
          onPrimaryContainer: p.ink,
          secondary: p.moon,
          surface: p.paper,
          onSurface: p.ink,
          onSurfaceVariant: p.inkMuted,
          outlineVariant: p.ink.withValues(alpha: .2),
        ),
      ),
      child: child,
    );
  }
}

/// The active theme's motif, faint, for a header corner. Paints nothing for
/// app colours or when the motif is switched off.
class CalendarThemeMotif extends StatelessWidget {
  const CalendarThemeMotif({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = CalendarThemeScope.maybeOf(context);
    final look = CalendarThemeScope.lookOf(context);
    if (scope == null || look == null || !scope.showMotif) {
      return const SizedBox.shrink();
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = look.of(Theme.of(context).brightness);
    final alpha = dark ? .13 : .1;
    final size = switch (look.motifShape) {
      CalendarMotifShape.square => const Size(84, 84),
      CalendarMotifShape.wide => const Size(140, 50),
    };
    return ExcludeSemantics(
      child: IgnorePointer(
        child: CustomPaint(
          size: size,
          painter: MotifPainter(
            look.motif,
            color: palette.accent.withValues(alpha: alpha),
            accent: palette.moon.withValues(alpha: alpha * 1.3),
          ),
        ),
      ),
    );
  }
}
