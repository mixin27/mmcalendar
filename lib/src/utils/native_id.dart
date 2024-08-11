import 'package:native_id/native_id.dart';

Future<String?> getNativeDeviceId() async {
  return NativeId().getId();
}
