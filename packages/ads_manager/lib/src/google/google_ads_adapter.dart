import 'dart:developer';
import 'package:ads_manager/src/ads_adapter.dart';
import 'package:ads_manager/src/config/ads_config.dart';
import 'package:ads_manager/src/controllers/app_open_ad_controller.dart';
import 'package:ads_manager/src/controllers/banner_ad_controller.dart';
import 'package:ads_manager/src/controllers/interstitial_ad_controller.dart';
import 'package:ads_manager/src/controllers/native_ad_controller.dart';
import 'package:ads_manager/src/controllers/rewarded_ad_controller.dart';
import 'package:ads_manager/src/google/google_app_open_ad_controller.dart';
import 'package:ads_manager/src/google/google_banner_ad_controller.dart';
import 'package:ads_manager/src/google/google_interstitial_ad_controller.dart';
import 'package:ads_manager/src/google/google_native_ad_controller.dart';
import 'package:ads_manager/src/google/google_rewarded_ad_controller.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleAdsAdapter implements IAdsAdapter {
  bool _inited = false;

  @override
  Future<void> initialize(AdsConfig config) async {
    if (_inited) return;
    log("MobileAds.instance.initialize() called!!!");
    await MobileAds.instance.initialize();
    // if (Platform.isAndroid) {
    // NativeAdFactory exampleFactory = ListTileNativeFactory();
    // MobileAds.instance.registerNativeAdFactory('listTile', exampleFactory);
    // }
    _inited = true;
    log("MobileAds.instance.initialize() completed!!!");
  }

  @override
  Future<void> showConsentFormIfRequired() async {
    // implement UMP consent flow via platform channels or native integration if needed
  }

  @override
  Future<BannerAdController> createBanner(
    String adUnitId, {
    required int width,
    required int height,
  }) async {
    final size = AdSize(width: width, height: height);
    final ctrl = GoogleBannerAdController(adUnitId: adUnitId, size: size);
    await ctrl.load();
    return ctrl;
  }

  @override
  Future<NativeAdController> createNative(
    String adUnitId, {
    String? factoryId,
  }) async {
    final ctrl = GoogleNativeAdController(
      adUnitId: adUnitId,
      factoryId: factoryId,
    );
    await ctrl.load();
    return ctrl;
  }

  @override
  Future<InterstitialAdController> createInterstitial(String adUnitId) async {
    final ctrl = GoogleInterstitialAdController(adUnitId: adUnitId);
    await ctrl.load();
    return ctrl;
  }

  @override
  Future<RewardedAdController> createRewarded(String adUnitId) async {
    final ctrl = GoogleRewardedAdController(adUnitId: adUnitId);
    await ctrl.load();
    return ctrl;
  }

  @override
  Future<AppOpenAdController> createAppOpen(String adUnitId) async {
    final ctrl = GoogleAppOpenAdController(adUnitId: adUnitId);
    await ctrl.load();
    return ctrl;
  }
}
