import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// How an astrological mark reads: Sabbath, a good day, or one to be
/// careful on.
enum AstroTone { sabbath, good, caution }

/// The app's one rule for good days, used by day details, the grid, the
/// Astrology widget and the good-day finder.
///
/// It follows myanmar_calendar_dart's descriptions: Yatyaza is "generally
/// auspicious", Amyeittasote "highly auspicious", Thamaphyu good for
/// offerings; Pyathada, Thamanyo and the other named days call for care.
abstract final class GoodDays {
  /// The marks that make a day good.
  static const goodMarks = {'Yatyaza', 'Amyeittasote', 'Thamaphyu'};

  /// The tone of a mark from myanmar_calendar_dart ("Yatyaza",
  /// "Pyathada", "Thamanyo", "Sabbath"...).
  static AstroTone tone(String mark) => switch (mark) {
    'Sabbath' || 'Sabbath Eve' => AstroTone.sabbath,
    _ when goodMarks.contains(mark) => AstroTone.good,
    _ => AstroTone.caution,
  };

  /// The day's marks: Sabbath, Yatyaza, Pyathada, then the named days.
  static List<String> marks(CompleteDate day) => [
    if (day.sabbath.isNotEmpty) day.sabbath,
    if (day.yatyaza.isNotEmpty) day.yatyaza,
    if (day.pyathada.isNotEmpty) day.pyathada,
    ...day.astrologicalDays,
  ];

  /// A good day: at least one good mark and none that calls for care.
  /// Sabbath counts neither way.
  static bool isGood(CompleteDate day) {
    final tones = marks(day).map(tone);
    return tones.contains(AstroTone.good) && !tones.contains(AstroTone.caution);
  }

  /// The good days from [from] to [to], both included, optionally only on
  /// the given `DateTime` [weekdays].
  static List<CompleteDate> between(
    DateTime from,
    DateTime to, {
    Set<int>? weekdays,
  }) => [
    for (
      var d = DateTime(from.year, from.month, from.day);
      !d.isAfter(to);
      d = DateTime(d.year, d.month, d.day + 1)
    )
      if (weekdays == null || weekdays.contains(d.weekday))
        if (MyanmarCalendar.getCompleteDateFor(d.year, d.month, d.day)
            case final day when isGood(day))
          day,
  ];
}
