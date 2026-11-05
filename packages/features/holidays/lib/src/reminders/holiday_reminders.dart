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
/// Sabbath days can be followed too ([sabbath]); a Sabbath that is also
/// the first day of a reminded holiday shares that holiday's notification.
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
  static const _sabbathKey = 'holiday_reminders_sabbath';

  /// Holiday ids are [idBase] + day × 100 + slot, below this offset;
  /// Sabbath ids ([idBase] + offset + day × 2 + time) start past them.
  static const _sabbathSlot = 100000 * 100;

  final SharedPreferences _prefs;
  final Future<bool> Function() _requestPermission;
  final FlutterLocalNotificationsPlugin _plugin;

  Language _calendarLanguage = Language.myanmar;
  Locale _appLocale = const Locale('en');

  Set<String> get followed => {...?_prefs.getStringList(_followedKey)};
  bool get allPublic => _prefs.getBool(_allPublicKey) ?? false;

  /// Whether Sabbath days get reminders.
  bool get sabbath => _prefs.getBool(_sabbathKey) ?? false;
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

  Future<bool> setSabbath(bool on) async {
    await _prefs.setBool(_sabbathKey, on);
    return _changed(asking: on);
  }

  /// The reminder choices, for a backup.
  Map<String, Object?> toBackup() => {
    _followedKey: followed.toList()..sort(),
    _allPublicKey: allPublic,
    _sabbathKey: sabbath,
    _timeKey: time.name,
  };

  /// Restores choices from [toBackup] (unknown keys are ignored) and
  /// reschedules. Doesn't ask for notification permission.
  Future<void> restoreBackup(Map<String, Object?> backup) async {
    if (backup[_followedKey] case final List<Object?> ids) {
      await _prefs.setStringList(_followedKey, [
        for (final id in ids)
          if (id is String) id,
      ]);
    }
    if (backup[_allPublicKey] case final bool on) {
      await _prefs.setBool(_allPublicKey, on);
    }
    if (backup[_sabbathKey] case final bool on) {
      await _prefs.setBool(_sabbathKey, on);
    }
    if (backup[_timeKey] case final String name
        when HolidayReminderTime.values.any((t) => t.name == name)) {
      await _prefs.setString(_timeKey, name);
    }
    await _changed(asking: false);
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
        sabbath: sabbath,
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
          notificationDetails: _details(r.body),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: r.payload,
        );
      }
    } catch (e) {
      // No plugin in tests, or notifications unavailable: nothing to do.
      debugPrint('Holiday reminders not scheduled: $e');
    }
  }

  /// Android shows [body] in full when the notification is expanded; its
  /// second line explains the holiday.
  static NotificationDetails _details(String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      'holidays_channel',
      'Holiday reminders',
      channelDescription: 'Reminders for holidays you follow',
      importance: Importance.defaultImportance,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    ),
    macOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    ),
  );

  /// The reminders for holidays starting, and with [sabbath] Sabbath days
  /// falling, within [horizonDays] of [now], in time order.
  static List<PlannedHolidayReminder> plan({
    required DateTime now,
    required Set<String> followed,
    required bool allPublic,
    bool sabbath = false,
    required HolidayReminderTime time,
    required Language calendarLanguage,
    required AppLocalizations l10n,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: horizonDays));
    final format = CalendarFormat(calendarLanguage);
    final sabbathDays = sabbath
        ? {
            for (
              var d = today;
              !d.isAfter(end);
              d = DateTime(d.year, d.month, d.day + 1)
            )
              if (MyanmarCalendar.getCompleteDateFor(
                d.year,
                d.month,
                d.day,
              ).isSabbath)
                d,
          }
        : <DateTime>{};
    final out = <PlannedHolidayReminder>[];
    void add(
      DateTime day,
      int Function(int slot) id,
      String name,
      String body,
      String payload,
    ) {
      final evening = DateTime(day.year, day.month, day.day - 1, eveningHour);
      final morning = DateTime(day.year, day.month, day.day, morningHour);
      if (time.hasEvening && evening.isAfter(now)) {
        out.add(
          PlannedHolidayReminder(
            id: id(0),
            at: evening,
            title: l10n.holidayReminderTomorrow(name),
            body: body,
            payload: payload,
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
            payload: payload,
          ),
        );
      }
    }

    int dayIndex(DateTime day) =>
        day.difference(DateTime(1970)).inDays % 100000;

    for (final o in HolidayYears.between(today, end, calendarLanguage)) {
      final e = o.entry;
      if (!followed.contains(e.id) && !(allPublic && e.officeClosed)) continue;
      // A Sabbath on the holiday's first day joins its notification.
      final alsoSabbath = sabbathDays.remove(o.start);
      final name = alsoSabbath
          ? '${e.title(l10n)} · ${l10n.sabbathReminderName}'
          : e.title(l10n);
      final dates = format.holidayRange(o);
      final body = [
        e.officeClosed ? l10n.holidayReminderBodyPublic(dates) : dates,
        ?e.about(l10n),
      ].join('\n');
      final index = HolidayCatalog.all.indexOf(e);
      final day = dayIndex(o.start);
      add(
        o.start,
        (slot) => idBase + day * 100 + (index < 0 ? 49 : index) * 2 + slot,
        name,
        body,
        '$payloadPrefix${e.id}_${o.start.year}',
      );
    }
    for (final d in sabbathDays) {
      final myanmar = MyanmarCalendar.getCompleteDateFor(
        d.year,
        d.month,
        d.day,
      ).myanmar;
      add(
        d,
        (slot) => idBase + _sabbathSlot + dayIndex(d) * 2 + slot,
        l10n.sabbathReminderName,
        '${format.myanmar(myanmar, '&M &P &f')} · ${format.dayMonth(d)}',
        '${payloadPrefix}sabbath_${d.toIso8601String().substring(0, 10)}',
      );
    }
    return out..sort((a, b) => a.at.compareTo(b.at));
  }
}
