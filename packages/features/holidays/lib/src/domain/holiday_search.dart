import '../catalog/holiday_catalog.dart';
import 'holiday_year.dart';

/// Which holidays the Holidays page shows.
enum HolidayFilter {
  all,
  public,
  religious,
  cultural,
  anniversary;

  bool accepts(HolidayEntry e) => switch (this) {
    HolidayFilter.all => true,
    HolidayFilter.public => e.officeClosed,
    HolidayFilter.religious => e.kind == HolidayKind.religious,
    HolidayFilter.cultural => e.kind == HolidayKind.cultural,
    HolidayFilter.anniversary => e.kind == HolidayKind.anniversary,
  };
}

/// Search over holidays by any of their names: the localized title(s)
/// passed in, the library's names in English and the calendar language,
/// and the catalog's aliases.
abstract final class HolidaySearch {
  static String normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r"[\s'’]+"), ' ').trim();

  /// The text that matched [query], or null when [o] doesn't match.
  /// Titles are preferred, so a match on the name returns the title.
  static String? match(
    HolidayOccurrence o,
    String query, {
    List<String> titles = const [],
  }) {
    final q = normalize(query);
    if (q.isEmpty) return titles.isEmpty ? '' : titles.first;
    for (final t in [...titles, ...o.searchNames, ...o.entry.aliases]) {
      if (normalize(t).contains(q)) return t;
    }
    return null;
  }
}
