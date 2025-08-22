import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'calendar_home_widgets_platform_interface.dart';

/// An implementation of [CalendarHomeWidgetsPlatform] that uses method channels.
class MethodChannelCalendarHomeWidgets extends CalendarHomeWidgetsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('calendar_home_widgets');

  @override
  Future<void> updateMyanmarDateAndAstroInfo(Map<String, dynamic> data) async {
    try {
      await methodChannel.invokeListMethod(
        "updateMyanmarDateAndAstroInfo",
        data,
      );
    } catch (e) {
      debugPrint(
        "[updateMyanmarDateAndAstroInfo] Error on updating Astrology data.",
      );
    }
  }

  @override
  Future<void> updateMoonPhase(String phase) async {
    try {
      await methodChannel.invokeListMethod("updateMoonPhase", {
        "moonPhase",
        phase,
      });
    } catch (e) {
      debugPrint("[updateMoonPhase] Error on updating MoonPhase data.");
    }
  }
}
