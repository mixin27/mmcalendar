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

  test('old widget data is removed on Android', () async {
    await WidgetUpdateService.clearLegacyData(
      platform: TargetPlatform.android,
    );
    expect(saved, isNotEmpty);
    expect(saved.every((args) => args['data'] == null), isTrue);
  });
}
