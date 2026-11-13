import 'package:flutter_test/flutter_test.dart';
import 'package:shared_widget_payload/shared_widget_payload.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  final today = DateTime(2026, 10, 18);

  Map<String, Object?> build(
    Language language, {
    List<WidgetAgendaEvent>? events,
    bool preferShanYear = true,
    bool englishWesternDates = false,
  }) => WidgetPayloadBuilder.build(
    today: today,
    language: language,
    events: events ?? const [],
    preferShanYear: preferShanYear,
    englishWesternDates: englishWesternDates,
    generatedAt: DateTime(2026, 10, 18, 9),
  );

  group('days', () {
    test('180 days from today, Sunday first', () {
      final days = build(Language.english)['days']! as List;
      expect(days, hasLength(180));
      final first = days.first as Map;
      expect(first['d'], '2026-10-18');
      expect(first['wd'], 0);
      expect((days.last as Map)['d'], '2027-04-15');
    });

    test('Sabbath, holidays and moon are typed', () {
      final days = {
        for (final d in build(Language.english)['days']! as List)
          (d as Map)['d']: d,
      };
      expect(days['2026-10-19']!['sab'], 1, reason: 'waxing 8 is Sabbath');
      expect(days['2026-10-18']!['sab'], 2, reason: 'the eve before');
      expect(days['2026-10-26']!['ph'], 1, reason: 'full moon');
      expect(days['2026-10-25']!['hol'], isNotEmpty);
    });

    test('good and avoid follow the app rule, as day details does', () {
      for (final d in build(Language.english)['days']! as List) {
        final day = d as Map;
        final date = DateTime.parse(day['d'] as String);
        final complete = MyanmarCalendar.getCompleteDateFor(
          date.year,
          date.month,
          date.day,
        );
        // The widget's "next good day" test is good and nothing to avoid.
        expect(
          (day['good'] as List).isNotEmpty && (day['avoid'] as List).isEmpty,
          GoodDays.isGood(complete),
          reason: day['d'] as String,
        );
        if (complete.yatyaza.isNotEmpty) {
          expect(day['good'], contains('Yatyaza'), reason: day['d'] as String);
        }
        if (complete.astrologicalDays.contains('Thamanyo')) {
          expect(day['avoid'], contains('Thamanyo'));
        }
      }
    });

    test('Myanmar text and digits follow the language', () {
      final my = build(Language.myanmar);
      final first = (my['days']! as List).first as Map;
      expect(first['ln'], '၇');
      expect((my['s']! as Map)['digits'], '၀၁၂၃၄၅၆၇၈၉');
      expect((my['s']! as Map)['today'], 'ယနေ့');
      final en = build(Language.english);
      expect(((en['days']! as List).first as Map)['ln'], '7');
      expect((en['s']! as Map)['inDays'], 'in {n} days');
    });

    test('Western dates can be in English', () {
      final my = build(Language.myanmar)['s']! as Map;
      expect(my['westernDigits'], '၀၁၂၃၄၅၆၇၈၉');
      final english = build(Language.myanmar, englishWesternDates: true);
      final s = english['s']! as Map;
      expect(s['westernDigits'], '0123456789');
      expect((s['months']! as List)[9], 'October');
      expect((s['monthsShort']! as List)[9], 'Oct');
      expect((my['months']! as List)[9], 'အောက်တိုဘာ');
      expect((s['weekdays']! as List), my['weekdays'], reason: 'shared');
      expect(s['digits'], '၀၁၂၃၄၅၆၇၈၉', reason: 'Myanmar dates keep theirs');
      expect(((english['days']! as List).first as Map)['ln'], '၇');
    });
  });

  test('coming up lists the next Sabbath, holiday and full moon in order', () {
    final upcoming = build(Language.english)['upcoming']! as List;
    final dates = [for (final u in upcoming) (u as Map)['d'] as String];
    expect(dates, orderedEquals([...dates]..sort()));
    final kinds = {for (final u in upcoming) '${(u as Map)['d']} ${u['k']}'};
    expect(kinds, contains('2026-10-19 sabbath'));
    expect(kinds, contains('2026-10-25 holiday'));
    expect(kinds, contains('2026-10-26 fullMoon'));
    // A run of holiday days counts once.
    expect(kinds, isNot(contains('2026-10-26 holiday')));
  });

  test('Thingyan and the Myanmar year bracket today', () {
    final payload = build(Language.english);
    final thingyan = payload['thingyan']! as Map;
    expect(DateTime.parse(thingyan['d'] as String).isAfter(today), isTrue);
    expect(DateTime.parse(thingyan['d'] as String).month, 4);
    final year = payload['year']! as Map;
    final start = DateTime.parse(year['start'] as String);
    final end = DateTime.parse(year['end'] as String);
    expect(start.isAfter(today), isFalse);
    expect(end.isAfter(today), isTrue);
    expect(end.difference(start).inDays, inInclusiveRange(354, 385));
    expect(year['n'], '1388');
  });

  group('Prefer Shan Year', () {
    test('a Shan calendar shows the Shan year and its New Year bounds', () {
      final payload = build(Language.shan);
      final year = payload['year']! as Map;
      expect(year['n'], '2120');
      // Shan New Year falls around Nadaw, late in the Gregorian year.
      final start = DateTime.parse(year['start'] as String);
      final end = DateTime.parse(year['end'] as String);
      expect(start.isAfter(today), isFalse);
      expect(start.year, 2025);
      expect(end.isAfter(today), isTrue);
      expect(end.isAfter(DateTime(2026, 12, 31)), isFalse);
      expect(end.difference(start).inDays, inInclusiveRange(354, 385));
      final months = payload['months']! as Map;
      expect((months['2026-10']! as Map)['sub'], endsWith('· 2120'));
      expect((months['2026-12']! as Map)['sub'], endsWith('· 2121'));
    });

    test('off, or in another language, the Myanmar year', () {
      for (final payload in [
        build(Language.shan, preferShanYear: false),
        build(Language.english),
      ]) {
        expect((payload['year']! as Map)['n'], '1388');
        final months = payload['months']! as Map;
        expect((months['2026-12']! as Map)['sub'], endsWith('· 1388'));
      }
    });
  });

  test('months cover last month to five ahead, 42 cells, no today flag', () {
    final months = build(Language.english)['months']! as Map;
    expect(months.keys, containsAll(['2026-09', '2026-10', '2027-03']));
    final october = months['2026-10'] as Map;
    expect(october['title'], 'October 2026');
    final cells = october['cells'] as List;
    expect(cells, hasLength(42));
    expect((cells.first as Map)['d'], 27, reason: 'Sunday 27 September');
    expect((cells.first as Map)['in'], isFalse);
    expect((cells.first as Map).containsKey('today'), isFalse);
  });

  test('notes go in by day, earliest first, with the widget words', () {
    final payload = WidgetPayloadBuilder.build(
      today: today,
      language: Language.english,
      notes: {
        DateTime(2026, 10, 20): 'Dentist',
        DateTime(2026, 10, 18): 'Offer food to monks',
      },
    );
    expect(payload['notes'], [
      {'d': '2026-10-18', 't': 'Offer food to monks'},
      {'d': '2026-10-20', 't': 'Dentist'},
    ]);
    final s = payload['s']! as Map;
    expect(s['addNote'], 'Add a note');
    expect(s['goodDays'], 'Good days');
    expect(
      (WidgetPayloadBuilder.build(
            today: today,
            language: Language.myanmar,
          )['s']!
          as Map)['note'],
      'မှတ်စု',
    );
  });

  group('slim (watch)', () {
    Map<String, Object?> slim(Language language) =>
        WidgetPayloadBuilder.buildSlim(
          today: today,
          language: language,
          generatedAt: DateTime(2026, 10, 18, 9),
        );

    test('only days, words and coming up', () {
      expect(slim(Language.english).keys, [
        'v',
        'lang',
        'gen',
        'start',
        's',
        'days',
        'upcoming',
      ]);
      expect(
        slim(Language.english)['days'],
        hasLength(WidgetPayloadBuilder.slimDays),
      );
    });

    test('matches the full payload where they overlap', () {
      final full = build(Language.myanmar);
      final small = slim(Language.myanmar);
      for (final key in ['v', 'lang', 'gen', 'start', 's', 'upcoming']) {
        expect(small[key], full[key], reason: key);
      }
      expect(
        small['days'],
        (full['days']! as List).take(WidgetPayloadBuilder.slimDays).toList(),
      );
    });
  });
}
