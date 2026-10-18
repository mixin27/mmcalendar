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

      testWidgets('Settings reads in Myanmar', (tester) async {
        await SettingsHarness.pump(
          tester,
          style: style,
          locale: const Locale('my'),
          page: const SettingsPage(),
        );
        expect(find.text('ပြက္ခဒိန် စတူဒီယို'), findsOneWidget);
        expect(find.text('ဒီဇိုင်းဆွဲ၍ ပုံနှိပ်ရန်'), findsOneWidget);
        for (final english in ['Calendar Studio', 'Light', 'Dark', 'System']) {
          expect(find.text(english), findsNothing, reason: english);
        }

        await SettingsHarness.pump(
          tester,
          style: style,
          locale: const Locale('my'),
          page: const SettingsDisplayPreferencesPage(),
        );
        expect(find.text('ပြက္ခဒိန်တွင် ပြရန်'), findsOneWidget);
        expect(find.text('ရက်စွဲများ'), findsOneWidget);
      });

      testWidgets('Display toggles write the preference', (tester) async {
        final harness = await SettingsHarness.pump(
          tester,
          style: style,
          page: const SettingsDisplayPreferencesPage(),
        );
        expect(find.text('Calendar grid'), findsOneWidget);
        expect(find.text('Detailed'), findsOneWidget);
        // A chosen theme shows next to the layout.
        harness.bloc.add(
          const ChangeCalendarGridTheme(CalendarGridTheme.pagoda),
        );
        await tester.pumpAndSettle();
        expect(find.text('Detailed · Pagoda'), findsOneWidget);
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

      testWidgets('Calendar grid previews every style and saves the pick', (
        tester,
      ) async {
        final harness = await SettingsHarness.pump(
          tester,
          style: style,
          page: const SettingsCalendarGridPage(),
        );
        for (final grid in CalendarGridStyle.values) {
          expect(
            find.byKey(
              ValueKey('grid-style-${grid.name}'),
              skipOffstage: false,
            ),
            findsOneWidget,
          );
        }
        final moon = find.byKey(const ValueKey('grid-style-moonStrip'));
        await tester.ensureVisible(moon);
        await tester.pumpAndSettle();
        await tester.tap(moon);
        await tester.pumpAndSettle();
        expect(harness.repository.gridStyle, CalendarGridStyle.moonStrip);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Calendar grid themes preview, save and switch the motif', (
        tester,
      ) async {
        final harness = await SettingsHarness.pump(
          tester,
          style: style,
          page: const SettingsCalendarGridPage(),
        );
        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();
        for (final theme in CalendarGridTheme.values) {
          final choice = find.byKey(ValueKey('grid-theme-${theme.name}'));
          await tester.ensureVisible(choice);
          await tester.pumpAndSettle();
          await tester.tap(choice);
          await tester.pumpAndSettle();
          expect(harness.repository.gridTheme, theme);
        }
        final motif = find.byKey(const ValueKey('grid-theme-motif'));
        await tester.ensureVisible(motif);
        await tester.pumpAndSettle();
        await tester.tap(motif);
        await tester.pumpAndSettle();
        expect(
          harness.repository.preferences[StorageKeys.calendarGridMotif],
          isFalse,
        );
        expect(tester.takeException(), isNull);
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
