import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_widgets/home_widgets.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main() {
  final today = DateTime(2026, 10, 18);

  Map<String, Object?> build(
    Language language, {
    List<WidgetAgendaEvent>? events,
    bool preferShanYear = true,
    bool englishWesternDigits = false,
  }) => WidgetPayloadBuilder.build(
    today: today,
    language: language,
    events: events ?? const [],
    preferShanYear: preferShanYear,
    englishWesternDigits: englishWesternDigits,
    styles: WidgetPalettes.all(),
    prefs: const WidgetConfig.defaults().toPayload(),
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

    test('Western dates can use English digits', () {
      final my = build(Language.myanmar)['s']! as Map;
      expect(my['westernDigits'], '၀၁၂၃၄၅၆၇၈၉');
      final english = build(Language.myanmar, englishWesternDigits: true);
      final s = english['s']! as Map;
      expect(s['westernDigits'], '0123456789');
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

  test('events, styles and prefs are passed through', () {
    final payload = build(
      Language.english,
      events: [
        WidgetAgendaEvent(
          id: 3,
          date: today,
          title: 'Team call',
          color: 0xFF2F5BEA,
          time: DateTime(2026, 10, 18, 15, 30),
        ),
      ],
    );
    final event = (payload['events']! as List).single as Map;
    expect(event['t'], '15:30');
    expect(event['ti'], 'Team call');
    final styles = payload['styles']! as Map;
    for (final style in WidgetStyleId.values) {
      expect((styles[style.name] as Map).keys, containsAll(['light', 'dark']));
    }
    expect((payload['prefs']! as Map)['style'], 'app');
  });

  test('stays small enough to read on every widget refresh', () {
    final bytes = utf8.encode(jsonEncode(build(Language.myanmar))).length;
    expect(bytes, lessThan(160 * 1024));
  });

  group('links', () {
    String? go(String uri) => WidgetLinks.locationFor(Uri.parse(uri));

    test('map to app locations', () {
      expect(go('mmcalendar://today'), '/home');
      expect(
        go('mmcalendar://day/2026-10-18?homeWidget'),
        '/home/day-details?date=2026-10-18',
      );
      expect(go('mmcalendar://month/2026-11'), '/home?date=2026-11-01');
      expect(go('mmcalendar://event/12'), '/events/12/detail');
      expect(
        go('mmcalendar://events/new?date=2026-10-18'),
        '/events/create?date=2026-10-18',
      );
      expect(go('mmcalendar://events'), '/events');
    });

    test('ignore other schemes', () {
      expect(go('https://example.com/day/2026-10-18'), isNull);
      expect(WidgetLinks.locationFor(null), isNull);
    });
  });

  group('config', () {
    test('v1 themes migrate to styles', () {
      WidgetStyleId style(String theme) =>
          WidgetConfig.fromJson({'theme': theme}).style;
      expect(style('traditional'), WidgetStyleId.pagoda);
      expect(style('dark'), WidgetStyleId.plain);
      expect(style('gradientBlue'), WidgetStyleId.app);
    });

    test('round-trips', () {
      const config = WidgetConfig(
        style: WidgetStyleId.jade,
        showHolidays: false,
        showSabbath: true,
        showAstrology: false,
        showEvents: true,
        countdownTarget: CountdownTarget.thingyan,
        language: 'my',
      );
      expect(WidgetConfig.fromJson(config.toJson()), config);
    });
  });
}
