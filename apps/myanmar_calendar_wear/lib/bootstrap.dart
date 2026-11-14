import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:myanmar_calendar_wear/settings/watch_settings.dart';
import 'package:myanmar_calendar_wear/watch_payload/watch_payload_scheduler.dart';

/// Loads the saved calendar language, runs the app and schedules the daily
/// rewrite of the Tile and complication payload.
Future<void> bootstrap(Widget Function(WatchSettings settings) builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  final settings = await WatchSettings.load();
  // The app writes the payload after its first frame (App._write).
  runApp(builder(settings));
  unawaited(WatchPayloadScheduler.schedule());
}
