import 'package:shared_localizations/shared_localizations.dart';

import '../catalog/holiday_catalog.dart';
import 'holiday_guide_en.dart';
import 'holiday_guide_my.dart';

/// The parts of a holiday's "Good to know" section, in the order shown.
enum HolidayGuidePart { happens, practical, etiquette, where }

/// Visitor notes for each holiday: what happens, practical tips, etiquette
/// and where to see it. Sources are in docs/holiday-guide-sources.md.
///
/// The text lives in Dart maps, one per language, keyed by
/// [HolidayEntry.id] and then by [HolidayGuidePart.name]. A holiday has
/// only the parts that fit it, and Myanmar falls back to English part by
/// part, so a passage not yet translated is never missing.
abstract final class HolidayGuide {
  static const _byLanguage = {'en': holidayGuideEn, 'my': holidayGuideMy};

  /// [entry]'s parts in the app language, in [HolidayGuidePart] order;
  /// empty when it has none.
  static Map<HolidayGuidePart, String> of(
    HolidayEntry entry,
    AppLocalizations l10n,
  ) {
    final local = _byLanguage[l10n.localeName]?[entry.id] ?? const {};
    final english = holidayGuideEn[entry.id] ?? const {};
    return {
      for (final part in HolidayGuidePart.values)
        part: ?(local[part.name] ?? english[part.name]),
    };
  }
}

extension HolidayGuidePartText on HolidayGuidePart {
  String label(AppLocalizations l10n) => switch (this) {
    HolidayGuidePart.happens => l10n.holidayGuideHappens,
    HolidayGuidePart.practical => l10n.holidayGuidePractical,
    HolidayGuidePart.etiquette => l10n.holidayGuideEtiquette,
    HolidayGuidePart.where => l10n.holidayGuideWhere,
  };
}
