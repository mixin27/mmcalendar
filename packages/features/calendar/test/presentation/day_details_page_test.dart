import 'dart:async';

import 'package:calendar/calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart' as mm;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart'
    show Language, MyanmarCalendar;
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

class _Analytics implements AnalyticsPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _Display implements DisplayPreferencesPort {
  @override
  Future<bool> getShowShanCalendar() async => false;
  @override
  Stream<bool> watchShowShanCalendar() => Stream.value(false);
}

class _Actions implements EventActionsPort {
  final created = <DateTime?>[];
  final opened = <int>[];

  @override
  Future<void> openCreateEvent(
    BuildContext context, {
    DateTime? initialDate,
  }) async => created.add(initialDate);

  @override
  Future<void> openEventDetail(
    BuildContext context, {
    required int eventId,
    DateTime? occurrenceDate,
  }) async => opened.add(eventId);
}

class _Markers implements EventMarkersPort {
  final toggled = <(int, bool)>[];

  @override
  Stream<List<CalendarEventItem>> watchEventsForDate(DateTime date) =>
      Stream.value([
        if (date.day == 22)
          CalendarEventItem(
            id: 7,
            title: 'Grandma’s birthday',
            eventDate: date,
            isAllDay: true,
            category: const CalendarEventCategory(
              name: 'Family',
              iconName: 'family_restroom',
              colorCode: 0xFFE0457B,
            ),
            isRecurring: true,
          ),
      ]);

  @override
  Future<void> toggleEventCompletion({
    required int eventId,
    required bool isCompleted,
    bool isRecurring = false,
    DateTime? occurrenceDate,
  }) async => toggled.add((eventId, isCompleted));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Actions actions;
  late _Markers markers;

  Future<void> pump(WidgetTester tester, AppStyle style) async {
    final getIt = GetIt.instance;
    await getIt.reset();
    actions = _Actions();
    markers = _Markers();
    getIt
      ..registerSingleton<AnalyticsPort>(_Analytics())
      ..registerSingleton<DisplayPreferencesPort>(_Display())
      ..registerSingleton<EventActionsPort>(actions)
      ..registerSingleton<EventMarkersPort>(markers);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 2600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          style: style,
          colorScheme: AppColorSchemes.modernLight,
        ),
        home: DayDetailsPage(date: DateTime(2026, 10, 22)),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final style in [AppStyle.clear, AppStyle.material]) {
    group('${style.name} style', () {
      testWidgets('shows every section of the day', (tester) async {
        await pump(tester, style);
        expect(
          find.text(
            CalendarFormat(
              MyanmarCalendar.currentLanguage,
            ).shortDate(DateTime(2026, 10, 22)),
          ),
          findsWidgets,
        );
        for (final label in [
          'Buddhist Calendar',
          'Human nakhat',
          'AI Horoscope Prompt',
          'Grandma’s birthday',
          'Add event',
        ]) {
          // Clear writes group labels in capitals.
          expect(
            find.textContaining(RegExp(label, caseSensitive: false)),
            findsWidgets,
            reason: label,
          );
        }
        expect(find.byType(MoonGlyph), findsOneWidget);
      });

      testWidgets('events can be completed, opened and added', (tester) async {
        await pump(tester, style);
        await tester.tap(find.bySemanticsLabel('Mark complete'));
        await tester.pump();
        expect(markers.toggled, [(7, true)]);

        await tester.tap(find.text('Grandma’s birthday'));
        await tester.pump();
        expect(actions.opened, [7]);

        await tester.tap(find.text('Add event'));
        await tester.pump();
        expect(actions.created, [DateTime(2026, 10, 22)]);
      });

      testWidgets('the bar steps to the next day', (tester) async {
        await pump(tester, style);
        await tester.tap(find.byTooltip('Next Day'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            CalendarFormat(
              MyanmarCalendar.currentLanguage,
            ).shortDate(DateTime(2026, 10, 23)),
          ),
          findsWidgets,
        );
        expect(find.text('Grandma’s birthday'), findsNothing);
      });

      testWidgets('the AI prompt opens in a sheet with copy and share', (
        tester,
      ) async {
        await pump(tester, style);
        await tester.tap(find.text('AI Horoscope Prompt'));
        await tester.pumpAndSettle();
        expect(find.text('Copy Prompt'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);

        // Horoscope, fortune-telling or divination.
        expect(find.textContaining('horoscope reading'), findsOneWidget);
        await tester.tap(find.text('Fortune'));
        await tester.pumpAndSettle();
        expect(find.textContaining('fortune-telling reading'), findsOneWidget);
      });

      testWidgets('coming up counts to the next moons and Sabbath', (
        tester,
      ) async {
        await pump(tester, style);
        expect(
          find.byKey(const ValueKey('day-details-moon-countdown')),
          findsOneWidget,
        );
        // 22 October 2026: full moon and Sabbath on the 26th, new moon on
        // 9 November.
        expect(find.text('in 4 days'), findsNWidgets(2));
        expect(find.text('in 18 days'), findsOneWidget);
        expect(find.byType(mm.MoonGlyph), findsNWidgets(3));
      });

      testWidgets('astrology shows the day\'s marks as chips', (tester) async {
        await pump(tester, style);
        // 22 October 2026: Yatyaza and Thamanyo, no Sabbath or Pyathada.
        for (final key in ['Yatyaza', 'Thamanyo']) {
          expect(find.byKey(ValueKey('day-astro-$key')), findsOneWidget);
        }
        expect(find.byKey(const ValueKey('day-astro-Sabbath')), findsNothing);
        expect(find.byKey(const ValueKey('day-astro-Pyathada')), findsNothing);
        // The mark is its own label: no "Yatyaza: Yatyaza" row.
        expect(find.text('Yatyaza'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('day-astro-fact-Mahabote')),
            matching: find.text('Born in Marana'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('astrology labels follow the calendar language', (
        tester,
      ) async {
        final before = MyanmarCalendar.currentLanguage;
        MyanmarCalendar.setLanguage(Language.myanmar);
        addTearDown(() => MyanmarCalendar.setLanguage(before));
        await pump(tester, style);
        // Said the way people say them.
        for (final phrase in [
          'ရက်ရာဇာ',
          'သမားညို နေ့',
          'မရဏဖွား',
          'လူ နက္ခတ်',
          'ဘဒြ နှစ်',
          'နဂါးခေါင်း အရှေ့ဘက်သို့ လှည့်',
        ]) {
          expect(find.text(phrase), findsOneWidget, reason: phrase);
        }
      });

      testWidgets('the dragon\'s head shows as a compass', (tester) async {
        await pump(tester, style);
        expect(
          find.byKey(const ValueKey('day-details-nagahle-compass')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel(RegExp('East')), findsWidgets);
      });
    });
  }

  tearDown(() => GetIt.instance.reset());
}
