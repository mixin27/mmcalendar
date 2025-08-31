import 'package:ads_manager/src/controllers/banner_ad_controller.dart';
import 'package:flutter/widgets.dart';

class DummyBannerAdController implements BannerAdController {
  @override
  Future<void> show() async {}

  @override
  bool get isLoaded => false;

  @override
  Widget get widget => const SizedBox.shrink();

  @override
  void dispose() {}

  @override
  bool get isEnabled => false;

  @override
  Future<void> load() async {}
}
