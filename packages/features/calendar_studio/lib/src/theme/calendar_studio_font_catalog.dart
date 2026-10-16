import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// A font Calendar Studio bundles (SIL Open Font License).
class CalendarStudioFont {
  const CalendarStudioFont(
    this.id,
    this.family, {
    this.serif = true,
    this.variable = true,
    this.myanmar = false,
  });
  final String id;
  final String family;
  final bool serif;

  /// Weight comes from the `wght` axis instead of separate files.
  final bool variable;

  /// Has Myanmar glyphs; every other font is Latin-only and relies on the
  /// Myanmar fallback for Myanmar text.
  final bool myanmar;
}

/// Resolves block font names to the package's bundled families.
///
/// Templates store a plain family name (e.g. `Fraunces`) in block style; this
/// maps it to `packages/calendar_studio/Fraunces`, applies weight through the
/// variable axis, and picks a Myanmar fallback that matches the face (serif
/// display fonts fall back to Noto Serif Myanmar, sans to Noto Sans Myanmar).
abstract final class CalendarStudioFontCatalog {
  static const package = 'calendar_studio';

  static const fonts = [
    CalendarStudioFont(
      'noto-serif-myanmar',
      'Noto Serif Myanmar',
      variable: false,
      myanmar: true,
    ),
    CalendarStudioFont('cormorant-garamond', 'Cormorant Garamond'),
    CalendarStudioFont('fraunces', 'Fraunces'),
    CalendarStudioFont(
      'bricolage-grotesque',
      'Bricolage Grotesque',
      serif: false,
    ),
    CalendarStudioFont('space-grotesk', 'Space Grotesk', serif: false),
    CalendarStudioFont('spectral', 'Spectral', variable: false),
    CalendarStudioFont('libre-caslon-text', 'Libre Caslon Text'),
    CalendarStudioFont('lora', 'Lora'),
    CalendarStudioFont('sora', 'Sora', serif: false),
    CalendarStudioFont('italiana', 'Italiana', variable: false),
    CalendarStudioFont('newsreader', 'Newsreader'),
    CalendarStudioFont('crimson-pro', 'Crimson Pro'),
    CalendarStudioFont('petrona', 'Petrona'),
    CalendarStudioFont('bitter', 'Bitter'),
  ];

  /// Numerals in calendar grids, matching the Studio design system.
  static const numberFamily = 'Fraunces';

  static const serifMyanmar = 'packages/$package/Noto Serif Myanmar';

  /// Provided by the host app (bundled in apps/myanmar_calendar).
  static const sansMyanmar = 'Noto Sans Myanmar';

  static CalendarStudioFont? byFamily(String? family) {
    for (final font in fonts) {
      if (font.family == family) return font;
    }
    return null;
  }

  /// The family name Flutter needs: bundled fonts get the package prefix.
  static String? resolve(String? family) =>
      byFamily(family) == null ? family : 'packages/$package/$family';

  static List<String> fallbackFor(String? family) {
    final font = byFamily(family);
    return font == null || !font.serif
        ? const [sansMyanmar, serifMyanmar]
        : const [serifMyanmar, sansMyanmar];
  }

  /// Adds the bundled fonts' OFL licences to the app's licence page.
  static void registerLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final font in fonts) {
        final folder = font.family.toLowerCase().replaceAll(' ', '');
        final text = await rootBundle.loadString(
          'packages/$package/assets/fonts/$folder/OFL.txt',
        );
        yield LicenseEntryWithLineBreaks([
          'Calendar Studio · ${font.family}',
        ], text);
      }
    });
  }

  /// Font fields for a text style: family, Myanmar fallback, and weight on
  /// the variable axis when the face has one.
  static TextStyle style({
    String? family,
    FontWeight weight = FontWeight.w400,
    bool italic = false,
  }) {
    final font = byFamily(family);
    return TextStyle(
      fontFamily: resolve(family) ?? sansMyanmar,
      fontFamilyFallback: fallbackFor(family),
      fontWeight: weight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      fontVariations: font?.variable ?? false
          ? [FontVariation.weight(weight.value.toDouble())]
          : null,
    );
  }
}
