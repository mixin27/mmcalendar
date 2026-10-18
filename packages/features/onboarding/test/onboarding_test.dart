import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:onboarding/onboarding.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

class _Recorder {
  final calls = <String>[];
  bool? analytics;
  bool? crashReports;
  var finished = 0;

  OnboardingActions get actions => OnboardingActions(
    setAppLanguage: (c) => calls.add('app:$c'),
    setCalendarLanguage: (l) => calls.add('calendar:${l.code}'),
    setThemeMode: (m) => calls.add('mode:${m.name}'),
    setThemePreset: (p) => calls.add('preset:$p'),
    requestNotifications: () async {
      calls.add('notifications');
      return true;
    },
    finish: ({required analytics, required crashReports}) async {
      this.analytics = analytics;
      this.crashReports = crashReports;
      finished++;
    },
  );
}

Future<_Recorder> _pump(WidgetTester tester, AppStyle style) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 900);
  addTearDown(tester.view.reset);
  final r = _Recorder();
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.build(
        style: style,
        colorScheme: AppColorSchemes.modernLight,
      ),
      builder: (context, child) =>
          CalendarLanguageScope(language: Language.english, child: child!),
      home: OnboardingPage(
        settings: const OnboardingSettings(
          appLanguage: 'en',
          calendarLanguage: Language.myanmar,
          themeMode: ThemeMode.system,
          themePreset: 'modern',
        ),
        actions: r.actions,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return r;
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding-next')));
  await tester.pumpAndSettle();
}

void main() {
  for (final style in [AppStyle.clear, AppStyle.material]) {
    group('${style.name} style', () {
      testWidgets('the tour pages through to setup', (tester) async {
        await _pump(tester, style);
        expect(find.text('Welcome to Myanmar Calendar'), findsOneWidget);
        await _next(tester);
        expect(find.text('Two calendars in one'), findsOneWidget);
        await _next(tester);
        await _next(tester);
        expect(find.text('Make it yours'), findsOneWidget);
        expect(find.text('Set up the app'), findsOneWidget);
        await _next(tester);
        expect(find.text('Choose your languages'), findsOneWidget);
        expect(find.text('STEP 1 OF 4'), findsOneWidget);
      });

      testWidgets('Skip goes to setup, not past it', (tester) async {
        await _pump(tester, style);
        await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
        await tester.pumpAndSettle();
        expect(find.text('Choose your languages'), findsOneWidget);
        expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
      });

      testWidgets('setup choices reach settings; privacy starts off', (
        tester,
      ) async {
        final r = await _pump(tester, style);
        await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('onboarding-app-language-my')),
        );
        await tester.tap(
          find.byKey(const ValueKey('onboarding-calendar-language-en')),
        );
        await _next(tester);

        await tester.tap(find.byKey(const ValueKey('onboarding-theme-dark')));
        await tester.tap(
          find.byKey(const ValueKey('onboarding-preset-forest')),
        );
        await _next(tester);

        expect(find.text('Your calendar stays on your phone'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('onboarding-crash-reports')),
        );
        await tester.pumpAndSettle();
        await _next(tester);

        expect(find.text('Reminders when they matter'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('onboarding-allow-notifications')),
        );
        await tester.pumpAndSettle();

        expect(find.text("You're all set"), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pumpAndSettle();

        expect(r.calls, [
          'app:my',
          'calendar:en',
          'mode:dark',
          'preset:forest',
          'notifications',
        ]);
        expect(r.analytics, isFalse);
        expect(r.crashReports, isTrue);
        expect(r.finished, 1);
      });

      testWidgets('Not now skips the notification prompt', (tester) async {
        final r = await _pump(tester, style);
        await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
        await tester.pumpAndSettle();
        for (var i = 0; i < 3; i++) {
          await _next(tester);
        }
        await tester.tap(find.byKey(const ValueKey('onboarding-not-now')));
        await tester.pumpAndSettle();
        expect(find.text("You're all set"), findsOneWidget);
        expect(r.calls, isNot(contains('notifications')));
      });
    });
  }

  group('store', () {
    Future<OnboardingStore> store(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      return OnboardingStore(await SharedPreferences.getInstance());
    }

    test('a new install needs onboarding', () async {
      final s = await store({});
      await s.migrate(madeConsentChoice: false);
      expect(s.completed, isFalse);
    });

    test('people who made the consent choice skip it', () async {
      final s = await store({});
      await s.migrate(madeConsentChoice: true);
      expect(s.completed, isTrue);
    });

    test('people who saw the old carousel skip it', () async {
      final s = await store({
        'promo_seen_campaigns': ['onboarding_v1'],
      });
      await s.migrate(madeConsentChoice: false);
      expect(s.completed, isTrue);
    });

    test('complete and reset', () async {
      final s = await store({});
      await s.complete();
      expect(s.completed, isTrue);
      await s.reset();
      expect(s.completed, isFalse);
    });
  });
}
