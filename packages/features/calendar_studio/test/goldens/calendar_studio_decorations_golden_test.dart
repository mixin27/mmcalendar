import 'package:alchemist/alchemist.dart';
import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';

void main() {
  const sizes = {
    'horizonWave': Size(220, 40),
    'diamondWeave': Size(220, 30),
    'paperLantern': Size(200, 110),
    'sunRays': Size(180, 120),
  };
  goldenTest(
    'round-2 decorations draw inside their boxes',
    fileName: 'decorations',
    builder: () => GoldenTestGroup(
      columns: 5,
      children: [
        for (final kind in CalendarStudioDecorations.kinds)
          GoldenTestScenario(
            name: kind,
            child: Container(
              color: const Color(0xFFF7F0DE),
              padding: const EdgeInsets.all(8),
              child: SizedBox.fromSize(
                size: sizes[kind] ?? const Size(140, 120),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x22000000)),
                  ),
                  child: CalendarStudioDecorations.build(
                    CalendarStudioBlock(
                      id: kind,
                      type: CalendarStudioBlockType.decoration,
                      name: kind,
                      bounds: const StudioRect(
                        left: 0,
                        top: 0,
                        width: 1,
                        height: 1,
                      ),
                      content: {'kind': kind},
                      style: const {'color': 0xFF6B1F23, 'accent': 0xFFC9A227},
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
