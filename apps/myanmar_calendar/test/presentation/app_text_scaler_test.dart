import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmcalendar/app.dart';

void main() {
  double factor(TextScaler s) => s.scale(10) / 10;

  test('normally the system size, at most 1.3× (1.15× narrow)', () {
    expect(factor(appTextScaler(TextScaler.noScaling, width: 390)), 1);
    expect(factor(appTextScaler(const TextScaler.linear(2), width: 390)), 1.3);
    expect(factor(appTextScaler(const TextScaler.linear(2), width: 320)), 1.15);
  });

  test('easy reading: at least 1.3×, at most 1.5× (1.3× narrow)', () {
    expect(
      factor(
        appTextScaler(TextScaler.noScaling, width: 390, easyReading: true),
      ),
      1.3,
    );
    expect(
      factor(
        appTextScaler(
          const TextScaler.linear(1.4),
          width: 390,
          easyReading: true,
        ),
      ),
      closeTo(1.4, 1e-9),
    );
    expect(
      factor(
        appTextScaler(
          const TextScaler.linear(2),
          width: 390,
          easyReading: true,
        ),
      ),
      1.5,
    );
    expect(
      factor(
        appTextScaler(
          const TextScaler.linear(2),
          width: 320,
          easyReading: true,
        ),
      ),
      1.3,
    );
  });
}
