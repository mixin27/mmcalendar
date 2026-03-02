import 'package:shared_core/shared_core.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import '../models/remote_holiday_models.dart';

class HolidayService implements HolidayOverridesPort {
  final HolidayConfigPort _holidayConfigPort;

  HolidayService({required HolidayConfigPort holidayConfigPort})
    : _holidayConfigPort = holidayConfigPort;

  RemoteHolidayConfig getHolidayConfig() {
    final jsonMap = _holidayConfigPort.getHolidayConfig();
    if (jsonMap.isEmpty) {
      return const RemoteHolidayConfig(
        customHolidayRules: [],
        disabledHolidays: [],
        disabledHolidaysByYear: {},
        disabledHolidaysByDate: {},
      );
    }

    try {
      return RemoteHolidayConfig.fromJson(jsonMap);
    } catch (_) {
      // Log error or handle gracefully
      return const RemoteHolidayConfig(
        customHolidayRules: [],
        disabledHolidays: [],
        disabledHolidaysByYear: {},
        disabledHolidaysByDate: {},
      );
    }
  }

  @override
  List<CustomHoliday> getCustomHolidayRules() {
    return getHolidayConfig().customHolidayRules
        .map((e) => e.toCustomHolidayRule())
        .whereType<CustomHoliday>()
        .toList();
  }

  @override
  List<HolidayId> getDisabledHolidays() {
    return getHolidayConfig().disabledHolidays;
  }

  @override
  Map<int, List<HolidayId>> getDisabledHolidaysByYear() {
    return getHolidayConfig().disabledHolidaysByYear;
  }

  @override
  Map<String, List<HolidayId>> getDisabledHolidaysByDate() {
    return getHolidayConfig().disabledHolidaysByDate;
  }
}
