import 'package:mmcalendar/src/utils/native_id.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

const String onesignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');

Future<void> initOnesignal() async {
  if (onesignalAppId.isEmpty) {
    throw AssertionError('ONESIGNAL_APP_ID is not set');
  }

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  OneSignal.initialize(onesignalAppId);

  OneSignal.Notifications.requestPermission(true);

  final deviceId = await getNativeDeviceId();
  if (deviceId != null) {
    await OneSignal.login(deviceId);
  }

  OneSignal.InAppMessages.addTrigger('current_build_number', '2');
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
