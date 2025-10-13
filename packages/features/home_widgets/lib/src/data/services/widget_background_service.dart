import 'package:flutter/foundation.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

/// Background service for updating widgets
/// This runs independently of the Flutter app
///
/// IMPORTANT: This must be a top-level function, not inside a class
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 Background task started: $task');

    try {
      // Initialize Myanmar Calendar with default settings
      // Note: We can't access database in background, so use defaults
      MyanmarCalendar.configure(
        language: Language.myanmar,
        timezoneOffset: 6.5,
        sasanaYearType: 0,
        calendarType: 0,
        gregorianStart: 2361222,
      );

      debugPrint('✅ Myanmar Calendar configured');

      // Get today's date
      final today = DateTime.now();
      debugPrint('📅 Updating widget for date: $today');

      final myanmarDateTime = MyanmarCalendar.fromWestern(
        today.year,
        today.month,
        today.day,
      );

      // Format data
      final myanmarDate = myanmarDateTime.formatMyanmar('&y &M &P &ff');
      final westernDate = myanmarDateTime.formatWestern('%d %M %yyyy');
      final moonPhase = _getMoonPhaseName(myanmarDateTime.moonPhase);
      final moonPhaseEmoji = _getMoonPhaseEmoji(myanmarDateTime.moonPhase);
      final holidays = myanmarDateTime.allHolidays
          .map((h) => TranslationService.translate(h))
          .join(', ');

      // Get astrology info
      String sabbathInfo = '';
      String yatyazaInfo = '';
      String pyathadaInfo = '';

      if (myanmarDateTime.isSabbath || myanmarDateTime.isSabbathEve) {
        sabbathInfo = TranslationService.translate(myanmarDateTime.sabbath);
      }

      if (myanmarDateTime.isYatyaza) {
        yatyazaInfo = TranslationService.translate(myanmarDateTime.yatyaza);
      }

      if (myanmarDateTime.hasPyathada) {
        pyathadaInfo = TranslationService.translate(myanmarDateTime.pyathada);
      }

      debugPrint('📅 Myanmar Date: $myanmarDate');
      debugPrint('📅 Western Date: $westernDate');
      debugPrint('🌙 Moon Phase: $moonPhase $moonPhaseEmoji');
      debugPrint('🎉 Holidays: $holidays');

      // Save to HomeWidget storage
      await HomeWidget.saveWidgetData<String>('myanmar_date', myanmarDate);
      await HomeWidget.saveWidgetData<String>('western_date', westernDate);
      await HomeWidget.saveWidgetData<String>('moon_phase', moonPhase);
      await HomeWidget.saveWidgetData<String>(
        'moon_phase_emoji',
        moonPhaseEmoji,
      );
      await HomeWidget.saveWidgetData<String>('holidays', holidays);
      await HomeWidget.saveWidgetData<String>('sabbath_info', sabbathInfo);
      await HomeWidget.saveWidgetData<String>('yatyaza_info', yatyazaInfo);
      await HomeWidget.saveWidgetData<String>('pyathada_info', pyathadaInfo);
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateTime.now().toIso8601String(),
      );

      debugPrint('✅ Widget data saved');

      // Trigger widget update
      final result = await HomeWidget.updateWidget(
        androidName: 'AppHomeWidgetProvider',
        iOSName: 'HomeWidget',
      );

      debugPrint('📱 Widget update result: $result');

      return result == true;
    } catch (e, stackTrace) {
      debugPrint('❌ Background task failed: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  });
}

String _getMoonPhaseName(int moonPhase) {
  switch (moonPhase) {
    case 0:
      return 'Waxing';
    case 1:
      return 'Full Moon';
    case 2:
      return 'Waning';
    case 3:
      return 'New Moon';
    default:
      return 'Unknown';
  }
}

String _getMoonPhaseEmoji(int moonPhase) {
  switch (moonPhase) {
    case 0:
      return '🌒';
    case 1:
      return '🌕';
    case 2:
      return '🌘';
    case 3:
      return '🌑';
    default:
      return '🌙';
  }
}
