import 'package:calendar_home_widgets/utils/mmcalendar_utils.dart';
import 'package:calendar_home_widgets/utils/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

Language getLanguageFromString(String lang) {
  if (lang == Language.english.name) {
    return Language.english;
  } else if (lang == Language.karen.name) {
    return Language.karen;
  } else if (lang == Language.mon.name) {
    return Language.mon;
  } else if (lang == Language.tai.name) {
    return Language.tai;
  } else if (lang == Language.zawgyi.name) {
    return Language.zawgyi;
  } else {
    return Language.myanmar;
  }
}

Future<void> changeCalendarLanguage([
  Language language = Language.myanmar,
]) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("calendar_language", language.name);
}

Future<void> updateWidgetData({
  DateTime? date,
  String? title,
  Widget? moonPhase,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final language =
      prefs.getString("calendar_language") ?? Language.myanmar.name;
  final preferLanguage = getLanguageFromString(language);

  final config = MmCalendarConfig(language: preferLanguage);
  final mDateInfo = getMyanmarDateAndAstroInfo(
    date ?? DateTime.now(),
    config: config,
  );

  final widgetTheme = await getWidgetTheme();
  await HomeWidget.saveWidgetData("widget_theme", widgetTheme);

  await HomeWidget.saveWidgetData("title", title ?? "MyanmarCalendar");

  await HomeWidget.saveWidgetData<String>("en_day", mDateInfo["dayEn"]);
  await HomeWidget.saveWidgetData<String>("en_dow", mDateInfo["dowEn"]);
  await HomeWidget.saveWidgetData<String>(
    "en_month_year",
    mDateInfo["monthAndYearEn"],
  );
  await HomeWidget.saveWidgetData<String>(
    "myanmar_date_full",
    mDateInfo["date"],
  );
  await HomeWidget.saveWidgetData<String>("myanmar_dow", mDateInfo["dow"]);
  await HomeWidget.saveWidgetData<String>("myanmar_day", mDateInfo["day"]);
  await HomeWidget.saveWidgetData<String>(
    "fortnightDay",
    mDateInfo["fortnightDay"],
  );
  await HomeWidget.saveWidgetData<String>("sabbath", mDateInfo["sabbath"]);
  await HomeWidget.saveWidgetData<String>(
    "astrologicalDay",
    mDateInfo["astrologicalDay"],
  );
  await HomeWidget.saveWidgetData<String>("nagapor", mDateInfo["nagapor"]);
  await HomeWidget.saveWidgetData<String>("naga", mDateInfo["naga"]);
  await HomeWidget.saveWidgetData<String>("mahabote", mDateInfo["mahabote"]);
  await HomeWidget.saveWidgetData<String>("nakhat", mDateInfo["nakhat"]);
  await HomeWidget.saveWidgetData<String>("yearname", mDateInfo["yearname"]);
  await HomeWidget.saveWidgetData<String>(
    "isPublicHoliday",
    mDateInfo["isPublicHoliday"],
  );
  await HomeWidget.saveWidgetData<String>("holidays", mDateInfo["holidays"]);

  await HomeWidget.updateWidget(
    name: 'DateAndAstroInfoWidget',
    qualifiedAndroidName:
        'dev.mixin27.calendar_home_widgets.DateAndAstroInfoWidget',
  );

  // Moon Phase
  final mpDate = date ?? DateTime.now();
  final moonPhaseData = getMoonPhaseData(mpDate, config: config);
  await HomeWidget.saveWidgetData<String>("moonPhaseTitle", "Moon Phase");
  await HomeWidget.saveWidgetData<String>(
    "moonPhaseMM",
    moonPhaseData["moonPhaseMM"],
  );
  final widget = moonPhase ?? MoonPhaseWidget(date: mpDate, size: 72);
  await HomeWidget.renderFlutterWidget(
    widget,
    key: "moonPhase",
    logicalSize: const Size(72, 72),
  );

  // MoonPhase
  await HomeWidget.updateWidget(
    name: 'MoonPhaseWidget',
    qualifiedAndroidName: 'dev.mixin27.calendar_home_widgets.MoonPhaseWidget',
  );

  await HomeWidget.updateWidget(
    name: 'MmDateMoonPhaseWidget',
    qualifiedAndroidName:
        'dev.mixin27.calendar_home_widgets.MmDateMoonPhaseWidget',
  );
}
