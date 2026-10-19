import 'package:calendar_studio/calendar_studio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmcalendar/config/calendar_studio_look.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

void main() {
  test('Studio takes the app accent, surfaces and text colours', () {
    for (final style in [AppStyle.clear, AppStyle.material]) {
      for (final scheme in [
        AppColorSchemes.modernLight,
        AppColorSchemes.modernDark,
      ]) {
        final t = AppTokens.resolve(style: style, scheme: scheme);
        final studio = calendarStudioTokensFrom(t, scheme.brightness);
        expect(studio.primary, t.accent);
        expect(studio.onPrimary, t.onAccent);
        expect(studio.background, t.background);
        expect(studio.surface, t.surface);
        expect(studio.ink, t.label);
        expect(studio.holiday, t.holiday);
        // Opaque lines and surfaces: Studio draws them over its board.
        expect(studio.line.a, 1);
        expect(studio.surface2.a, 1);
      }
    }
  });

  testWidgets('the route hands Studio the app style and brightness', (
    tester,
  ) async {
    late CalendarStudioConfiguration look;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          style: AppStyle.clear,
          colorScheme: AppColorSchemes.modernDark,
        ),
        home: Builder(
          builder: (context) {
            look = calendarStudioConfigurationFor(
              context,
              base: CalendarStudioConfiguration(projects: _Store()),
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(look.chrome, CalendarStudioChrome.clear);
    expect(look.appearance, CalendarStudioAppearance.dark);
    expect(look.fontFamily, AppTextStyles.qualifiedFamily);
  });
}

class _Store implements CalendarStudioProjectStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
