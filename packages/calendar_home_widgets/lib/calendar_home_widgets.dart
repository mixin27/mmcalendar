import 'dart:async';
import 'dart:developer';

import 'package:calendar_home_widgets/utils/home_widget_utils.dart';
import 'package:calendar_home_widgets/utils/workmanager_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:home_widget/home_widget.dart';

class CalendarHomeWidgets {
  static Future<void> initCalendarWidgetsBackground({
    String? title,
    Widget? moonPhase,
  }) async {
    await updateWidgetData(title: title, moonPhase: moonPhase);

    await HomeWidget.registerInteractivityCallback(_interactivityCallback);

    Timer.periodic(Duration(minutes: 1), (_) async {
      log("update widget...");
      await updateWidgetData();
    });
  }

  static FutureOr<void> _interactivityCallback(Uri? uri) async {
    await updateWidgetData();
  }

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
