import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings/settings.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'settings_test_harness.dart';

void main() {
  for (final style in [AppStyle.clear, AppStyle.material]) {
    group('${style.name} style', () {
      testWidgets('an accent previews and applies', (tester) async {
        final harness = await SettingsHarness.pump(
          tester,
          style: style,
          page: const SettingsCustomColorsPage(),
        );
        expect(find.text('Custom colours'), findsWidgets);
        // Jade, one of the swatches.
        await tester.tap(find.byKey(const ValueKey('custom-accent-9')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('custom-colors-apply')));
        await tester.pumpAndSettle();
        final state = harness.bloc.state as SettingsLoaded;
        expect(state.settings.themePreset, 'custom');
        expect(state.settings.customColors?.seed, const Color(0xFF0E6B5C));
        expect(state.settings.customColors?.basePreset, 'modern');
        expect(tester.takeException(), isNull);
      });

      testWidgets('advanced slots open the picker and keep the choice', (
        tester,
      ) async {
        await SettingsHarness.pump(
          tester,
          style: style,
          page: const SettingsCustomColorsPage(),
        );
        final advanced = find.byKey(const ValueKey('custom-colors-advanced'));
        await tester.ensureVisible(advanced);
        await tester.tap(advanced);
        await tester.pumpAndSettle();
        final surface = find.byKey(const ValueKey('custom-slot-surface'));
        await tester.ensureVisible(surface);
        await tester.pumpAndSettle();
        await tester.tap(surface);
        await tester.pumpAndSettle();
        expect(find.text('Choose a colour'), findsOneWidget);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(find.text('Choose a colour'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
