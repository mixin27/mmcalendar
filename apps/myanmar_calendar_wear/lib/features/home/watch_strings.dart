import 'package:shared_localizations/shared_localizations.dart';

/// The words the watch shares with its Tile and complication: the slim
/// payload's `s` (WidgetStrings), in the calendar language and its digits.
/// Until the payload is written, the app's own words stand in.
class WatchStrings {
  WatchStrings(Map<String, Object?>? payload, this._l10n)
    : _s = (payload?['s'] as Map?)?.cast<String, Object?>() ?? const {};

  final Map<String, Object?> _s;
  final AppLocalizations _l10n;

  String _word(String key, String fallback) => _s[key] as String? ?? fallback;

  String get today => _word('today', _l10n.today);
  String get tomorrow => _word('tomorrow', _l10n.tomorrow);
  String get comingUp => _word('comingUp', 'Coming up');

  /// "Today", "Tomorrow" or "in 3 days".
  String countdown(int days) {
    if (days <= 0) return today;
    if (days == 1) return tomorrow;
    final template = _s['inDays'] as String?;
    if (template == null) return _l10n.holidaysInDays(days);
    return template.replaceAll('{n}', _digits(days));
  }

  String _digits(int value) {
    final digits = _s['digits'] as String?;
    if (digits == null || digits.length != 10) return '$value';
    return '$value'.split('').map((d) => digits[int.parse(d)]).join();
  }
}
