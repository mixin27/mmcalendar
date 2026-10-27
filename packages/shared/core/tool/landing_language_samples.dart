// Writes the landing site's "6 calendar languages" samples: one date as the
// app writes it in each calendar language.
//
//   cd packages/shared/core
//   dart run tool/landing_language_samples.dart ../../../site/src/content/languages.json
import 'dart:convert';
import 'dart:io';

import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// The full moon of Thadingyut 1388 ME.
final date = DateTime(2026, 10, 26);

void main(List<String> args) {
  final samples = [
    for (final language in Language.values)
      {
        'language': language.code,
        'text': MyanmarCalendar.formatMyanmar(
          MyanmarCalendar.getCompleteDate(date, language: language).myanmar,
          pattern: '&y &M &P &ff',
          language: language,
        ),
      },
  ];
  final json = const JsonEncoder.withIndent('  ').convert({
    'date': date.toIso8601String().substring(0, 10),
    'samples': samples,
  });
  if (args.isEmpty) {
    stdout.writeln(json);
  } else {
    File(args.single).writeAsStringSync('$json\n');
  }
}
