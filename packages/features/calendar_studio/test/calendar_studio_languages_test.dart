import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main() {
  const packageLanguages = [
    CalendarStudioLanguage.zawgyi,
    CalendarStudioLanguage.mon,
    CalendarStudioLanguage.shan,
    CalendarStudioLanguage.karen,
  ];

  for (final language in packageLanguages) {
    test(
      '${language.name} projects get titles and dates in that language',
      () async {
        final project = CalendarStudioTemplates.byId('family').create(
          id: 'p',
          source: CalendarStudioSource(year: 2027, language: language),
          now: DateTime(2027),
        );
        final march = project.pages[2];
        final title = march.blocks.firstWhere(
          (block) =>
              CalendarStudioBindings.of(block) ==
              CalendarStudioBinding.monthTitle,
        );
        expect(
          title.content['text'],
          TranslationService.getWesternMonthName(3, language.calendarLanguage),
        );
        expect(title.content.containsKey('subtitle'), isFalse);

        final days = await const MyanmarCalendarStudioDataProvider().daysFor(
          CalendarStudioSource(year: 2027, language: language),
          month: 3,
        );
        expect(
          days.first.myanmarLabel,
          MyanmarCalendar.formatMyanmar(
            MyanmarCalendar.getCompleteDate(DateTime(2027, 3)).myanmar,
            pattern: '&P &f',
            language: language.calendarLanguage,
          ),
        );
      },
    );
  }

  test('the app calendar language maps to a Studio language', () {
    for (final language in Language.values) {
      expect(
        CalendarStudioLanguageData.fromCalendarLanguage(
          language,
        ).calendarLanguage,
        language,
      );
    }
  });

  test('saved projects in "both" still open as Myanmar + English', () {
    final project = CalendarStudioTemplates.byId('jade-wall').create(
      id: 'p',
      source: const CalendarStudioSource(year: 2027),
      now: DateTime(2027),
    );
    final decoded = CalendarStudioDocumentCodec.decode(
      CalendarStudioDocumentCodec.encode(project),
    );
    expect(decoded.source.language, CalendarStudioLanguage.both);
    expect(CalendarStudioLanguage.both.label, 'Myanmar + English');
  });
}
