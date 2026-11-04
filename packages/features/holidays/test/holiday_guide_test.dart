import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holidays/holidays.dart';
// The raw maps, to check every key and part.
import 'package:holidays/src/guide/holiday_guide_en.dart';
import 'package:holidays/src/guide/holiday_guide_my.dart';
import 'package:shared_localizations/shared_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final my = lookupAppLocalizations(const Locale('my'));
  final ids = {for (final e in HolidayCatalog.all) e.id};
  final parts = {for (final p in HolidayGuidePart.values) p.name};

  /// The holidays visitors meet most. Each says what happens, the practical
  /// side and where to see it; etiquette only where there is any.
  const main = [
    'thingyan',
    'thadingyut',
    'tazaungdaing',
    'buddhaDay',
    'lentStart',
    'tabaung',
    'karenNewYear',
    'shanNewYear',
    'independence',
    'newYear',
  ];

  for (final (name, guide) in [
    ('en', holidayGuideEn),
    ('my', holidayGuideMy),
  ]) {
    test('$name: every key is a holiday and every part is known', () {
      for (final MapEntry(key: id, value: entry) in guide.entries) {
        expect(ids, contains(id));
        for (final MapEntry(key: part, value: text) in entry.entries) {
          expect(parts, contains(part), reason: '$id.$part');
          expect(text.trim(), isNotEmpty, reason: '$id.$part');
          expect(text.trim(), text, reason: '$id.$part has stray spaces');
          expect(text.length, lessThanOrEqualTo(480), reason: '$id.$part');
        }
      }
    });
  }

  test('the main festivals are covered in both languages', () {
    for (final id in main) {
      final entry = HolidayCatalog.byId(id)!;
      expect(
        HolidayGuide.of(entry, en).keys,
        containsAll([
          HolidayGuidePart.happens,
          HolidayGuidePart.practical,
          HolidayGuidePart.where,
        ]),
        reason: id,
      );
      expect(
        holidayGuideMy[id]?.keys,
        unorderedEquals(holidayGuideEn[id]!.keys),
        reason: '$id: Myanmar has the same parts as English',
      );
    }
  });

  test('parts come in a fixed order, Myanmar falling back to English', () {
    final thingyan = HolidayCatalog.thingyan;
    expect(HolidayGuide.of(thingyan, my).keys, HolidayGuidePart.values);
    expect(
      HolidayGuide.of(thingyan, my)[HolidayGuidePart.happens],
      holidayGuideMy['thingyan']!['happens'],
    );
    // A holiday with no guide has no parts.
    expect(
      HolidayGuide.of(
        HolidayCatalog.custom(
          'Pagoda fair',
          kind: HolidayKind.cultural,
          officeClosed: false,
        ),
        en,
      ),
      isEmpty,
    );
  });
}
