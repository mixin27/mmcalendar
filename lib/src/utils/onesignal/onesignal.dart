import 'package:mmcalendar/env.dart';
import 'package:mmcalendar/src/utils/native_id.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> initOnesignal() async {
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  OneSignal.initialize(Env.onesignalAppId);

  OneSignal.Notifications.requestPermission(true);

  final deviceId = await getNativeDeviceId();
  if (deviceId != null) {
    await OneSignal.login(deviceId);
  }
}

Future<void> disablePush([bool disable = true]) async {
  if (disable) {
    OneSignal.User.pushSubscription.optOut();
  } else {
    OneSignal.User.pushSubscription.optIn();
  }
}

bool? getPushSubsciption() {
  return OneSignal.User.pushSubscription.optedIn;
}
