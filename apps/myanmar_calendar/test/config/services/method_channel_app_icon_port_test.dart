import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mmcalendar/config/services/method_channel_app_icon_port.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.mixin27.mmcalendar/app_icon');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('applies and verifies a platform app icon', () async {
    var currentIcon = 'default';
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'setAppIcon':
          currentIcon =
              (call.arguments as Map<Object?, Object?>)['iconId']! as String;
          return true;
        case 'getCurrentIcon':
          return currentIcon;
        default:
          return null;
      }
    });

    final port = MethodChannelAppIconPort();

    expect(await port.setIcon('forest'), isTrue);
    expect(await port.getCurrentIcon(), 'forest');
  });

  test('reports a native icon change failure', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'native_change_failed',
        message: 'iOS did not apply the selected app icon.',
      );
    });

    final port = MethodChannelAppIconPort();

    await expectLater(
      port.setIcon('moon'),
      throwsA(
        isA<AppIconException>()
            .having((error) => error.code, 'code', 'native_change_failed')
            .having(
              (error) => error.message,
              'message',
              'iOS did not apply the selected app icon.',
            ),
      ),
    );
  });
}
