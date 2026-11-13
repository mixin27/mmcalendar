import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:myanmar_calendar_wear/settings/watch_settings.dart';
import 'package:myanmar_calendar_wear/watch_payload/watch_payload_writer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// Rewrites the Tile and complication payload once a day in the
/// background, so its 90 days stay ahead of today without the app opening.
/// (The Tile and complications pick today's entry at midnight themselves.)
abstract final class WatchPayloadScheduler {
  static const task = 'watchPayloadDaily';

  static Future<void> schedule() async {
    try {
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerPeriodicTask(
        task,
        task,
        frequency: const Duration(days: 1),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: true,
        ),
      );
    } on Object catch (error, stack) {
      log('Could not schedule $task', error: error, stackTrace: stack);
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    final preferences = await SharedPreferences.getInstance();
    // The app may have changed the language since this isolate started.
    await preferences.reload();
    await WatchPayloadWriter(
      preferences,
    ).write(WatchSettings.languageOf(preferences));
    return true;
  });
}
