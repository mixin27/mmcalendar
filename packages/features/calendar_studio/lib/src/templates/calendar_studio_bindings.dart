import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart' as mm;

import '../models/calendar_studio_document.dart';
import '../models/calendar_studio_types.dart';

/// What a bound text block shows; it is rewritten for every page's month and
/// the project's language, so one template design works for any month.
enum CalendarStudioBinding {
  /// The month name: Myanmar, English, or Myanmar with an English subtitle.
  monthTitle,

  /// The Gregorian year, in Myanmar or Western digits.
  yearTitle,

  /// Month and year on one line ("October 2026").
  monthYear,

  /// The Myanmar months and era years the Gregorian month spans.
  eraLine;

  static CalendarStudioBinding? tryParse(Object? value) {
    for (final binding in values) {
      if (binding.name == value) return binding;
    }
    return null;
  }

  /// Short label for the "Updates every month" chips.
  String get label => switch (this) {
    monthTitle => 'Month name',
    yearTitle => 'Year',
    monthYear => 'Month and year',
    eraLine => 'Myanmar era',
  };
}

/// Resolves, applies and detects [CalendarStudioBinding]s on text blocks.
///
/// Block content keys:
/// - `binding`: the [CalendarStudioBinding] name.
/// - `bindingSubtitle`: a month title also gets the English month as its
///   subtitle when the language is both.
/// - `bindingUpper`: the text is written in capitals.
abstract final class CalendarStudioBindings {
  static const key = 'binding';
  static const subtitleKey = 'bindingSubtitle';
  static const upperKey = 'bindingUpper';

  static CalendarStudioBinding? of(CalendarStudioBlock block) =>
      block.type == CalendarStudioBlockType.text
      ? CalendarStudioBinding.tryParse(block.content[key])
      : null;

  /// The text (and subtitle, for a month title in both languages).
  static (String, String?) resolve(
    CalendarStudioBinding binding, {
    required CalendarStudioLanguage language,
    required int year,
    required int month,
  }) {
    final mmMonth = myanmarMonths[month - 1];
    final enMonth = englishMonths[month - 1];
    return switch (binding) {
      CalendarStudioBinding.monthTitle => switch (language) {
        CalendarStudioLanguage.myanmar => (mmMonth, null),
        CalendarStudioLanguage.english => (enMonth, null),
        CalendarStudioLanguage.both => (mmMonth, enMonth),
      },
      CalendarStudioBinding.yearTitle => (
        language == CalendarStudioLanguage.myanmar
            ? myanmarNumber(year)
            : '$year',
        null,
      ),
      CalendarStudioBinding.monthYear => (
        language == CalendarStudioLanguage.myanmar
            ? '$mmMonth ${myanmarNumber(year)}'
            : '$enMonth $year',
        null,
      ),
      CalendarStudioBinding.eraLine => (eraLine(year, month), null),
    };
  }

  /// [block] with its bound text rewritten for [year]/[month]; unbound
  /// blocks are returned unchanged.
  static CalendarStudioBlock apply(
    CalendarStudioBlock block, {
    required CalendarStudioLanguage language,
    required int year,
    required int month,
  }) {
    final binding = of(block);
    if (binding == null) return block;
    var (text, subtitle) = resolve(
      binding,
      language: language,
      year: year,
      month: month,
    );
    if (block.content[upperKey] == true) {
      text = text.toUpperCase();
      subtitle = subtitle?.toUpperCase();
    }
    final withSubtitle = block.content[subtitleKey] == true;
    return block.copyWith(
      content: {
        for (final entry in block.content.entries)
          if (entry.key != 'subtitle') entry.key: entry.value,
        'text': text,
        if (withSubtitle && subtitle != null) 'subtitle': subtitle,
      },
    );
  }

  /// The binding whose text for [year]/[month], in any language, equals
  /// [text]; English matches ignore case.
  static CalendarStudioBinding? detect(String text, int year, int month) {
    final value = text.trim();
    if (value.isEmpty) return null;
    for (final binding in CalendarStudioBinding.values) {
      for (final language in CalendarStudioLanguage.values) {
        final (candidate, _) = resolve(
          binding,
          language: language,
          year: year,
          month: month,
        );
        if (candidate == value ||
            candidate.toLowerCase() == value.toLowerCase()) {
          return binding;
        }
      }
    }
    return null;
  }

  /// [block] marked with the binding its current text matches on a page for
  /// [year]/[month]; blocks that are already bound, or match nothing, are
  /// returned unchanged.
  static CalendarStudioBlock markDetected(
    CalendarStudioBlock block, {
    required int year,
    required int month,
  }) {
    if (block.type != CalendarStudioBlockType.text || of(block) != null) {
      return block;
    }
    final text = block.content['text'] as String? ?? '';
    final binding = detect(text, year, month);
    if (binding == null) return block;
    final subtitle = block.content['subtitle'] as String?;
    final upper =
        RegExp('[A-Za-z]').hasMatch(text) && text == text.toUpperCase();
    return block.copyWith(
      content: {
        ...block.content,
        key: binding.name,
        if (binding == CalendarStudioBinding.monthTitle &&
            subtitle != null &&
            subtitle.toLowerCase() == englishMonths[month - 1].toLowerCase())
          subtitleKey: true,
        if (upper) upperKey: true,
      },
    );
  }

  /// [block] without its binding, so its text stays as typed.
  static CalendarStudioBlock unbind(CalendarStudioBlock block) =>
      block.copyWith(
        content: {
          for (final entry in block.content.entries)
            if (entry.key != key &&
                entry.key != subtitleKey &&
                entry.key != upperKey)
              entry.key: entry.value,
        },
      );

  /// "သီတင်းကျွတ်၊ တန်ဆောင်မုန်း ၁၃၈၈" for the Myanmar months a Gregorian
  /// month spans and their era years.
  static String eraLine(int year, int month) {
    final first = mm.MyanmarCalendar.getCompleteDate(DateTime(year, month, 1));
    final last = mm.MyanmarCalendar.getCompleteDate(
      DateTime(year, month + 1, 0),
    );
    String monthOf(mm.MyanmarDate date) => mm.MyanmarCalendar.formatMyanmar(
      date,
      pattern: '&M',
      language: mm.Language.myanmar,
    );
    final firstMonth = monthOf(first.myanmar);
    final lastMonth = monthOf(last.myanmar);
    final years = eraYearsBetween(first.myanmar, last.myanmar);
    return '${firstMonth == lastMonth ? firstMonth : '$firstMonth၊ $lastMonth'} $years';
  }

  static String eraYearsBetween(mm.MyanmarDate first, mm.MyanmarDate last) {
    final a = myanmarNumber(first.year);
    final b = myanmarNumber(last.year);
    return a == b ? a : '$a–$b';
  }

  static String myanmarNumber(Object value) =>
      value.toString().replaceAllMapped(
        RegExp(r'\d'),
        (match) => '၀၁၂၃၄၅၆၇၈၉'[int.parse(match[0]!)],
      );

  static const myanmarMonths = [
    'ဇန်နဝါရီ',
    'ဖေဖော်ဝါရီ',
    'မတ်',
    'ဧပြီ',
    'မေ',
    'ဇွန်',
    'ဇူလိုင်',
    'ဩဂုတ်',
    'စက်တင်ဘာ',
    'အောက်တိုဘာ',
    'နိုဝင်ဘာ',
    'ဒီဇင်ဘာ',
  ];

  static const englishMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}
