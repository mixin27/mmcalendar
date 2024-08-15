import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

bool isWeekend(DateTime date) =>
    date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

bool isHoliday(DateTime date, MyanmarDate mmDate) {
  if (isWeekend(date)) return true;

  return mmDate.holidays.isNotEmpty;
}

// extension MyanmarDateX on MyanmarDate {
//   Astro get astro => AstroConverter.convert(this);

//   List<String> get holidays => HolidaysCalculator.getHolidays(this);
//   List<MyanmarThingyan> get thingyans =>
//       ThingyanCalculator.getMyanmarThingyanDays(this);
// }

// extension DateTimeX on DateTime {
//   MyanmarDate get mmDate => MyanmarDateConverter.fromDateTime(this);
// }
