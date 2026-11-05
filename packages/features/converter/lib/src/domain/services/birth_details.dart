import 'package:flutter/foundation.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:shared_core/shared_core.dart';

/// The eight Burmese birth signs: one per weekday, with Wednesday split at
/// noon into Mercury (before) and Rahu (after).
enum BirthSign {
  sunday,
  monday,
  tuesday,
  wednesday,
  rahu,
  thursday,
  friday,
  saturday;

  /// The sign for a `DateTime` [weekday]; [afternoon] matters only on
  /// Wednesday.
  static BirthSign of(int weekday, {bool afternoon = false}) =>
      switch (weekday) {
        DateTime.sunday => sunday,
        DateTime.monday => monday,
        DateTime.tuesday => tuesday,
        DateTime.wednesday => afternoon ? rahu : wednesday,
        DateTime.thursday => thursday,
        DateTime.friday => friday,
        _ => saturday,
      };
}

/// Years, months and days.
@immutable
class Age {
  const Age(this.years, this.months, this.days);

  final int years;
  final int months;
  final int days;

  /// The time from [birth] to [today], as on a calendar: whole months
  /// counted from the birth day (the 31st steps to a shorter month's last
  /// day), then the days left.
  factory Age.between(DateTime birth, DateTime today) {
    DateTime monthsOn(int months) {
      final lastDay = DateTime(birth.year, birth.month + months + 1, 0).day;
      return DateTime(
        birth.year,
        birth.month + months,
        birth.day > lastDay ? lastDay : birth.day,
      );
    }

    var months = (today.year - birth.year) * 12 + today.month - birth.month;
    if (monthsOn(months).isAfter(today)) months--;
    final from = monthsOn(months);
    // UTC, so a daylight-saving change can't shorten a day.
    final days = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
    return Age(months ~/ 12, months % 12, days);
  }

  @override
  bool operator ==(Object other) =>
      other is Age &&
      other.years == years &&
      other.months == months &&
      other.days == days;

  @override
  int get hashCode => Object.hash(years, months, days);

  @override
  String toString() => 'Age($years y, $months m, $days d)';
}

/// What a birth date says: the Myanmar date and signs, the age, and the
/// next Western and Myanmar birthdays.
@immutable
class BirthDetails {
  const BirthDetails._({
    required this.birth,
    required this.date,
    required this.sign,
    required this.age,
    required this.nextBirthday,
    required this.nextMyanmarBirthday,
  });

  factory BirthDetails.of(
    DateTime birth, {
    required DateTime today,
    bool afternoon = false,
  }) {
    final day = DateTime(birth.year, birth.month, birth.day);
    final now = DateTime(today.year, today.month, today.day);
    final date = MyanmarCalendar.getCompleteDateFor(
      day.year,
      day.month,
      day.day,
    );
    return BirthDetails._(
      birth: day,
      date: date,
      sign: BirthSign.of(day.weekday, afternoon: afternoon),
      age: Age.between(day, now),
      nextBirthday: nextWesternBirthday(day, now),
      nextMyanmarBirthday: MyanmarRecurrence.next(day, now),
    );
  }

  final DateTime birth;
  final CompleteDate date;
  final BirthSign sign;
  final Age age;
  final DateTime nextBirthday;

  /// The next day with the birth's Myanmar month and day
  /// ([MyanmarRecurrence]); null only when none falls in the next years.
  final DateTime? nextMyanmarBirthday;

  /// The next [birth] day and month from [today], today included; 29
  /// February falls on 28 February in other years.
  static DateTime nextWesternBirthday(DateTime birth, DateTime today) {
    DateTime inYear(int y) {
      final d = DateTime(y, birth.month, birth.day);
      return d.month == birth.month ? d : DateTime(y, birth.month + 1, 0);
    }

    final thisYear = inYear(today.year);
    return thisYear.isBefore(today) ? inYear(today.year + 1) : thisYear;
  }
}
