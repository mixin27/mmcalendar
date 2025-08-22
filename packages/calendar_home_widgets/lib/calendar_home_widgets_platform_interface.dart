import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'calendar_home_widgets_method_channel.dart';

abstract class CalendarHomeWidgetsPlatform extends PlatformInterface {
  /// Constructs a CalendarHomeWidgetsPlatform.
  CalendarHomeWidgetsPlatform() : super(token: _token);

  static final Object _token = Object();

  static CalendarHomeWidgetsPlatform _instance =
      MethodChannelCalendarHomeWidgets();

  /// The default instance of [CalendarHomeWidgetsPlatform] to use.
  ///
  /// Defaults to [MethodChannelCalendarHomeWidgets].
  static CalendarHomeWidgetsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CalendarHomeWidgetsPlatform] when
  /// they register themselves.
  static set instance(CalendarHomeWidgetsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Update `MyanmarDate` and `AstrologyData` data
  ///
  Future<void> updateMyanmarDateAndAstroInfo(Map<String, dynamic> data) {
    throw UnimplementedError(
      'updateMyanmarDateAndAstroInfo() has not been implemented.',
    );
  }

  /// Update `MoonPhase` data
  Future<void> updateMoonPhase(String phase) {
    throw UnimplementedError('updateMoonPhase() has not been implemented.');
  }
}
