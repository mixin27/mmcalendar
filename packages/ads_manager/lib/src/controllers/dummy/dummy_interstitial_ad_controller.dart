import 'package:ads_manager/src/controllers/interstitial_ad_controller.dart';

class DummyInterstitialAdController implements InterstitialAdController {
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
}
