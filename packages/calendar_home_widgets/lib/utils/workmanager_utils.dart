import 'package:calendar_home_widgets/utils/utils.dart';
import 'package:workmanager/workmanager.dart';

const widgetUpdateTask = "updateCalendarWidget";

class WorkmanagerUtils {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);

    // Schedule every 24 hours, starting midnight
    await Workmanager().registerPeriodicTask(
      "1",
      widgetUpdateTask,
      frequency: const Duration(hours: 24),
      initialDelay: timeUntilNextMidnight(),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == widgetUpdateTask) {
      // Do something
      // updateWidgetData()
    }
    return Future.value(true);
  });
}
