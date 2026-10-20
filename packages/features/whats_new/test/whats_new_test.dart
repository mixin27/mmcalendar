import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';
import 'package:whats_new/whats_new.dart';

Future<WhatsNewStore> _store(
  Map<String, Object> values, {
  String current = '2.3.0',
}) async {
  SharedPreferences.setMockInitialValues(values);
  return WhatsNewStore(
    await SharedPreferences.getInstance(),
    currentVersion: current,
  );
}

Widget _app(AppStyle style, Widget home) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.build(style: style, colorScheme: AppColorSchemes.modernLight),
  home: home,
);

void main() {
  group('store', () {
    test('versions compare numerically and ignore build numbers', () {
      expect(WhatsNewStore.compareVersions('2.2.10', '2.2.9'), 1);
      expect(WhatsNewStore.compareVersions('2.3.0+230', '2.3.0'), 0);
      expect(WhatsNewStore.compareVersions('2.2', '2.2.1'), -1);
    });

    test(
      'an update from the old promo version shows everything since, newest first',
      () async {
        final store = await _store({WhatsNewStore.legacyKey: '2.2.0'});
        expect(store.pending().map((p) => p.item.id), [
          'studio',
          'gridThemes',
          'timetables',
          'holidays',
          'widgets',
          'customColors',
          'newAppIcons',
          'appIcons',
        ]);
        await store.markSeen();
        expect(store.pending(), isEmpty);
        expect(store.lastSeen, '2.3.0');
      },
    );

    test('a first run shows nothing', () async {
      expect((await _store({})).pending(), isEmpty);
    });

    test('history stops at the installed version', () async {
      final store = await _store({}, current: '2.2.3');
      expect(store.history().map((r) => r.version), ['2.2.1']);
    });
  });

  for (final style in [AppStyle.clear, AppStyle.material]) {
    group('${style.name} style', () {
      testWidgets('the sheet pages through features and opens one', (
        tester,
      ) async {
        final store = await _store({WhatsNewStore.lastSeenKey: '2.2.0'});
        String? opened;
        var seeAll = 0;
        await tester.pumpWidget(
          _app(
            style,
            Builder(
              builder: (context) => TextButton(
                onPressed: () => showWhatsNewSheet(
                  context,
                  items: store.pending(),
                  currentVersion: store.currentVersion,
                  onOpen: (route) => opened = route,
                  onSeeAll: () => seeAll++,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('New in 2.3'), findsOneWidget);
        expect(find.text('1 of 8'), findsOneWidget);
        expect(find.text('Calendar Studio'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('whats-new-next')));
        await tester.pumpAndSettle();
        expect(find.text('2 of 8'), findsOneWidget);
        expect(find.text('Calendar layouts and themes'), findsOneWidget);

        // The last page comes from an earlier version.
        for (var i = 0; i < 6; i++) {
          await tester.tap(find.byKey(const ValueKey('whats-new-next')));
          await tester.pumpAndSettle();
        }
        expect(find.text('From 2.2.1'), findsOneWidget);
        expect(find.text('See all updates'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('whats-new-try')));
        await tester.pumpAndSettle();
        expect(opened, '/settings/theme');
        expect(find.text('App icons'), findsNothing);
        expect(seeAll, 0);
      });

      testWidgets('history lists every release with its features', (
        tester,
      ) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(390, 2400);
        addTearDown(tester.view.reset);
        final store = await _store({});
        String? opened;
        await tester.pumpWidget(
          _app(
            style,
            WhatsNewPage(
              releases: store.history(),
              currentVersion: store.currentVersion,
              onOpen: (r) => opened = r,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(RegExp('this update', caseSensitive: false)),
          findsOneWidget,
        );
        expect(find.text('Calendar Studio'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('whats-new-holidays')));
        expect(opened, '/views/holidays');
      });
    });
  }
}
