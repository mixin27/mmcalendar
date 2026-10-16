import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_moon/shared_moon.dart';

/// October 2026 as seen from Myanmar: 11th new, 26th full (the Thadingyut
/// full moon). Each row is a week; the shape should grow, then shrink.
Widget _month(Brightness brightness) {
  final days = List.generate(31, (i) => DateTime(2026, 10, i + 1));
  return Theme(
    data: ThemeData(brightness: brightness),
    child: ColoredBox(
      color: brightness == Brightness.dark
          ? Colors.black
          : const Color(0xFFF2F2F7),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 0; row < 5; row++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final day in days.skip(row * 7).take(7))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: MoonGlyph(date: day, size: 36),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  goldenTest(
    'moon glyph follows the real sky through October 2026',
    fileName: 'moon_glyph_october_2026',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        GoldenTestScenario(name: 'light', child: _month(Brightness.light)),
        GoldenTestScenario(name: 'dark', child: _month(Brightness.dark)),
      ],
    ),
  );

  goldenTest(
    'moon glyph colour sets and sizes',
    fileName: 'moon_glyph_variants',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: [
        for (final (name, colors, bg) in const [
          ('light', MoonColors.light, Color(0xFFFFFFFF)),
          ('dark', MoonColors.dark, Color(0xFF1C1C1E)),
          ('night (widgets)', MoonColors.night, Color(0xFF15171C)),
        ])
          for (final size in const [9.0, 24.0, 64.0])
            GoldenTestScenario(
              name: '$name $size',
              child: ColoredBox(
                color: bg,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: MoonGlyph(
                    date: DateTime(2026, 10, 22),
                    size: size,
                    colors: colors,
                  ),
                ),
              ),
            ),
      ],
    ),
  );
}
