import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:mmcalendar/presentation/pages/backup_page.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

void main() {
  late AppDatabase db;
  final saved = <String, Uint8List>{};
  Uint8List? toPick;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    saved.clear();
    await db
        .into(db.calendarEvents)
        .insert(
          CalendarEventsCompanion.insert(
            title: 'Dentist',
            eventDate: DateTime(2026, 11, 20),
            createdAt: DateTime(2026, 11, 1),
            updatedAt: DateTime(2026, 11, 1),
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 1200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.build(
          style: AppStyle.clear,
          colorScheme: AppColorSchemes.modernLight,
        ),
        builder: (context, child) =>
            CalendarLanguageScope(language: Language.english, child: child!),
        home: BackupPage(
          database: db,
          today: DateTime(2026, 11, 5),
          saveFile: (bytes, name, _) async => saved[name] = bytes,
          pickFile: () async => toPick,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    // The work runs on the database; the spinner never settles meanwhile.
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('back up, lose an event, restore it', (tester) async {
    await pump(tester);
    await tapAndWait(tester, find.byKey(const ValueKey('backup-now')));
    final backup = saved['myanmar-calendar-2026-11-05.mmcbackup'];
    expect(backup, isNotNull);

    await tester.runAsync(() => db.delete(db.calendarEvents).go());
    toPick = backup;
    await tapAndWait(tester, find.byKey(const ValueKey('backup-restore')));
    expect(find.text('Restore backup'), findsOneWidget);
    await tapAndWait(tester, find.byKey(const ValueKey('backup-merge')));
    expect(find.text('Backup restored'), findsOneWidget);
    final events = await tester.runAsync(
      () => db.select(db.calendarEvents).get(),
    );
    expect(events!.single.title, 'Dentist');
  });

  testWidgets('events export as an .ics file', (tester) async {
    await pump(tester);
    await tapAndWait(tester, find.byKey(const ValueKey('backup-ics')));
    final ics = utf8.decode(saved['myanmar-calendar-events-2026-11-05.ics']!);
    expect(ics, contains('SUMMARY:Dentist'));
  });

  testWidgets('another file says it is not a backup', (tester) async {
    await pump(tester);
    toPick = Uint8List.fromList(utf8.encode('hello'));
    await tapAndWait(tester, find.byKey(const ValueKey('backup-restore')));
    expect(
      find.text("This file isn't a Myanmar Calendar backup."),
      findsOneWidget,
    );
  });
}
