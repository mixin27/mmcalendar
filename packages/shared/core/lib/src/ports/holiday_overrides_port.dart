import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

/// SDK-agnostic contract for holiday overrides consumed by features.
///
/// Implementations can source values from any integration (remote config,
/// local cache, backend, etc.).
abstract interface class HolidayOverridesPort {
  List<CustomHoliday> getCustomHolidays();

  List<HolidayId> getDisabledHolidays();

  Map<int, List<HolidayId>>? getDisabledHolidaysByYear();

  Map<String, List<HolidayId>>? getDisabledHolidaysByDate();
}
