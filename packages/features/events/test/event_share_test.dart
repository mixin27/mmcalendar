import 'dart:convert';

import 'package:events/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart' show Language;
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

final _stamp = DateTime(2026, 11, 1);

Event _event({
  String title = "Grandma's birthday",
  DateTime? date,
  DateTime? time,
  String? description,
  String? location,
  RecurrenceRule? rule,
  EventCategory? category,
  int? id,
}) => Event(
  id: id,
  title: title,
  eventDate: date ?? DateTime(1990, 3, 11),
  eventTime: time,
  isAllDay: time == null,
  description: description,
  location: location,
  category: category ?? EventCategory.personal,
  recurrenceRule: rule,
  createdAt: _stamp,
  updatedAt: _stamp,
);

SharedEvent _roundTrip(Event e) =>
    EventShare.fromLink(Uri.parse(EventShare.link(e).toString()))!;

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.build(
    style: AppStyle.clear,
    colorScheme: AppColorSchemes.modernLight,
  ),
  builder: (context, c) =>
      CalendarLanguageScope(language: Language.english, child: c!),
  home: Scaffold(body: child),
);

void main() {
  group('the link', () {
    test('is mmcalendar://add-event with the data in e=', () {
      final link = EventShare.link(_event());
      expect(link.scheme, 'mmcalendar');
      expect(link.host, 'add-event');
      expect(link.queryParameters['e'], isNotEmpty);
    });

    test('an all-day Myanmar yearly event comes back whole', () {
      final shared = _roundTrip(
        _event(
          description: 'Bring flowers',
          location: 'Mandalay',
          rule: const RecurrenceRule(type: RecurrenceType.myanmarYearly),
          category: EventCategory.personal.copyWith(name: 'Family'),
        ),
      );
      expect(shared.title, "Grandma's birthday");
      expect(shared.date, DateTime(1990, 3, 11));
      expect(shared.allDay, isTrue);
      expect(shared.description, 'Bring flowers');
      expect(shared.location, 'Mandalay');
      expect(shared.categoryName, 'Family');
      expect(shared.recurrence!.type, RecurrenceType.myanmarYearly);
      expect(shared.recurrence!.interval, 1);
    });

    test('a timed weekly event keeps its days, interval and end', () {
      final shared = _roundTrip(
        _event(
          title: 'ဘုရားဝတ်ပြု',
          date: DateTime(2026, 11, 13),
          time: DateTime(2026, 11, 13, 18, 30),
          rule: RecurrenceRule(
            type: RecurrenceType.weekly,
            interval: 2,
            daysOfWeek: const [1, 5],
            endDate: DateTime(2027, 3, 31),
            exceptions: [DateTime(2026, 12, 25)],
          ),
        ),
      );
      expect(shared.title, 'ဘုရားဝတ်ပြု');
      expect(shared.time, DateTime(2026, 11, 13, 18, 30));
      final rule = shared.recurrence!;
      expect(rule.type, RecurrenceType.weekly);
      expect(rule.interval, 2);
      expect(rule.daysOfWeek, [1, 5]);
      expect(rule.endDate, DateTime(2027, 3, 31));
      expect(rule.exceptions, [DateTime(2026, 12, 25)]);
    });

    test('picked dates and a count come back', () {
      final shared = _roundTrip(
        _event(
          date: DateTime(2026, 12, 1),
          rule: RecurrenceRule(
            type: RecurrenceType.dates,
            dates: [DateTime(2026, 12, 1), DateTime(2027, 1, 5)],
          ),
        ),
      );
      expect(shared.recurrence!.dates, [
        DateTime(2026, 12, 1),
        DateTime(2027, 1, 5),
      ]);
      final counted = _roundTrip(
        _event(
          rule: const RecurrenceRule(
            type: RecurrenceType.monthly,
            occurrenceCount: 6,
          ),
        ),
      );
      expect(counted.recurrence!.occurrenceCount, 6);
    });

    test('anything else is not an event', () {
      expect(EventShare.decode(null), isNull);
      expect(EventShare.decode(''), isNull);
      expect(EventShare.decode('not base64 !!'), isNull);
      expect(EventShare.fromLink(Uri.parse('mmcalendar://event/12')), isNull);
      expect(
        EventShare.fromLink(Uri.parse('https://example.com/?e=x')),
        isNull,
      );
      final data = EventShare.encode(_event());
      // Cut short in a chat.
      expect(EventShare.decode(data.substring(0, data.length ~/ 2)), isNull);
    });

    test('a newer format or a bad date is not read', () {
      expect(
        EventShare.decode(_raw('{"v":2,"t":"x","d":"2026-01-01"}')),
        isNull,
      );
      expect(
        EventShare.decode(_raw('{"v":1,"t":"x","d":"2026-02-31"}')),
        isNull,
      );
      expect(
        EventShare.decode(_raw('{"v":1,"t":" ","d":"2026-02-01"}')),
        isNull,
      );
      expect(
        EventShare.decode(
          _raw('{"v":1,"t":"x","d":"2026-02-01","h":"25:00"}'),
        )!.allDay,
        isTrue,
      );
    });

    test('the QR code drops long notes, and gives up on a huge event', () {
      expect(EventShare.qrLink(_event())!.withoutNotes, isFalse);
      final long = _event(description: 'x' * 1500);
      final qr = EventShare.qrLink(long)!;
      expect(qr.withoutNotes, isTrue);
      expect(EventShare.fromLink(qr.link)!.description, isNull);
      final huge = _event(
        rule: RecurrenceRule(
          type: RecurrenceType.dates,
          dates: [
            for (var i = 0; i < 200; i++)
              DateTime(2027, 1, 1).add(Duration(days: i)),
          ],
        ),
      );
      expect(EventShare.qrLink(huge), isNull);
    });

    test("toEvent uses the receiver's category of the same name", () {
      final shared = _roundTrip(
        _event(category: EventCategory.personal.copyWith(name: 'Work')),
      );
      final work = EventCategory.work;
      expect(
        shared
            .toEvent(category: EventCategory.personal, categories: [work])
            .category,
        work,
      );
      final other = _roundTrip(
        _event(category: EventCategory.personal.copyWith(name: 'Mine')),
      );
      expect(
        other.toEvent(category: EventCategory.personal).category.name,
        'Personal',
      );
    });
  });

  group('shared event page', () {
    testWidgets('a bad link says it cannot be read', (tester) async {
      await tester.pumpWidget(_app(const SharedEventPage(data: 'nope')));
      await tester.pumpAndSettle();
      expect(find.text("Can't read this event"), findsOneWidget);
      expect(find.byKey(const ValueKey('shared-event-add')), findsNothing);
    });

    testWidgets('shows the event and adds it', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(390, 1200);
      addTearDown(tester.view.reset);
      final data = EventShare.encode(
        _event(
          location: 'Mandalay',
          rule: const RecurrenceRule(type: RecurrenceType.myanmarYearly),
        ),
      );
      Event? saved;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => SharedEventPage(
              data: data,
              categories: () async => [EventCategory.personal],
              save: (e) async {
                saved = e;
                return 42;
              },
            ),
          ),
          GoRoute(
            path: '/events/:id/detail',
            builder: (_, s) => Text('detail ${s.pathParameters['id']}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.build(
            style: AppStyle.clear,
            colorScheme: AppColorSchemes.modernLight,
          ),
          builder: (context, c) =>
              CalendarLanguageScope(language: Language.english, child: c!),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Grandma's birthday"), findsOneWidget);
      expect(find.text('Mandalay'), findsOneWidget);
      expect(find.textContaining('Tabaung'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('shared-event-add')));
      await tester.pumpAndSettle();
      expect(saved!.title, "Grandma's birthday");
      expect(saved!.recurrenceRule!.type, RecurrenceType.myanmarYearly);
      expect(saved!.category.name, 'Personal');
      expect(find.text('detail 42'), findsOneWidget);
    });
  });

  group('share sheet', () {
    testWidgets('shows a QR code and the share rows', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(390, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(EventShareView(event: _event(id: 3))));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('event-share-qr')), findsOneWidget);
      expect(find.text('Share link'), findsOneWidget);
      expect(find.text('Copy link'), findsOneWidget);
      expect(find.byKey(const ValueKey('event-share-file')), findsOneWidget);
    });

    testWidgets('a huge event has no QR code', (tester) async {
      final huge = _event(
        rule: RecurrenceRule(
          type: RecurrenceType.dates,
          dates: [
            for (var i = 0; i < 200; i++)
              DateTime(2027, 1, 1).add(Duration(days: i)),
          ],
        ),
      );
      await tester.pumpWidget(_app(EventShareView(event: huge)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('event-share-qr')), findsNothing);
      expect(
        find.byKey(const ValueKey('event-share-too-large')),
        findsOneWidget,
      );
    });
  });
}

String _raw(String json) =>
    base64Url.encode(utf8.encode(json)).replaceAll('=', '');
