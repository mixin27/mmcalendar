import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

import '../catalog/holiday_catalog.dart';

/// One day of a holiday, with the library's names for that day in the
/// calendar language ("သင်္ကြန် အကြို", "Holiday").
class HolidayDay {
  const HolidayDay(this.date, this.labels);

  final DateTime date;
  final List<String> labels;
}

/// A holiday in a given year: one or more consecutive days.
class HolidayOccurrence {
  HolidayOccurrence(this.entry, this.days, this.searchNames);

  final HolidayEntry entry;
  final List<HolidayDay> days;

  /// The library's names for these days in English and the calendar
  /// language, for search.
  final Set<String> searchNames;

  DateTime get start => days.first.date;
  DateTime get end => days.last.date;
  int get length => days.length;

  /// Whether [date] (a calendar day) falls within this holiday.
  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Days from [today] to the start; negative once it has started.
  int daysFrom(DateTime today) =>
      start.difference(DateTime(today.year, today.month, today.day)).inDays;
}

/// Builds a year's holidays from `myanmar_calendar_dart` as catalog entries,
/// merging consecutive days of the same holiday into one occurrence and
/// folding the library's generic "Holiday" days into the holiday they
/// extend (Thingyan, Thadingyut, Tazaungdaing) or into New Year's Eve.
///
/// Uses the calendar's current configuration, so remote holiday rules
/// apply. Call [clearCache] after the configuration changes.
abstract final class HolidayYears {
  /// The years search covers when asked to look beyond the current one.
  static const firstYear = 2014;
  static const lastYear = 2035;

  static final Map<String, List<HolidayOccurrence>> _cache = {};

  static void clearCache() => _cache.clear();

  /// Cached per year and language, and rebuilt after the calendar's
  /// configuration (holiday rules) changes.
  static List<HolidayOccurrence> of(int year, Language language) =>
      _cache.putIfAbsent(
        '$year|${language.code}|$myanmarCalendarConfigGeneration',
        () => _build(year, language),
      );

  /// Holidays overlapping [from]..[to] (inclusive), across years.
  static List<HolidayOccurrence> between(
    DateTime from,
    DateTime to,
    Language language,
  ) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    return [
      for (var y = start.year; y <= end.year; y++)
        for (final o in of(y, language))
          if (!o.end.isBefore(start) && !o.start.isAfter(end)) o,
    ];
  }

  /// The occurrence of [entryId] in [year], if it has one.
  static HolidayOccurrence? find(String entryId, int year, Language language) {
    for (final o in of(year, language)) {
      if (o.entry.id == entryId) return o;
    }
    return null;
  }

  static List<HolidayOccurrence> _build(int year, Language language) {
    final first = DateTime(year, 1, 1);
    final dayCount = DateTime(year + 1, 1, 1).difference(first).inDays;

    // Per day: the entries on it, each with that day's labels and names.
    final perDay = List.generate(dayCount, (_) => <HolidayEntry, _DayPart>{});
    final bridge = List<_DayPart?>.filled(dayCount, null);

    for (var i = 0; i < dayCount; i++) {
      final date = DateTime(year, 1, 1 + i);
      final md = MyanmarCalendar.fromWestern(
        date.year,
        date.month,
        date.day,
      ).myanmarDate;
      final en = MyanmarCalendar.getHolidayInfo(md, language: Language.english);
      final local = language == Language.english
          ? en
          : MyanmarCalendar.getHolidayInfo(md, language: language);

      void bucket(
        List<String> english,
        List<String> localNames,
        HolidayKind kind,
        bool closed,
      ) {
        for (var k = 0; k < english.length; k++) {
          final name = english[k];
          final label = k < localNames.length ? localNames[k] : name;
          if (name == HolidayCatalog.bridgeName) {
            (bridge[i] ??= _DayPart()).add(label, name);
            continue;
          }
          final entry =
              HolidayCatalog.forName(name) ??
              HolidayCatalog.custom(label, kind: kind, officeClosed: closed);
          perDay[i].putIfAbsent(entry, _DayPart.new).add(label, name);
        }
      }

      bucket(
        en.publicHolidays,
        local.publicHolidays,
        HolidayKind.national,
        true,
      );
      bucket(
        en.religiousHolidays,
        local.religiousHolidays,
        HolidayKind.religious,
        false,
      );
      bucket(
        en.culturalHolidays,
        local.culturalHolidays,
        HolidayKind.cultural,
        false,
      );
      bucket(
        en.otherHolidays,
        local.otherHolidays,
        HolidayKind.cultural,
        false,
      );
      bucket(
        en.myanmarAnniversaryDays,
        local.myanmarAnniversaryDays,
        HolidayKind.anniversary,
        false,
      );
      bucket(
        en.otherAnniversaryDays,
        local.otherAnniversaryDays,
        HolidayKind.anniversary,
        false,
      );
    }

    // Fold each bridge day into the closed holiday it touches.
    bool closedOn(int i) =>
        i >= 0 &&
        i < dayCount &&
        (bridge[i] != null || perDay[i].keys.any((e) => e.officeClosed));
    HolidayEntry? anchor(int i) {
      for (final e in perDay[i].keys) {
        if (e.officeClosed) return e;
      }
      return null;
    }

    for (var i = 0; i < dayCount; i++) {
      final part = bridge[i];
      if (part == null) continue;
      HolidayEntry? target = anchor(i);
      for (var step = 1; target == null && step < 10; step++) {
        if (closedOn(i - step)) target ??= anchor(i - step);
        if (target == null && closedOn(i + step)) target = anchor(i + step);
        if (!closedOn(i - step) && !closedOn(i + step)) break;
      }
      final date = DateTime(year, 1, 1 + i);
      target ??= date.month == 12 && date.day == 31
          ? HolidayCatalog.newYearsEve
          : HolidayCatalog.publicHoliday;
      perDay[i].putIfAbsent(target, _DayPart.new).merge(part);
    }

    // Merge consecutive days of the same entry.
    final out = <HolidayOccurrence>[];
    final open =
        <
          HolidayEntry,
          ({List<HolidayDay> days, Set<String> names, int last})
        >{};
    void close(HolidayEntry e) {
      final run = open.remove(e)!;
      out.add(HolidayOccurrence(e, run.days, run.names));
    }

    for (var i = 0; i < dayCount; i++) {
      for (final e in open.keys.toList()) {
        if (!perDay[i].containsKey(e)) close(e);
      }
      final date = DateTime(year, 1, 1 + i);
      for (final MapEntry(key: e, value: part) in perDay[i].entries) {
        final run = open[e] ??= (
          days: <HolidayDay>[],
          names: <String>{},
          last: i,
        );
        run.days.add(HolidayDay(date, part.labels));
        run.names.addAll(part.names);
      }
    }
    for (final e in open.keys.toList()) {
      close(e);
    }
    out.sort((a, b) {
      final byDate = a.start.compareTo(b.start);
      if (byDate != 0) return byDate;
      // Public holidays before observances on the same day.
      if (a.entry.officeClosed != b.entry.officeClosed) {
        return a.entry.officeClosed ? -1 : 1;
      }
      return a.entry.kind.index.compareTo(b.entry.kind.index);
    });
    return out;
  }
}

class _DayPart {
  final labels = <String>[];
  final names = <String>{};

  void add(String label, String englishName) {
    if (!labels.contains(label)) labels.add(label);
    names
      ..add(label)
      ..add(englishName);
  }

  void merge(_DayPart other) {
    for (final l in other.labels) {
      if (!labels.contains(l)) labels.add(l);
    }
    names.addAll(other.names);
  }
}
