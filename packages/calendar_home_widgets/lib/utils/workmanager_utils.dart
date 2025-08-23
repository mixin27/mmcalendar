import 'dart:developer';

import 'package:calendar_home_widgets/utils/home_widget_utils.dart';
import 'package:workmanager/workmanager.dart';

class WorkmanagerUtils {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);

    // Schedule every 24 hours, starting midnight
    await Workmanager().registerPeriodicTask(
      "calendar_widget_update_task_1",
      "updateWidgetDataTask",
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
    log("updateWidgets task registered!!!");
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == "updateWidgetDataTask") {
        await updateWidgetData();
        log("Widget data updated after 15 min.");
        return Future.value(true);
      } else {
        log("Widget data update failed after 15 min.");
        return Future.value(false);
      }
    } catch (e) {
      // 🔥 Permanent failure - will not retry
      throw Exception('Task failed: $e');
    }
  });
}
