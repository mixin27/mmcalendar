import 'package:calendar_home_widgets/utils/utils.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:intl/intl.dart';

Map<String, dynamic> getMyanmarDateAndAstroInfo(
  DateTime date, {
  MmCalendarConfig? config,
}) {
  final dayEn = DateFormat("d", "en_US").format(date);
  final monthAndYearEn = DateFormat("MMMM yyyy", "en_US").format(date);
  final dowEn = DateFormat("EEEE", "en_US").format(date);

  final mConfig = config ?? MmCalendarConfig(language: Language.myanmar);
  final mmCalendar = MmCalendar(config: mConfig);
  final mmDate = mmCalendar.fromDateTime(date);
  final fortnightDay = mmDate.getFortnightDay();

  final mmDow = mmDate.format('En');

  final mmDay = fortnightDay.isNotEmpty
      ? mmDate.format('M p f r n')
      : mmDate.format('M p n');

  final mmDateFull = fortnightDay.isNotEmpty
      ? mmDate.format('S s k, B y k, M p f r, En')
      : mmDate.format('S s k, B y k, M p, En');

  final moonPhaseMM = mmDate.format('M p');

  final languageCatalog = LanguageCatalog(language: mConfig.language);
  final astro = mmDate.astro;

  final sabbath = astro.getSabbath();
  final astrologicalDay = astro.getAstrologicalDay();

  final nagaMM = languageCatalog.translate('Naga');
  final headMM = languageCatalog.translate('Head');
  final facingMM = languageCatalog.translate('Facing');
  final nagahle = astro.getNagahle();

  final bornMM = languageCatalog.translate('Born');
  final mahabote = astro.getMahabote();

  final yearMM = languageCatalog.translate('Year');
  final yearname = astro.getYearName();

  final nakhatMM = languageCatalog.translate('Nakhat');
  final nakhat = astro.getNakhat();

  final nagapor = astro.getNagapor();

  List<String> holidays = mmDate.getHolidays(
    langCatalog: mmCalendar.languageCatalog,
  );
  final isPublicHoliday = isHoliday(date, mmDate);

  return {
    "dayEn": dayEn,
    "monthAndYearEn": monthAndYearEn,
    "dowEn": dowEn,
    "date": mmDateFull,
    "moonPhaseMM": moonPhaseMM,
    "dow": mmDow,
    "day": mmDay,
    "fortnightDay": fortnightDay,
    "sabbath": sabbath.isNotEmpty ? '\u2022 $sabbath' : "--",
    "astrologicalDay": astrologicalDay.isNotEmpty
        ? '\u2022 $astrologicalDay'
        : "--",
    "nagapor": nagapor.isNotEmpty ? '\u2022 $nagapor' : "--",
    "naga": '\u2022 $nagaMM$headMM $nagahle $facingMM',
    "mahabote": '\u2022 $mahabote $bornMM',
    "nakhat": '\u2022 $nakhat $nakhatMM',
    "yearname": '\u2022 $yearname $yearMM',
    "isPublicHoliday": isPublicHoliday.toString(),
    "holidays": holidays.toString(),
  };
}

Map<String, String> getMoonPhaseData(
  DateTime date, {
  MmCalendarConfig? config,
}) {
  final mConfig = config ?? MmCalendarConfig(language: Language.myanmar);
  final mmCalendar = MmCalendar(config: mConfig);
  final mmDate = mmCalendar.fromDateTime(date);
  final moonPhaseMM = mmDate.format('M p');
  return {"moonPhaseMM": moonPhaseMM};
}
