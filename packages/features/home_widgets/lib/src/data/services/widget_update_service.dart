import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Writes the widgets' data and asks every native widget to redraw.
abstract final class WidgetUpdateService {
  /// The one payload every widget reads (see WidgetPayloadBuilder).
  static const payloadKey = 'widget_data_v2';
  static const versionKey = 'widget_data_version';

  /// WidgetKit kinds; each is reloaded after a write.
  static const iosKinds = [
    'TodayWidget',
    'MoonWidget',
    'MonthWidget',
    'WeekWidget',
    'ComingUpWidget',
    'AgendaWidget',
    'CountdownWidget',
    'AstrologyWidget',
    'YearWidget',
    'LockScreenMoonWidget',
    'LockScreenDayWidget',
    'LockScreenDateWidget',
    'LockScreenLineWidget',
  ];

  /// Glance widget receivers (Android).
  static const androidReceivers = [
    'TodayWidgetReceiver',
    'MoonWidgetReceiver',
    'MonthWidgetReceiver',
    'WeekWidgetReceiver',
    'ComingUpWidgetReceiver',
    'AgendaWidgetReceiver',
    'CountdownWidgetReceiver',
    'AstrologyWidgetReceiver',
    'YearWidgetReceiver',
  ];

  static const _androidPackage = 'dev.mixin27.mmcalendar.widgets';

  /// The fully qualified name of an Android widget [receiver].
  static String androidReceiver(String receiver) =>
      '$_androidPackage.$receiver';

  /// Keys the v1 widgets used; cleared once v2 is written.
  static const _legacyKeys = [
    'widget_timeline_v1',
    'widget_month_timeline_v1',
    'myanmar_month_data',
    'myanmar_date',
    'western_date',
    'moon_phase',
    'moon_illumination',
    'moon_is_waxing',
    'moon_phase_value',
    'fortnight_day',
    'fortnight_day_text',
    'holidays',
    'sabbath_info',
    'yatyaza_info',
    'pyathada_info',
    'astrological_days',
    'weekday_names',
    'moon_phase_names',
    'last_updated',
    'moon_phase_image_path',
    'full_moon_phase_image_path',
    'next_moon_phase',
    'show_holidays',
    'show_astrology',
    'show_last_updated',
    'show_myanmar_date',
    'show_western_date',
    'widget_size',
    'widget_theme',
    'moon_phase_image_large',
    'moon_phase_image_small',
  ];

  static Future<void> savePayload(Map<String, Object?> payload) async {
    await HomeWidget.saveWidgetData<String>(payloadKey, jsonEncode(payload));
    await HomeWidget.saveWidgetData<int>(versionKey, payload['v'] as int);
  }

  /// Removes the widget data older versions wrote, on Android only.
  ///
  /// home_widget removes a key when given null on Android, but on iOS it
  /// passes null on to UserDefaults as NSNull, which iOS 27 rejects by
  /// terminating the app (the 2.3.0 launch crash). The few old keys left
  /// in the iOS app group are unused and harmless.
  static Future<void> clearLegacyData({TargetPlatform? platform}) async {
    if ((platform ?? defaultTargetPlatform) != TargetPlatform.android) return;
    for (final key in _legacyKeys) {
      await HomeWidget.saveWidgetData<Object>(key, null);
    }
  }

  /// Redraws every widget kind on both platforms.
  static Future<void> reloadAll() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      for (final kind in iosKinds) {
        await _reload(() => HomeWidget.updateWidget(iOSName: kind));
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      for (final receiver in androidReceivers) {
        await _reload(
          () => HomeWidget.updateWidget(
            qualifiedAndroidName: androidReceiver(receiver),
          ),
        );
      }
    }
  }

  static Future<void> _reload(Future<Object?> Function() call) async {
    try {
      await call();
    } catch (e) {
      // A kind that isn't installed yet (or an older native build) is fine.
      debugPrint('Widget reload skipped: $e');
    }
  }
}
