import 'package:ads_manager/src/config/ads_config.dart';
import 'package:ads_manager/src/controllers/app_open_ad_controller.dart';
import 'package:ads_manager/src/controllers/banner_ad_controller.dart';
import 'package:ads_manager/src/controllers/interstitial_ad_controller.dart';
import 'package:ads_manager/src/controllers/native_ad_controller.dart';
import 'package:ads_manager/src/controllers/rewarded_ad_controller.dart';

abstract class IAdsAdapter {
  Future<void> initialize(AdsConfig config);
  Future<void> showConsentFormIfRequired();

  Future<BannerAdController> createBanner(
    String adUnitId, {
    required int width,
    required int height,
  });
  Future<NativeAdController> createNative(String adUnitId, {String? factoryId});
  Future<InterstitialAdController> createInterstitial(String adUnitId);
  Future<RewardedAdController> createRewarded(String adUnitId);
  Future<AppOpenAdController> createAppOpen(String adUnitId);
}
