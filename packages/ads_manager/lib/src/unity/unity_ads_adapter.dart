import 'package:ads_manager/src/controllers/app_open_ad_controller.dart';

import '../config/ads_config.dart';
import '../controllers/banner_ad_controller.dart';
import '../controllers/native_ad_controller.dart';
import '../controllers/interstitial_ad_controller.dart';
import '../controllers/rewarded_ad_controller.dart';

class UnityAdsAdapter /* implements IAdsAdapter */ {
  bool _inited = false;
  final String gameId;

  UnityAdsAdapter(this.gameId);

  Future<void> initialize(AdsConfig config) async {
    if (_inited) return;
    // await UnityAds.init(gameId: gameId);  // pseudo
    _inited = true;
  }

  Future<void> showConsentFormIfRequired() async {}

  Future<BannerAdController> createBanner(
    String adUnitId, {
    required int width,
    required int height,
  }) async {
    // Create a UnityBannerAdController (you must implement it)
    throw UnimplementedError(
      'Implement Unity controllers similar to Google ones.',
    );
  }

  Future<NativeAdController> createNative(
    String adUnitId, {
    required int width,
    required int height,
  }) async {
    throw UnimplementedError();
  }

  Future<InterstitialAdController> createInterstitial(String adUnitId) async {
    throw UnimplementedError();
  }

  Future<RewardedAdController> createRewarded(String adUnitId) async {
    throw UnimplementedError();
  }

  Future<AppOpenAdController> createAppOpen(String adUnitId) async {
    throw UnimplementedError();
  }
}
