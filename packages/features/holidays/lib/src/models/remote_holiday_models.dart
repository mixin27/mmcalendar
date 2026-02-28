import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

class RemoteHolidayConfig {
  final List<RemoteCustomHoliday> customHolidays;
  final List<HolidayId> disabledHolidays;
  final Map<int, List<HolidayId>>? disabledHolidaysByYear;
  final Map<String, List<HolidayId>>? disabledHolidaysByDate;

  RemoteHolidayConfig({
    required this.customHolidays,
    required this.disabledHolidays,
    required this.disabledHolidaysByYear,
    required this.disabledHolidaysByDate,
  });

  factory RemoteHolidayConfig.fromJson(Map<String, dynamic> json) {
    return RemoteHolidayConfig(
      customHolidays: (json['customHolidays'] as List? ?? [])
          .map((e) => RemoteCustomHoliday.fromJson(e as Map<String, dynamic>))
          .toList(),
      disabledHolidays: (json['disabledHolidays'] as List? ?? [])
          .map((e) => _parseHolidayId(e as String))
          .whereType<HolidayId>()
          .toList(),
      disabledHolidaysByYear:
          (json['disabledHolidaysByYear'] as Map<String, dynamic>?)?.map(
            (year, holidays) => MapEntry(
              int.parse(year),
              (holidays as List<dynamic>)
                  .map((e) => _parseHolidayId(e as String))
                  .whereType<HolidayId>()
                  .toList(),
            ),
          ),
      disabledHolidaysByDate:
          (json['disabledHolidaysByDate'] as Map<String, dynamic>?)?.map(
            (date, holidays) => MapEntry(
              date,
              (holidays as List<dynamic>)
                  .map((e) => _parseHolidayId(e as String))
                  .whereType<HolidayId>()
                  .toList(),
            ),
          ),
    );
  }

  static HolidayId? _parseHolidayId(String value) {
    try {
      return HolidayId.values.byName(value);
    } catch (_) {
      return null;
    }
  }
}

class RemoteCustomHoliday {
  final String id;
  final String name;
  final HolidayType type;
  final RemoteHolidayRule rule;

  RemoteCustomHoliday({
    required this.id,
    required this.name,
    required this.type,
    required this.rule,
  });

  factory RemoteCustomHoliday.fromJson(Map<String, dynamic> json) {
    return RemoteCustomHoliday(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _parseHolidayType(json['type'] as String),
      rule: RemoteHolidayRule.fromJson(json['rule'] as Map<String, dynamic>),
    );
  }

  static HolidayType _parseHolidayType(String value) {
    try {
      return HolidayType.values.byName(value);
    } catch (_) {
      return HolidayType.other;
    }
  }

  CustomHoliday toCustomHoliday() {
    return CustomHoliday(
      id: id,
      name: name,
      type: type,
      matcher: rule.toMatcher(),
    );
  }
}

class RemoteHolidayRule {
  final String type; // 'western', 'myanmar'
  final int? month;
  final int? day;
  final int? moonPhase; // for myanmar

  RemoteHolidayRule({required this.type, this.month, this.day, this.moonPhase});

  factory RemoteHolidayRule.fromJson(Map<String, dynamic> json) {
    return RemoteHolidayRule(
      type: json['type'] as String,
      month: json['month'] as int?,
      day: json['day'] as int?,
      moonPhase: json['moonPhase'] as int?,
    );
  }

  CustomHolidayMatcher toMatcher() {
    if (type == 'western') {
      return (CustomHolidayContext context) {
        final wd = context.westernDate;
        return wd.month == month && wd.day == day;
      };
    } else if (type == 'myanmar') {
      return (CustomHolidayContext context) {
        final mm = context.myanmarDate;
        if (month != null && mm.month != month) return false;
        if (day != null && mm.day != day) return false;
        if (moonPhase != null && mm.moonPhase != moonPhase) return false;
        return true;
      };
    }
    return (_) => false;
  }
}
