import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// How a date in a search was written.
enum DateQueryKind { western, myanmar, relative }

/// A day a search query names.
class DateQueryMatch {
  const DateQueryMatch(this.date, this.kind);

  /// The day, at midnight.
  final DateTime date;
  final DateQueryKind kind;

  @override
  bool operator ==(Object other) =>
      other is DateQueryMatch && other.date == date && other.kind == kind;

  @override
  int get hashCode => Object.hash(date, kind);

  @override
  String toString() => 'DateQueryMatch($date, ${kind.name})';
}

/// Reads a day out of what someone types into search, in English or
/// Myanmar, with Western or Myanmar digits:
///
/// - Western dates: `2027-04-13`, `13/4/2027`, `13 Apr 2027`, `April 13`,
///   `၁၃ ဧပြီ`. Day first when it is all numbers, as people write in
///   Myanmar.
/// - Myanmar dates: `Tabaung full moon 1388`, `Tagu waxing 5`,
///   `တန်ခူးလဆန်း ၅`, `သီတင်းကျွတ်လပြည့်`. Years before 1800 are Myanmar
///   years, later ones Western years; without a year, the next one.
/// - `today`, `tomorrow`, `yesterday`, `next Sabbath`, `next full moon`,
///   `next new moon` (and ယနေ့, မနက်ဖြန်, ဥပုသ်, လပြည့်, လကွယ်).
///
/// Dates without a year are the next one from today, today included.
abstract final class DateQueryParser {
  /// The day [query] names, or null.
  static DateQueryMatch? parse(String query, {required DateTime today}) {
    final day = DateTime(today.year, today.month, today.day);
    final s = _normalize(query);
    if (s.isEmpty) return null;
    final compact = s.replaceAll(' ', '');
    return _relative(compact, day) ??
        _myanmar(s, compact, day) ??
        _westernNamed(s, compact, day) ??
        _westernNumeric(s, day);
  }

  static const _myanmarDigits = '၀၁၂၃၄၅၆၇၈၉';

  static String _normalize(String q) {
    var s = q.toLowerCase().trim();
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll(_myanmarDigits[i], '$i');
    }
    return s
        .replaceAll(RegExp(r'[,،။၊]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<int> _numbers(String s) => [
    for (final m in RegExp(r'\d+').allMatches(s)) int.parse(m.group(0)!),
  ];

  // --- today, next Sabbath... ---

  static DateQueryMatch? _relative(String compact, DateTime today) {
    final c = compact.startsWith('next') ? compact.substring(4) : compact;
    DateQueryMatch rel(DateTime d) => DateQueryMatch(d, DateQueryKind.relative);
    switch (c) {
      case 'today' || 'ယနေ့' || 'ဒီနေ့':
        return rel(today);
      case 'tomorrow' || 'မနက်ဖြန်':
        return rel(today.add(const Duration(days: 1)));
      case 'yesterday' || 'မနေ့က' || 'မနေ့':
        return rel(today.subtract(const Duration(days: 1)));
      case 'sabbath' || 'sabbathday' || 'ဥပုသ်' || 'ဥပုသ်နေ့':
        return _firstFrom(today, (d) => d.isSabbath, rel);
      case 'fullmoon' || 'လပြည့်' || 'လပြည့်နေ့':
        return _firstFrom(today, (d) => d.myanmar.moonPhase == 1, rel);
      case 'newmoon' || 'လကွယ်' || 'လကွယ်နေ့':
        return _firstFrom(today, (d) => d.myanmar.moonPhase == 3, rel);
    }
    return null;
  }

  static DateQueryMatch? _firstFrom(
    DateTime from,
    bool Function(CompleteDate) test,
    DateQueryMatch Function(DateTime) wrap,
  ) {
    for (var i = 0; i < 40; i++) {
      final d = DateTime(from.year, from.month, from.day + i);
      if (test(MyanmarCalendar.getCompleteDateFor(d.year, d.month, d.day))) {
        return wrap(d);
      }
    }
    return null;
  }

  // --- Myanmar dates ---

  /// Month names (lowercase, no spaces) to Myanmar month index, longest
  /// first so "secondwaso" wins over "waso".
  static final List<(String, int)> _myanmarMonths = () {
    final names = <(String, int)>[];
    for (var i = 0; i <= 14; i++) {
      for (final language in [Language.english, Language.myanmar]) {
        final name = TranslationService.getMonthName(i, 0, language);
        names.add((name.toLowerCase().replaceAll(' ', ''), i));
      }
    }
    // Second Waso is Waso (4) in a watat year; common spellings too.
    names.addAll(const [
      ('secondwaso', 4),
      ('dutiyawaso', 4),
      ('kasone', 2),
      ('nayone', 3),
      ('tazaungmone', 8),
      ('tawthalin', 6),
      ('thadingyut', 7),
      ('pyatho', 10),
      ('tabodwe', 11),
    ]);
    names.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return names;
  }();

  static (String, int)? _myanmarMonth(String compact) {
    for (final m in _myanmarMonths) {
      if (m.$1.isNotEmpty && compact.contains(m.$1)) return m;
    }
    return null;
  }

  static DateQueryMatch? _myanmar(String s, String compact, DateTime today) {
    final month = _myanmarMonth(compact);
    if (month == null) return null;
    final rest = compact.replaceFirst(month.$1, '');
    final full = rest.contains('fullmoon') || rest.contains('လပြည့်');
    final newMoon = rest.contains('newmoon') || rest.contains('လကွယ်');
    final waning = rest.contains('waning') || rest.contains('လဆုတ်');
    final numbers = _numbers(s);
    final year = numbers.where((n) => n >= 1000).firstOrNull;
    final dayNumber = numbers.where((n) => n >= 1 && n <= 15).firstOrNull;
    if (!full && !newMoon && dayNumber == null) return null;

    DateTime? resolveIn(int myanmarYear, int monthIndex) {
      try {
        final first = MyanmarCalendar.fromMyanmar(myanmarYear, monthIndex, 1);
        final length = first.monthLength;
        final day = full
            ? 15
            : newMoon
            ? length
            : waning
            ? 15 + dayNumber!
            : dayNumber!;
        if (day > length) return null;
        final d = MyanmarCalendar.fromMyanmar(myanmarYear, monthIndex, day);
        // A month the year doesn't have (First Waso outside watat years)
        // comes back as another month.
        if (d.myanmarMonth != monthIndex || d.myanmarYear != myanmarYear) {
          return null;
        }
        return DateTime(d.westernYear, d.westernMonth, d.westernDay);
      } on Exception {
        return null;
      }
    }

    // Tagu and Kason days before the new year are the previous year's Late
    // Tagu and Late Kason.
    DateTime? resolve(int myanmarYear) =>
        resolveIn(myanmarYear, month.$2) ??
        switch (month.$2) {
          1 => resolveIn(myanmarYear - 1, 13),
          2 => resolveIn(myanmarYear - 1, 14),
          13 => resolveIn(myanmarYear + 1, 1),
          14 => resolveIn(myanmarYear + 1, 2),
          _ => null,
        };

    DateQueryMatch my(DateTime d) => DateQueryMatch(d, DateQueryKind.myanmar);
    if (year != null && year < 1800) {
      final d = resolve(year);
      return d == null ? null : my(d);
    }
    if (year != null) {
      // A Western year: the Myanmar year that puts the day in it.
      for (final y in [year - 639, year - 638]) {
        final d = resolve(y);
        if (d != null && d.year == year) return my(d);
      }
      return null;
    }
    final thisYear = MyanmarCalendar.getCompleteDateFor(
      today.year,
      today.month,
      today.day,
    ).myanmarYear;
    for (final y in [thisYear - 1, thisYear, thisYear + 1, thisYear + 2]) {
      final d = resolve(y);
      if (d != null && !d.isBefore(today)) return my(d);
    }
    return null;
  }

  // --- Western dates ---

  static final List<(RegExp, int)> _englishMonths = [
    for (var m = 1; m <= 12; m++)
      (
        RegExp(
          '\\b${TranslationService.getWesternMonthName(m, Language.english).toLowerCase().substring(0, 3)}'
          '[a-z]*\\.?\\b',
        ),
        m,
      ),
  ];

  static final List<(String, int)> _myanmarWesternMonths = [
    for (var m = 1; m <= 12; m++)
      (
        TranslationService.getWesternMonthName(
          m,
          Language.myanmar,
        ).replaceAll(' ', ''),
        m,
      ),
  ]..sort((a, b) => b.$1.length.compareTo(a.$1.length));

  static DateQueryMatch? _westernNamed(
    String s,
    String compact,
    DateTime today,
  ) {
    int? month;
    for (final (re, m) in _englishMonths) {
      if (re.hasMatch(s)) {
        month = m;
        break;
      }
    }
    if (month == null) {
      for (final (name, m) in _myanmarWesternMonths) {
        if (name.isNotEmpty && compact.contains(name)) {
          month = m;
          break;
        }
      }
    }
    if (month == null) return null;
    final numbers = _numbers(s);
    final year = numbers.where((n) => n >= 1000).firstOrNull;
    final day = numbers.where((n) => n >= 1 && n <= 31).firstOrNull;
    if (day == null) return null;
    return _western(year, month, day, today);
  }

  static DateQueryMatch? _westernNumeric(String s, DateTime today) {
    final iso = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})$').firstMatch(s);
    if (iso != null) {
      return _western(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
        today,
      );
    }
    final dmy = RegExp(
      r'^(\d{1,2})[-/.](\d{1,2})(?:[-/.](\d{4}))?$',
    ).firstMatch(s);
    if (dmy != null) {
      return _western(
        dmy.group(3) == null ? null : int.parse(dmy.group(3)!),
        int.parse(dmy.group(2)!),
        int.parse(dmy.group(1)!),
        today,
      );
    }
    return null;
  }

  static DateQueryMatch? _western(
    int? year,
    int month,
    int day,
    DateTime today,
  ) {
    DateTime? valid(int y) {
      if (month < 1 || month > 12) return null;
      final d = DateTime(y, month, day);
      return d.month == month && d.day == day ? d : null;
    }

    DateQueryMatch w(DateTime d) => DateQueryMatch(d, DateQueryKind.western);
    if (year != null) {
      final d = valid(year);
      return d == null ? null : w(d);
    }
    // Four years ahead at most, for 29 February.
    for (var y = today.year; y <= today.year + 4; y++) {
      final d = valid(y);
      if (d != null && !d.isBefore(today)) return w(d);
    }
    return null;
  }
}
