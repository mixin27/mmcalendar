import 'package:flutter_test/flutter_test.dart';
import 'package:holidays/holidays.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main() {
  setUp(HolidayYears.clearCache);

  test(
    'every holiday the library emits maps to a catalog entry, 2015–2035',
    () {
      for (var year = 2015; year <= 2035; year++) {
        for (final o in HolidayYears.of(year, Language.english)) {
          expect(
            o.entry.isCustom,
            isFalse,
            reason: '$year ${o.start}: ${o.searchNames}',
          );
          if (o.entry == HolidayCatalog.publicHoliday) {
            // Only the year-end days of 2017 and the substitute days of
            // 2019–2021 stand alone.
            expect(
              year,
              inInclusiveRange(2017, 2021),
              reason: '${o.start} ${o.searchNames}',
            );
          }
        }
      }
    },
  );

  test('multi-day holidays are one occurrence in 2026', () {
    final year = HolidayYears.of(2026, Language.english);
    HolidayOccurrence only(HolidayEntry e) =>
        year.singleWhere((o) => o.entry == e);

    final thingyan = only(HolidayCatalog.thingyan);
    expect(thingyan.start, DateTime(2026, 4, 13));
    expect(thingyan.end, DateTime(2026, 4, 21));
    expect(thingyan.length, 9);

    final thadingyut = only(HolidayCatalog.thadingyut);
    expect(
      [thadingyut.start, thadingyut.end],
      [DateTime(2026, 10, 25), DateTime(2026, 10, 27)],
    );
    // The full moon is End of Buddhist Lent only; the public holidays are
    // the days either side.
    expect(thadingyut.days.map((d) => d.labels), [
      ['Holiday'],
      ['End of Buddhist Lent'],
      ['Holiday'],
    ]);

    final tazaungdaing = only(HolidayCatalog.tazaungdaing);
    expect(
      [tazaungdaing.start, tazaungdaing.end],
      [DateTime(2026, 11, 23), DateTime(2026, 11, 24)],
    );

    // 31 December is a public holiday only from 2018 to 2021.
    expect(year.where((o) => o.entry == HolidayCatalog.newYearsEve), isEmpty);
    expect(
      HolidayYears.of(
        2021,
        Language.english,
      ).singleWhere((o) => o.entry == HolidayCatalog.newYearsEve).start,
      DateTime(2021, 12, 31),
    );
  });

  test('2026 has 16 public holidays', () {
    final closed = HolidayYears.of(
      2026,
      Language.english,
    ).where((o) => o.entry.officeClosed);
    // 1 January and 31 December stopped being public holidays after 2021.
    expect(closed.length, 16);
  });

  test('labels follow the calendar language', () {
    final thingyan = HolidayYears.of(
      2026,
      Language.myanmar,
    ).singleWhere((o) => o.entry == HolidayCatalog.thingyan);
    expect(thingyan.days.first.labels.single, 'သင်္ကြန် အကြို');
    expect(thingyan.searchNames, contains('Thingyan Akyo'));
  });

  test('between spans years', () {
    // 2020 to 2021, while New Year's Eve and New Year's Day were holidays.
    final list = HolidayYears.between(
      DateTime(2020, 12, 20),
      DateTime(2021, 1, 10),
      Language.english,
    );
    expect(
      list.map((o) => o.entry.id),
      containsAllInOrder([
        'christmas',
        'newYearsEve',
        'newYear',
        'independence',
      ]),
    );
  });

  test('search matches titles, library names in any language, and aliases', () {
    final mm = HolidayYears.of(2026, Language.myanmar);
    final thingyan = mm.singleWhere((o) => o.entry == HolidayCatalog.thingyan);
    expect(HolidaySearch.match(thingyan, 'water festival'), 'Water Festival');
    expect(HolidaySearch.match(thingyan, 'akyat'), isNotNull);
    expect(HolidaySearch.match(thingyan, 'သင်္ကြန်'), isNotNull);
    expect(
      HolidaySearch.match(
        thingyan,
        'Thingyan',
        titles: ['Thingyan and Myanmar New Year'],
      ),
      'Thingyan and Myanmar New Year',
    );

    final fullMoons = HolidayYears.of(
      2026,
      Language.english,
    ).where((o) => HolidaySearch.match(o, 'full moon') != null);
    expect(fullMoons.map((o) => o.entry.id), [
      'tabaung',
      'buddhaDay',
      'lentStart',
      'thadingyut',
      'tazaungdaing',
    ]);
  });

  test('filters', () {
    expect(HolidayFilter.public.accepts(HolidayCatalog.buddhaDay), isTrue);
    expect(HolidayFilter.public.accepts(HolidayCatalog.goodFriday), isFalse);
    expect(HolidayFilter.cultural.accepts(HolidayCatalog.thingyan), isTrue);
    expect(
      HolidayFilter.anniversary.accepts(HolidayCatalog.unitedNations),
      isTrue,
    );
  });

  test('a year builds quickly', () {
    final watch = Stopwatch()..start();
    HolidayYears.of(2030, Language.myanmar);
    expect(watch.elapsedMilliseconds, lessThan(1500));
    // ignore: avoid_print
    print('2030 built in ${watch.elapsedMilliseconds} ms');
  });
}
