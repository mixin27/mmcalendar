import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

class RemoteHolidayConfig {
  const RemoteHolidayConfig({
    required this.customHolidayRules,
    required this.disabledHolidays,
    required this.disabledHolidaysByYear,
    required this.disabledHolidaysByDate,
  });

  final List<RemoteCustomHolidayRule> customHolidayRules;
  final List<HolidayId> disabledHolidays;
  final Map<int, List<HolidayId>> disabledHolidaysByYear;
  final Map<String, List<HolidayId>> disabledHolidaysByDate;

  factory RemoteHolidayConfig.fromJson(Map<String, dynamic> json) {
    final customHolidayRules = (json['customHolidayRules'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (entry) => RemoteCustomHolidayRule.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList(growable: false);

    final disabledHolidays = (json['disabledHolidays'] as List? ?? const [])
        .map(_parseHolidayId)
        .whereType<HolidayId>()
        .toList(growable: false);

    final disabledHolidaysByYear = _parseDisabledByYear(
      json['disabledHolidaysByYear'],
    );
    final disabledHolidaysByDate = _parseDisabledByDate(
      json['disabledHolidaysByDate'],
    );

    return RemoteHolidayConfig(
      customHolidayRules: customHolidayRules,
      disabledHolidays: disabledHolidays,
      disabledHolidaysByYear: disabledHolidaysByYear,
      disabledHolidaysByDate: disabledHolidaysByDate,
    );
  }

  static HolidayId? _parseHolidayId(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    try {
      return HolidayId.values.byName(value.trim());
    } catch (_) {
      return null;
    }
  }

  static Map<int, List<HolidayId>> _parseDisabledByYear(Object? raw) {
    if (raw is! Map) {
      return const <int, List<HolidayId>>{};
    }

    final mapped = <int, List<HolidayId>>{};
    raw.forEach((key, value) {
      final year = int.tryParse('$key');
      if (year == null) {
        return;
      }

      final holidays = (value is List ? value : const <Object?>[])
          .map(_parseHolidayId)
          .whereType<HolidayId>()
          .toList(growable: false);
      mapped[year] = holidays;
    });
    return mapped;
  }

  static Map<String, List<HolidayId>> _parseDisabledByDate(Object? raw) {
    if (raw is! Map) {
      return const <String, List<HolidayId>>{};
    }

    final mapped = <String, List<HolidayId>>{};
    raw.forEach((key, value) {
      final dateKey = '$key';
      final holidays = (value is List ? value : const <Object?>[])
          .map(_parseHolidayId)
          .whereType<HolidayId>()
          .toList(growable: false);
      mapped[dateKey] = holidays;
    });
    return mapped;
  }
}

class RemoteCustomHolidayRule {
  const RemoteCustomHolidayRule({
    required this.id,
    required this.name,
    required this.type,
    required this.rule,
    this.localizedNames = const <Language, String>{},
    this.cacheKey,
    this.cacheVersion = 1,
  });

  final String id;
  final String name;
  final HolidayType type;
  final RemoteHolidayRule rule;
  final Map<Language, String> localizedNames;
  final String? cacheKey;
  final int cacheVersion;

  factory RemoteCustomHolidayRule.fromJson(Map<String, dynamic> json) {
    final rawLocalizedNames = json['localizedNames'];
    final localizedNames = <Language, String>{};
    if (rawLocalizedNames is Map) {
      rawLocalizedNames.forEach((key, value) {
        if (value is! String || value.trim().isEmpty) {
          return;
        }
        localizedNames[Language.fromCode('$key')] = value;
      });
    }

    return RemoteCustomHolidayRule(
      id: (json['id'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      type: _parseHolidayType(json['type']),
      rule: RemoteHolidayRule.fromJson(
        Map<String, dynamic>.from(json['rule'] as Map? ?? const {}),
      ),
      localizedNames: localizedNames,
      cacheKey: (json['cacheKey'] as String?)?.trim(),
      cacheVersion: (json['cacheVersion'] as int?) ?? 1,
    );
  }

  static HolidayType _parseHolidayType(Object? value) {
    final raw = (value as String?)?.trim() ?? '';
    try {
      return HolidayType.values.byName(raw);
    } catch (_) {
      return HolidayType.other;
    }
  }

  CustomHoliday? toCustomHolidayRule() {
    if (id.isEmpty || name.isEmpty) {
      return null;
    }
    return rule.toCustomHoliday(
      id: id,
      name: name,
      type: type,
      localizedNames: localizedNames,
      cacheKey: cacheKey,
      cacheVersion: cacheVersion <= 0 ? 1 : cacheVersion,
    );
  }
}

enum RemoteHolidayRuleKind { westernDate, myanmarDate, matcher }

class RemoteHolidayRule {
  const RemoteHolidayRule({
    required this.kind,
    this.month,
    this.day,
    this.year,
    this.fromYear,
    this.toYear,
    this.moonPhase,
    this.fortnightDay,
    this.weekday,
    this.yearType,
    this.western,
    this.myanmar,
  });

  final RemoteHolidayRuleKind kind;
  final int? month;
  final int? day;
  final int? year;
  final int? fromYear;
  final int? toYear;
  final int? moonPhase;
  final int? fortnightDay;
  final int? weekday;
  final int? yearType;
  final Map<String, dynamic>? western;
  final Map<String, dynamic>? myanmar;

  factory RemoteHolidayRule.fromJson(Map<String, dynamic> json) {
    final kindToken = (json['kind'] ?? json['type'] ?? 'matcher')
        .toString()
        .trim();

    return RemoteHolidayRule(
      kind: _parseKind(kindToken),
      month: _asInt(json['month']),
      day: _asInt(json['day']),
      year: _asInt(json['year']),
      fromYear: _asInt(json['fromYear']),
      toYear: _asInt(json['toYear']),
      moonPhase: _asInt(json['moonPhase']),
      fortnightDay: _asInt(json['fortnightDay']),
      weekday: _asInt(json['weekday']),
      yearType: _asInt(json['yearType']),
      western: _asMap(json['western']),
      myanmar: _asMap(json['myanmar']),
    );
  }

  static RemoteHolidayRuleKind _parseKind(String token) {
    switch (token) {
      case 'western':
      case 'westernDate':
        return RemoteHolidayRuleKind.westernDate;
      case 'myanmar':
      case 'myanmarDate':
        return RemoteHolidayRuleKind.myanmarDate;
      case 'matcher':
      default:
        return RemoteHolidayRuleKind.matcher;
    }
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamic val) => MapEntry('$key', val));
    }
    return null;
  }

  CustomHoliday? toCustomHoliday({
    required String id,
    required String name,
    required HolidayType type,
    required Map<Language, String> localizedNames,
    required String? cacheKey,
    required int cacheVersion,
  }) {
    switch (kind) {
      case RemoteHolidayRuleKind.westernDate:
        if (month == null || day == null) {
          return null;
        }
        return CustomHoliday.westernDate(
          id: id,
          name: name,
          type: type,
          month: month!,
          day: day!,
          year: year,
          fromYear: fromYear,
          toYear: toYear,
          localizedNames: localizedNames,
          cacheKey: cacheKey,
          cacheVersion: cacheVersion,
        );
      case RemoteHolidayRuleKind.myanmarDate:
        if (month == null || day == null) {
          return null;
        }
        return CustomHoliday.myanmarDate(
          id: id,
          name: name,
          type: type,
          month: month!,
          day: day!,
          year: year,
          fromYear: fromYear,
          toYear: toYear,
          localizedNames: localizedNames,
          cacheKey: cacheKey,
          cacheVersion: cacheVersion,
        );
      case RemoteHolidayRuleKind.matcher:
        if (!_hasMatcherConditions) {
          return null;
        }
        return CustomHoliday(
          id: id,
          name: name,
          type: type,
          localizedNames: localizedNames,
          cacheKey: cacheKey,
          cacheVersion: cacheVersion,
          matcher: (context) {
            return _matchWestern(context.westernDate) &&
                _matchMyanmar(context.myanmarDate);
          },
        );
    }
  }

  bool get _hasMatcherConditions {
    return month != null ||
        day != null ||
        year != null ||
        fromYear != null ||
        toYear != null ||
        moonPhase != null ||
        fortnightDay != null ||
        weekday != null ||
        yearType != null ||
        (western?.isNotEmpty ?? false) ||
        (myanmar?.isNotEmpty ?? false);
  }

  bool _matchWestern(WesternDate date) {
    final matcher = western ?? const <String, dynamic>{};

    final matchYear = _asInt(matcher['year']) ?? year;
    final matchFromYear = _asInt(matcher['fromYear']) ?? fromYear;
    final matchToYear = _asInt(matcher['toYear']) ?? toYear;
    final matchMonth = _asInt(matcher['month']) ?? month;
    final matchDay = _asInt(matcher['day']) ?? day;
    final matchWeekday = _asInt(matcher['weekday']) ?? weekday;

    if (matchYear != null && date.year != matchYear) return false;
    if (matchFromYear != null && date.year < matchFromYear) return false;
    if (matchToYear != null && date.year > matchToYear) return false;
    if (matchMonth != null && date.month != matchMonth) return false;
    if (matchDay != null && date.day != matchDay) return false;
    if (matchWeekday != null && date.weekday != matchWeekday) return false;
    return true;
  }

  bool _matchMyanmar(MyanmarDate date) {
    final matcher = myanmar ?? const <String, dynamic>{};

    final matchYear = _asInt(matcher['year']) ?? year;
    final matchFromYear = _asInt(matcher['fromYear']) ?? fromYear;
    final matchToYear = _asInt(matcher['toYear']) ?? toYear;
    final matchMonth = _asInt(matcher['month']) ?? month;
    final matchDay = _asInt(matcher['day']) ?? day;
    final matchMoonPhase = _asInt(matcher['moonPhase']) ?? moonPhase;
    final matchFortnightDay = _asInt(matcher['fortnightDay']) ?? fortnightDay;
    final matchYearType = _asInt(matcher['yearType']) ?? yearType;
    final matchWeekday = _asInt(matcher['weekday']) ?? weekday;

    if (matchYear != null && date.year != matchYear) return false;
    if (matchFromYear != null && date.year < matchFromYear) return false;
    if (matchToYear != null && date.year > matchToYear) return false;
    if (matchMonth != null && date.month != matchMonth) return false;
    if (matchDay != null && date.day != matchDay) return false;
    if (matchMoonPhase != null && date.moonPhase != matchMoonPhase) {
      return false;
    }
    if (matchFortnightDay != null && date.fortnightDay != matchFortnightDay) {
      return false;
    }
    if (matchYearType != null && date.yearType != matchYearType) return false;
    if (matchWeekday != null && date.weekday != matchWeekday) return false;
    return true;
  }
}
