import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_moon/shared_moon.dart';

void main() {
  group('MoonPhaseState.at matches published phase times', () {
    // Instants from the US Naval Observatory phase tables (UTC).
    final cases = <(String, DateTime, double, bool?)>[
      ('new moon', DateTime.utc(2024, 4, 8, 18, 21), 0, null),
      ('full moon', DateTime.utc(2024, 4, 23, 23, 49), 1, null),
      ('first quarter', DateTime.utc(2024, 1, 18, 3, 53), .5, true),
      ('last quarter', DateTime.utc(2024, 2, 2, 23, 18), .5, false),
      ('full moon', DateTime.utc(2025, 3, 14, 6, 55), 1, null),
      ('new moon', DateTime.utc(2025, 9, 21, 19, 54), 0, null),
    ];
    for (final (name, instant, lit, waxing) in cases) {
      test('$name ${instant.toIso8601String()}', () {
        final moon = MoonPhaseState.at(instant);
        expect(moon.illumination, closeTo(lit, .02));
        if (waxing != null) expect(moon.isWaxing, waxing);
      });
    }
  });

  test('Myanmar evenings agree with the October 2026 calendar', () {
    // လကွယ် on 11 Oct and လပြည့် on 26 Oct.
    final newMoon = MoonPhaseState.evening(DateTime(2026, 10, 11));
    final fullMoon = MoonPhaseState.evening(DateTime(2026, 10, 26));
    expect(newMoon.illumination, lessThan(.02));
    expect(fullMoon.illumination, greaterThan(.98));
    expect(MoonPhaseState.evening(DateTime(2026, 10, 16)).isWaxing, isTrue);
    expect(MoonPhaseState.evening(DateTime(2026, 10, 30)).isWaxing, isFalse);
  });

  test('evening uses 18:30 at the given offset', () {
    final date = DateTime(2026, 10, 16);
    expect(
      MoonPhaseState.evening(date),
      MoonPhaseState.at(DateTime.utc(2026, 10, 16, 12)),
    );
    expect(
      MoonPhaseState.evening(date, utcOffset: Duration.zero),
      MoonPhaseState.at(DateTime.utc(2026, 10, 16, 18, 30)),
    );
  });

  test('illumination rises to full, then falls, day by day', () {
    final days = [
      for (var d = 12; d <= 31; d++)
        MoonPhaseState.evening(DateTime(2026, 10, d)),
    ];
    final peak = days.indexWhere((m) => !m.isWaxing);
    for (var i = 1; i < peak; i++) {
      expect(days[i].illumination, greaterThan(days[i - 1].illumination));
    }
    for (var i = peak + 1; i < days.length; i++) {
      expect(days[i].illumination, lessThan(days[i - 1].illumination));
    }
    expect(days.first.cycle, lessThan(.1));
    expect(days.last.cycle, greaterThan(.6));
  });

  group('MoonPainter.litPath', () {
    const radius = 100.0;

    double litShare(MoonPhaseState state, {double tilt = 0}) {
      final path = MoonPainter.litPath(state, radius, tilt: tilt);
      if (path == null) return 0;
      var inside = 0, total = 0;
      for (var y = -radius; y <= radius; y += 2) {
        for (var x = -radius; x <= radius; x += 2) {
          if (x * x + y * y > radius * radius) continue;
          total++;
          if (path.contains(Offset(x, y))) inside++;
        }
      }
      return inside / total;
    }

    MoonPhaseState phase(double k, {bool waxing = true}) => MoonPhaseState(
      illumination: k,
      isWaxing: waxing,
      phaseAngle: math.acos(2 * k - 1) * 180 / math.pi,
    );

    for (final k in [.1, .3, .5, .7, .9]) {
      test('lit area equals illumination at $k', () {
        expect(litShare(phase(k)), closeTo(k, .02));
        expect(litShare(phase(k, waxing: false)), closeTo(k, .02));
      });
    }

    test('waxing is lit on the right, waning on the left when upright', () {
      final waxing = MoonPainter.litPath(phase(.3), radius, tilt: 0)!;
      final waning = MoonPainter.litPath(
        phase(.3, waxing: false),
        radius,
        tilt: 0,
      )!;
      expect(waxing.contains(const Offset(90, 0)), isTrue);
      expect(waxing.contains(const Offset(-90, 0)), isFalse);
      expect(waning.contains(const Offset(-90, 0)), isTrue);
      expect(waning.contains(const Offset(90, 0)), isFalse);
    });

    test('Myanmar tilt lights the lower right while waxing, upper left while '
        'waning', () {
      final lowerRight = Offset.fromDirection(MoonTilt.myanmar, 90);
      final upperLeft = -lowerRight;
      final waxing = MoonPainter.litPath(phase(.25), radius)!;
      final waning = MoonPainter.litPath(phase(.25, waxing: false), radius)!;
      expect(lowerRight.dx > 0 && lowerRight.dy > 0, isTrue);
      expect(waxing.contains(lowerRight), isTrue);
      expect(waxing.contains(upperLeft), isFalse);
      expect(waning.contains(upperLeft), isTrue);
      expect(waning.contains(lowerRight), isFalse);
    });

    test('new moon has no lit path; full moon is the whole disc', () {
      expect(MoonPainter.litPath(phase(0), radius), isNull);
      expect(litShare(phase(1)), closeTo(1, .001));
    });
  });

  testWidgets('MoonGlyph describes the moon and follows the theme', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Center(child: MoonGlyph(date: DateTime(2026, 10, 26), size: 40)),
      ),
    );
    expect(find.bySemanticsLabel(RegExp(r'^Moon (99|100)% lit')), findsOne);
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(MoonGlyph),
        matching: find.byType(CustomPaint),
      ),
    );
    final painter = paint.painter! as MoonPainter;
    expect(painter.colors, MoonColors.dark);
    expect(painter.texture, isFalse);
    handle.dispose();
  });
}
