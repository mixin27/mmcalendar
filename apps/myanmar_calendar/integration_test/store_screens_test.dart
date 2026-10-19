// Store and README screenshots: runs the real app on a fresh device with
// demo data and stops on each screen. Run through
// `scripts/capture_store_screens.sh`, never on a device with real data:
// for each `STORE_SHOT <name>` line it prints, the script takes a real
// device screenshot (status bar included) while the test holds still.

import 'package:calendar_studio/calendar_studio.dart';
import 'package:events/events.dart';
import 'package:events/src/domain/services/weekly_timetable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integrations_database/integrations_database.dart'
    show AppDatabase;
import 'package:mmcalendar/config/calendar_studio_configuration.dart';
import 'package:mmcalendar/config/router.dart';
import 'package:mmcalendar/main.dart' as app;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screens', (tester) async {
    await _skipFirstRun();
    app.main();
    await _settle(tester, seconds: 6);
    final ids = await _seedDemoData();
    await _settle(tester);

    Future<void> capture(String name) async {
      // ignore: avoid_print
      print('STORE_SHOT $name');
      await _settle(tester, seconds: 4);
    }

    Future<void> shot(String name, String location) async {
      router.go(location);
      await _settle(tester, seconds: 3);
      await capture(name);
    }

    final today = DateTime.now();
    String day(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    await shot('01_home', RoutePaths.home);
    // Day details, scrolled to the astrology chips and the compass.
    router.go('${RoutePaths.home}/day-details?date=${day(today)}');
    await _settle(tester, seconds: 3);
    final astrology = find.byKey(const ValueKey('day-astro-fact-Mahabote'));
    await tester.scrollUntilVisible(
      astrology,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -420));
    await _settle(tester);
    await capture('02_day_details');
    await shot('03_holidays', RoutePaths.holidaysPath());
    await shot('04_myanmar_month', '${RoutePaths.views}/myanmar-month');

    // The class timetable, with its repeat sheet open.
    router.go(RoutePaths.eventsEdit(ids.classId));
    await _settle(tester, seconds: 3);
    await tester.tap(find.byKey(const ValueKey('event-form-repeat')));
    await _settle(tester, seconds: 2);
    await capture('05_timetable');

    // Calendar Studio: the demo project open in the editor.
    router.go(RoutePaths.studio);
    await _settle(tester, seconds: 4);
    final resume = find.text('Resume');
    if (resume.evaluate().isNotEmpty) {
      await tester.tap(resume.first);
      await _settle(tester, seconds: 6);
    }
    await capture('06_studio');

    await shot('07_grid_styles', '${RoutePaths.settings}/calendar-grid');
    await shot('08_converter', RoutePaths.converter);
  });
}

const _studioName = 'ကျွန်ုပ်၏ ပြက္ခဒိန် ၂၀၂၇';

/// Pumps for [seconds] rather than settling: the app has repeating
/// animations (shimmer, moon) that never settle.
Future<void> _settle(WidgetTester tester, {int seconds = 2}) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A returning user in Myanmar: no consent prompt, onboarding or What's
/// new, the Almanac grid.
Future<void> _skipFirstRun() async {
  final prefs = await SharedPreferences.getInstance();
  final info = await PackageInfo.fromPlatform();
  await prefs.setBool(StorageKeys.onboardingCompleted, true);
  await prefs.setString('whats_new_last_seen', info.version);
  await prefs.setString(StorageKeys.calendarLanguage, 'my');

  final settings = AppDatabase().settingsDao;
  for (final (key, value) in [
    (StorageKeys.appLanguage, 'my'),
    (StorageKeys.calendarLanguage, 'my'),
    (StorageKeys.hasShownConsentDialog, 'true'),
    (StorageKeys.enableAnalytics, 'false'),
    (StorageKeys.enableCrashlytics, 'false'),
    (StorageKeys.calendarGridStyle, 'almanac'),
    (StorageKeys.themeMode, 'light'),
  ]) {
    await settings.setSetting(key, value);
  }
}

/// Events and a Studio project a teacher in Yangon might have, written
/// through the app's own stores (no reminders are scheduled).
Future<({int classId})> _seedDemoData() async {
  final events = GetIt.instance<EventsRepository>();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int days, [int hour = 0, int minute = 0]) =>
      DateTime(today.year, today.month, today.day + days, hour, minute);

  Event event(
    String title,
    DateTime date, {
    DateTime? time,
    RecurrenceRule? rule,
    EventCategory? category,
    String? location,
  }) => Event(
    title: title,
    eventDate: date,
    eventTime: time,
    isAllDay: time == null,
    category: category ?? EventCategory.personal,
    recurrenceRule: rule,
    location: location,
    notifications: const [NotificationSetting(minutesBefore: 15)],
    createdAt: now,
    updatedAt: now,
  );

  Future<int> save(Event e) async {
    final [toSave] = WeeklyTimetable.eventsToSave(e);
    final created = (await events.createEvent(toSave)).fold(
      (failure) => throw StateError(failure.message),
      (created) => created,
    );
    return created.id!;
  }

  final classId = await save(
    event(
      'အင်္ဂလိပ်စာ အွန်လိုင်းအတန်း',
      today,
      time: at(0, 19),
      rule: const RecurrenceRule(
        type: RecurrenceType.weekly,
        daysOfWeek: [DateTime.wednesday, DateTime.thursday],
        occurrenceCount: 24,
      ),
      category: EventCategory.work,
      location: 'Zoom',
    ),
  );
  await save(
    event(
      'စာမေးပွဲ',
      at(9),
      time: at(9, 9),
      rule: RecurrenceRule(
        type: RecurrenceType.dates,
        dates: [at(9), at(16), at(23)],
      ),
      category: EventCategory.work,
    ),
  );
  await save(
    event(
      'ဘုန်းကြီးကျောင်း ဆွမ်းကပ်',
      today,
      time: at(0, 7),
      category: EventCategory.religious,
    ),
  );
  await save(event('အမေ့ မွေးနေ့', at(5), category: EventCategory.family));
  await save(event('ပရောဂျက် ဆွေးနွေးပွဲ', at(3), time: at(3, 14)));

  final template = CalendarStudioTemplates.all.firstWhere(
    (t) => t.id != 'blank' && t.monthly,
    orElse: () => CalendarStudioTemplates.byId('jade-wall'),
  );
  await calendarStudioConfiguration.projects.save(
    template
        .create(
          id: 'store-demo',
          source: CalendarStudioSource(year: today.year + 1),
          now: now,
        )
        .copyWith(name: _studioName),
  );
  return (classId: classId);
}
