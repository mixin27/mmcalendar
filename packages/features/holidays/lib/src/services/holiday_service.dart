import 'package:shared_core/shared_core.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import '../models/remote_holiday_models.dart';

class HolidayService {
  final HolidayConfigPort _holidayConfigPort;

  HolidayService({required HolidayConfigPort holidayConfigPort})
    : _holidayConfigPort = holidayConfigPort;

  RemoteHolidayConfig getHolidayConfig() {
    final jsonMap = _holidayConfigPort.getHolidayConfig();
    if (jsonMap.isEmpty) {
      return RemoteHolidayConfig(
        customHolidays: [],
        disabledHolidays: [],
        disabledHolidaysByYear: {},
        disabledHolidaysByDate: {},
      );
    }

    try {
      return RemoteHolidayConfig.fromJson(jsonMap);
    } catch (_) {
      // Log error or handle gracefully
      return RemoteHolidayConfig(
        customHolidays: [],
        disabledHolidays: [],
        disabledHolidaysByYear: {},
        disabledHolidaysByDate: {},
      );
    }
  }

  List<CustomHoliday> getCustomHolidays() {
    return getHolidayConfig().customHolidays
        .map((e) => e.toCustomHoliday())
        .toList();
  }

  List<HolidayId> getDisabledHolidays() {
    return getHolidayConfig().disabledHolidays;
  }

  Map<int, List<HolidayId>>? getDisabledHolidaysByYear() {
    return getHolidayConfig().disabledHolidaysByYear;
  }

  Map<String, List<HolidayId>>? getDisabledHolidaysByDate() {
    return getHolidayConfig().disabledHolidaysByDate;
  }
}
