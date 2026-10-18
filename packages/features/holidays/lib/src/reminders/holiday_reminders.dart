import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../catalog/holiday_catalog.dart';
import '../domain/holiday_year.dart';
import '../presentation/holiday_text.dart';
import '../presentation/holiday_widgets.dart';

/// When holiday reminders come.
enum HolidayReminderTime {
  evening,
  morning,
  both;

  bool get hasEvening => this != HolidayReminderTime.morning;
  bool get hasMorning => this != HolidayReminderTime.evening;
}

/// One reminder to schedule.
@immutable
class PlannedHolidayReminder {
  const PlannedHolidayReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String payload;
}

/// Which holidays the user follows and when to be reminded, plus scheduling
/// the reminders as local notifications for the next [horizonDays] days.
///
/// Holiday notifications have payloads starting with [payloadPrefix] and
/// ids from [idBase] up, so event scheduling can leave them alone.
class HolidayReminders extends ChangeNotifier {
  HolidayReminders({
    required SharedPreferences preferences,
    required Future<bool> Function() requestPermission,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _prefs = preferences,
       _requestPermission = requestPermission,
       _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const payloadPrefix = 'holiday_';
  static const idBase = 1500000000;
  static const horizonDays = 60;
  static const eveningHour = 18;
  static const morningHour = 8;

  static const _followedKey = 'holiday_reminders_followed';
  static const _allPublicKey = 'holiday_reminders_all_public';
  static const _timeKey = 'holiday_reminders_time';

  final SharedPreferences _prefs;
  final Future<bool> Function() _requestPermission;
  final FlutterLocalNotificationsPlugin _plugin;

  Language _calendarLanguage = Language.myanmar;
  Locale _appLocale = const Locale('en');

  Set<String> get followed => {...?_prefs.getStringList(_followedKey)};
  bool get allPublic => _prefs.getBool(_allPublicKey) ?? false;
  HolidayReminderTime get time => HolidayReminderTime.values.firstWhere(
    (t) => t.name == _prefs.getString(_timeKey),
    orElse: () => HolidayReminderTime.evening,
  );

  /// Whether [entry] gets reminders, on its own or as a public holiday.
  bool isOn(HolidayEntry entry) =>
      followed.contains(entry.id) || (allPublic && entry.officeClosed);

  /// Whether [entry] is covered by following all public holidays.
  bool coveredByAllPublic(HolidayEntry entry) =>
      allPublic && entry.officeClosed;

  /// Turns reminders for [entry] on or off. Returns false when the user
  /// refused notification permission (the choice is kept either way).
  Future<bool> follow(HolidayEntry entry, bool on) async {
    final ids = followed;
    on ? ids.add(entry.id) : ids.remove(entry.id);
    await _prefs.setStringList(_followedKey, ids.toList()..sort());
    return _changed(asking: on);
  }

  Future<bool> setAllPublic(bool on) async {
    await _prefs.setBool(_allPublicKey, on);
    return _changed(asking: on);
  }

  Future<void> setTime(HolidayReminderTime value) async {
    await _prefs.setString(_timeKey, value.name);
    await _changed(asking: false);
  }

  /// Sets the languages reminders are written in and reschedules.
  Future<void> configure({
    required Language calendarLanguage,
    required Locale appLocale,
  }) async {
    _calendarLanguage = calendarLanguage;
    _appLocale = appLocale;
    await reschedule();
  }

  Future<bool> _changed({required bool asking}) async {
    notifyListeners();
    var granted = true;
    if (asking) granted = await _requestPermission();
    await reschedule();
    return granted;
  }

  /// Replaces every scheduled holiday reminder with the current plan.
  Future<void> reschedule({DateTime? now}) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.payload?.startsWith(payloadPrefix) ?? false) {
          await _plugin.cancel(id: p.id);
        }
      }
      final reminders = plan(
        now: now ?? DateTime.now(),
        followed: followed,
        allPublic: allPublic,
        time: time,
        calendarLanguage: _calendarLanguage,
        l10n: lookupAppLocalizations(_appLocale),
      );
      for (final r in reminders) {
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.title,
          body: r.body,
          scheduledDate: tz.TZDateTime.from(r.at, tz.local),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: r.payload,
        );
      }
    } catch (e) {
      // No plugin in tests, or notifications unavailable: nothing to do.
      debugPrint('Holiday reminders not scheduled: $e');
    }
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'holidays_channel',
      'Holiday reminders',
      channelDescription: 'Reminders for holidays you follow',
      importance: Importance.defaultImportance,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  /// The reminders for holidays starting within [horizonDays] of [now].
  static List<PlannedHolidayReminder> plan({
    required DateTime now,
    required Set<String> followed,
    required bool allPublic,
    required HolidayReminderTime time,
    required Language calendarLanguage,
    required AppLocalizations l10n,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final format = CalendarFormat(calendarLanguage);
    final out = <PlannedHolidayReminder>[];
    for (final o in HolidayYears.between(
      today,
      today.add(const Duration(days: horizonDays)),
      calendarLanguage,
    )) {
      final e = o.entry;
      if (!followed.contains(e.id) && !(allPublic && e.officeClosed)) continue;
      final name = e.title(l10n);
      final dates = format.holidayRange(o);
      final body = e.officeClosed
          ? l10n.holidayReminderBodyPublic(dates)
          : dates;
      final index = HolidayCatalog.all.indexOf(e);
      final day = o.start.difference(DateTime(1970)).inDays % 100000;
      int id(int slot) =>
          idBase + day * 100 + (index < 0 ? 49 : index) * 2 + slot;
      final evening = DateTime(
        o.start.year,
        o.start.month,
        o.start.day - 1,
        eveningHour,
      );
      final morning = DateTime(
        o.start.year,
        o.start.month,
        o.start.day,
        morningHour,
      );
      if (time.hasEvening && evening.isAfter(now)) {
        out.add(
          PlannedHolidayReminder(
            id: id(0),
            at: evening,
            title: l10n.holidayReminderTomorrow(name),
            body: body,
            payload: '$payloadPrefix${e.id}_${o.start.year}',
          ),
        );
      }
      if (time.hasMorning && morning.isAfter(now)) {
        out.add(
          PlannedHolidayReminder(
            id: id(1),
            at: morning,
            title: l10n.holidayReminderToday(name),
            body: body,
            payload: '$payloadPrefix${e.id}_${o.start.year}',
          ),
        );
      }
    }
    return out;
  }
}
