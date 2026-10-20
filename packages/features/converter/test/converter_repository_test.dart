import 'package:converter/converter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main() {
  final day = DateTime(2026, 10, 22);

  String converted(Language language, {required bool preferShanYear}) {
    final before = MyanmarCalendar.currentLanguage;
    MyanmarCalendar.setLanguage(language);
    addTearDown(() => MyanmarCalendar.setLanguage(before));
    final repository = ConverterRepositoryImpl(
      shanYear: ShanYearPreference()..value = preferShanYear,
    );
    return repository
        .convertWesternToMyanmar(day)
        .fold((f) => fail('$f'), (r) => r.formattedMyanmar);
  }

  group('Prefer Shan Year', () {
    test('a Shan calendar shows the Shan year when preferred', () {
      expect(
        converted(Language.shan, preferShanYear: true),
        startsWith('2120 '),
      );
    });

    test('off, or in another language, the Myanmar year', () {
      expect(
        converted(Language.shan, preferShanYear: false),
        startsWith('1388 '),
      );
      expect(
        converted(Language.english, preferShanYear: true),
        startsWith('1388 '),
      );
    });

    test('Myanmar to Western follows the same rule', () {
      final before = MyanmarCalendar.currentLanguage;
      MyanmarCalendar.setLanguage(Language.shan);
      addTearDown(() => MyanmarCalendar.setLanguage(before));
      final preference = ShanYearPreference();
      final repository = ConverterRepositoryImpl(shanYear: preference);
      String format() => repository
          .convertMyanmarToWestern(1388, 7, 11)
          .fold((f) => fail('$f'), (r) => r.formattedMyanmar);
      expect(format(), startsWith('2120 '));
      preference.value = false;
      expect(format(), startsWith('1388 '));
    });
  });
}
