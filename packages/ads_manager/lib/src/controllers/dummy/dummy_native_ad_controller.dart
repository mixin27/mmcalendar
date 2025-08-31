import 'package:ads_manager/src/controllers/native_ad_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class DummyNativeAdController implements NativeAdController {
  @override
  void dispose() {}

  @override
  bool get isEnabled => false;

  @override
  bool get isLoaded => false;

  @override
  Future<void> load() async {}

  @override
  Future<void> show() async {}

  @override
  Future<void> loadWithTemplate({
    required NativeTemplateStyle nativeTemplateStyle,
  }) async {}

  @override
  Widget get widget => const SizedBox.shrink();
}
