import 'package:calendar/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_motifs/shared_motifs.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

void main() {
  test('every theme except App colours has a look and a known motif', () {
    for (final theme in CalendarGridTheme.values) {
      final look = CalendarThemeLook.forTheme(theme);
      if (theme == CalendarGridTheme.app) {
        expect(look, isNull);
        continue;
      }
      expect(look, isNotNull, reason: theme.name);
      expect(MotifPainter.kinds, contains(look!.motif), reason: theme.name);
    }
  });

  test('theme text stays readable in light and dark', () {
    for (final theme in CalendarGridTheme.values) {
      final look = CalendarThemeLook.forTheme(theme);
      if (look == null) continue;
      for (final b in Brightness.values) {
        final p = look.of(b);
        final where = '${theme.name} ${b.name}';
        expect(
          _contrast(p.ink, p.paper),
          greaterThanOrEqualTo(7),
          reason: where,
        );
        expect(
          _contrast(p.inkMuted, p.paper),
          greaterThanOrEqualTo(4.5),
          reason: '$where muted',
        );
        expect(
          _contrast(p.holiday, p.paper),
          greaterThanOrEqualTo(3),
          reason: '$where holiday',
        );
        expect(
          _contrast(p.sabbath, p.paper),
          greaterThanOrEqualTo(3),
          reason: '$where sabbath',
        );
        expect(
          _contrast(p.accent, p.paper),
          greaterThanOrEqualTo(3),
          reason: '$where accent',
        );
        expect(
          _contrast(p.onAccent, p.accent),
          greaterThanOrEqualTo(4.5),
          reason: '$where today disc',
        );
        expect(
          _contrast(p.holiday, p.surface),
          greaterThanOrEqualTo(3),
          reason: '$where holiday on a tile',
        );
      }
    }
  });

  test('unknown saved names fall back to App colours', () {
    expect(CalendarGridTheme.fromName('mystery'), CalendarGridTheme.app);
    expect(CalendarGridTheme.fromName(null), CalendarGridTheme.app);
    expect(CalendarGridTheme.fromName('pagoda'), CalendarGridTheme.pagoda);
  });

  testWidgets('CalendarColors follow the scope', (tester) async {
    late CalendarColors app;
    late CalendarColors themed;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const []),
        home: Builder(
          builder: (context) {
            return CalendarThemeScope(
              theme: CalendarGridTheme.pagoda,
              child: Builder(
                builder: (context) {
                  themed = CalendarColors.of(context);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
    final look = CalendarThemeLook.forTheme(CalendarGridTheme.pagoda)!;
    expect(themed.paper, look.light.paper);
    expect(themed.accent, look.light.accent);
    expect(themed.numberFamily, 'Crimson Pro');
    // Without a font scope, numbers keep the app's font.
    const base = TextStyle(fontSize: 14);
    expect(themed.numberStyle(base), base);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            app = CalendarColors.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(app.paper, isNull);
  });
}
