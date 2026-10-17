import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_motifs/shared_motifs.dart';

void main() {
  testWidgets('every kind paints in square, wide and tall boxes', (
    tester,
  ) async {
    for (final kind in MotifPainter.kinds) {
      for (final size in const [Size(96, 96), Size(160, 48), Size(48, 120)]) {
        await tester.pumpWidget(
          Center(
            child: CustomPaint(
              size: size,
              painter: MotifPainter(
                kind,
                color: const Color(0xFF6B1F23),
                accent: const Color(0xFFC9A227),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$kind at $size');
      }
    }
  });

  test('repaints only when something visible changes', () {
    const a = MotifPainter(
      'stupa',
      color: Color(0xFF000000),
      accent: Color(0xFFFFFFFF),
    );
    const same = MotifPainter(
      'stupa',
      color: Color(0xFF000000),
      accent: Color(0xFFFFFFFF),
    );
    const other = MotifPainter(
      'rain',
      color: Color(0xFF000000),
      accent: Color(0xFFFFFFFF),
    );
    expect(a.shouldRepaint(same), isFalse);
    expect(a.shouldRepaint(other), isTrue);
  });
}
