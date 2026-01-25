import 'dart:convert';
import 'dart:developer';
import 'package:app_remote_config/app_remote_config.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import '../models/remote_holiday_models.dart';

class HolidayService {
  final RemoteConfigService _remoteConfigService;
  static const String _holidayConfigKey = 'holiday_config';

  HolidayService({required RemoteConfigService remoteConfigService})
    : _remoteConfigService = remoteConfigService;

  RemoteHolidayConfig getHolidayConfig() {
    final jsonString = _remoteConfigService.getString(_holidayConfigKey);
    if (jsonString.isEmpty) {
      return RemoteHolidayConfig(
        customHolidays: [],
        disabledHolidays: [],
        disabledHolidaysByYear: {},
        disabledHolidaysByDate: {},
      );
    }

    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      log('CustomHolidays: ${jsonMap.toString()}');
      return RemoteHolidayConfig.fromJson(jsonMap);
    } catch (e) {
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
