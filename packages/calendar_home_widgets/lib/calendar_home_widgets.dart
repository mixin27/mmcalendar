import 'package:calendar_home_widgets/utils/home_widget_utils.dart';
import 'package:calendar_home_widgets/utils/workmanager_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

class CalendarHomeWidgets {
  static Future<void> initCalendarWidgets({
    String? title,
    Widget? moonPhase,
  }) async {
    await updateWidgetData(title: title, moonPhase: moonPhase);
    await WorkmanagerUtils.init();
  }

  static Future<void> updateMoonPhase(Widget phase) async {
    await updateWidgetData(moonPhase: phase);
  }

  static Future<void> updateCalendarLanguage(Language lang) async {
    await changeCalendarLanguage(lang);
    await updateWidgetData();
  }
}
