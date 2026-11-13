import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_widgets/home_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final saved = <Map<Object?, Object?>>[];

  setUp(() {
    saved.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), (
          call,
        ) async {
          if (call.method == 'saveWidgetData') {
            saved.add(call.arguments as Map<Object?, Object?>);
          }
          return true;
        });
  });

  // On iOS, home_widget hands null to UserDefaults as NSNull, which iOS 27
  // rejects by terminating the app: 2.3.0 crashed on launch.
  test('old widget data is never cleared with null on iOS', () async {
    await WidgetUpdateService.clearLegacyData(platform: TargetPlatform.iOS);
    expect(saved, isEmpty);
  });

  group('Apple Watch sync', () {
    final calls = <String>[];
    void handle(Future<Object?> Function(MethodCall call) handler) =>
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(WidgetUpdateService.watchChannel, (
              call,
            ) {
              calls.add(call.method);
              return handler(call);
            });

    setUp(calls.clear);
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WidgetUpdateService.watchChannel, null),
    );

    test('asks the iPhone to send the payload to the watch', () async {
      handle((_) async => null);
      await WidgetUpdateService.syncWatch(platform: TargetPlatform.iOS);
      expect(calls, ['sync']);
    });

    test('does nothing on Android', () async {
      handle((_) async => null);
      await WidgetUpdateService.syncWatch(platform: TargetPlatform.android);
      expect(calls, isEmpty);
    });

    test('a missing watch or channel is not an error', () async {
      handle((_) async => throw PlatformException(code: 'no_watch'));
      await WidgetUpdateService.syncWatch(platform: TargetPlatform.iOS);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WidgetUpdateService.watchChannel, null);
      // No handler at all, as in the background isolate.
      await WidgetUpdateService.syncWatch(platform: TargetPlatform.iOS);
      expect(calls, ['sync']);
    });
  });

  test('old widget data is removed on Android', () async {
    await WidgetUpdateService.clearLegacyData(
      platform: TargetPlatform.android,
    );
    expect(saved, isNotEmpty);
    expect(saved.every((args) => args['data'] == null), isTrue);
  });
}
