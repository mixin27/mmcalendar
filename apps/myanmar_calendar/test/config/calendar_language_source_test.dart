import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Calendar dates must come from CalendarFormat (the calendar language),
/// never from the interface locale. Times of day are fine.
void main() {
  test('presentation code formats calendar dates with CalendarFormat', () {
    final root = Directory('../../packages/features');
    final banned = RegExp(
      r"DateFormat\('[^']*[dMyE]|formatMonthYear\(|formatShortMonthDay\(|"
      r"formatFullDate\(|formatMediumDate\(|\.format\('[^']*[dMyE]",
    );
    final offenders = <String>[];
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      final path = file.path;
      if (!path.endsWith('.dart') ||
          !path.contains('/lib/src/presentation/') ||
          path.contains('/calendar_studio/')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (banned.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
