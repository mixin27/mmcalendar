import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:settings/settings.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'settings_test_harness.dart';

void main() {
  for (final style in [AppStyle.clear, AppStyle.material]) {
    group('${style.name} style', () {
      testWidgets('Settings lists every section and resets after confirming', (
        tester,
      ) async {
        final harness = await SettingsHarness.pump(
          tester,
          style: style,
          page: const SettingsPage(),
        );
        for (final title in [
          'Appearance',
          'Language',
          'Calendar Configuration',
          'Calendar Studio',
          'Display Preferences',
          'Privacy & Data',
          'App Updates',
          'About',
        ]) {
          expect(find.text(title), findsOneWidget, reason: title);
        }

        await tester.scrollUntilVisible(
          find.text('Reset All Settings'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Reset All Settings'));
        await tester.pumpAndSettle();
        expect(
          style == AppStyle.clear
              ? find.byType(CupertinoAlertDialog)
              : find.byType(AlertDialog),
          findsOneWidget,
        );
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        expect(harness.repository.resets, 1);
      });

      testWidgets('Display toggles write the preference', (tester) async {
        final harness = await SettingsHarness.pump(
          tester,
          style: style,
          page: const SettingsDisplayPreferencesPage(),
        );
        expect(find.text('Calendar grid'), findsOneWidget);
        expect(find.text('Detailed'), findsOneWidget);
        await tester.tap(find.text('Show Holidays'));
        await tester.pumpAndSettle();
        expect(
          harness.repository.preferences[StorageKeys.showHolidays],
          isFalse,
        );
        expect(
          find.byType(style == AppStyle.clear ? CupertinoSwitch : Switch),
          findsWidgets,
        );
      });

      testWidgets('Appearance switches app style, mode and preset', (
        tester,
      ) async {
        final harness = await SettingsHarness.pump(
          tester,
          style: style,
          page: const SettingsAppearancePage(),
        );
        await tester.tap(find.text('Material'));
        await tester.pumpAndSettle();
        expect(harness.repository.appStyle, AppStyle.material);

        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();
        expect(harness.repository.themeMode, ThemeMode.dark);

        await tester.tap(find.text('Ocean Blue'));
        await tester.pumpAndSettle();
        expect(harness.repository.preset, 'ocean');
      });

      testWidgets('Language is a checkmark list', (tester) async {
        final harness = await SettingsHarness.pump(
          tester,
          style: style,
          page: const SettingsLanguagePage(),
        );
        await tester.tap(find.text('English').last);
        await tester.pumpAndSettle();
        expect(harness.repository.calendarLanguage, Language.english);
      });
    });
  }

  tearDown(() => GetIt.instance.reset());
}
