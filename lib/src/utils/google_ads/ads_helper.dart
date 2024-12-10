// ignore_for_file: unused_field

import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mmcalendar/src/utils/dialogs.dart';
import 'package:mmcalendar/src/utils/remote_config/app_remote_config.dart';

const _isDebug = kDebugMode || kProfileMode;

class AdsHelper {
  // for initializing ads sdk
  static Future<void> initAds() async {
    await MobileAds.instance.initialize();
  }

  static String get nativeAdUnit => _isDebug
      ? "ca-app-pub-3940256099942544/2247696110"
      : 'ca-app-pub-7567997114394639/4179011671';

  static String get bannerAdUnit => _isDebug
      ? "ca-app-pub-3940256099942544/9214589741"
      : 'ca-app-pub-7567997114394639/3249073381';

  static String get interstitialAdUnit => _isDebug
      ? "ca-app-pub-3940256099942544/1033173712"
      : 'ca-app-pub-7567997114394639/2865930008';

  static String get appOpenAdUnit => _isDebug
      ? "ca-app-pub-3940256099942544/9257395921"
      : 'ca-app-pub-7567997114394639/3754944612';

  static InterstitialAd? _interstitialAd;
  static bool _interstitialAdLoaded = false;

  static NativeAd? _nativeAd;
  static bool _nativeAdLoaded = false;

  static BannerAd? _bannerAd;
  static bool _bannerAdLoaded = false;

  //*****************Interstitial Ad******************
  static void precacheInterstitialAd() {
    log('Precache Interstitial Ad - Id: $interstitialAdUnit');

    if (AppRemoteConfig.hideAds) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _resetInterstitialAd();
              precacheInterstitialAd();
            },
          );
          _interstitialAd = ad;
          _interstitialAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _resetInterstitialAd();
          log('Failed to load an interstitial ad: ${error.message}');
        },
      ),
    );
  }

  static void _resetInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _interstitialAdLoaded = false;
  }

  static void showInterstitialAd(
    BuildContext context, {
    required VoidCallback onComplete,
  }) {
    if (AppRemoteConfig.hideAds) {
      onComplete();
      return;
    }

    if (_interstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd?.show();
      onComplete();
      return;
    }

    showLoadingDialog(context);

    InterstitialAd.load(
      adUnitId: interstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          //ad listener
          ad.fullScreenContentCallback =
              FullScreenContentCallback(onAdDismissedFullScreenContent: (ad) {
            onComplete();
            _resetInterstitialAd();
            precacheInterstitialAd();
          });
          Navigator.pop(context);
          ad.show();
        },
        onAdFailedToLoad: (err) {
          Navigator.pop(context);
          log('Failed to load an interstitial ad: ${err.message}');
          onComplete();
        },
      ),
    );
  }

  //*****************Native Ad******************
  static void precacheNativeAd() {
    if (AppRemoteConfig.hideAds) return;

    _nativeAd = NativeAd(
      adUnitId: nativeAdUnit,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          log('$NativeAd loaded.');
          _nativeAdLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          _resetNativeAd();
          log('$NativeAd failed to load: $error');
        },
      ),
      request: const AdRequest(),
      // Styling
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
    )..load();
  }

  static void _resetNativeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _nativeAdLoaded = false;
  }

  static NativeAd? loadNativeAd({
    VoidCallback? onLoaded,
    TemplateType type = TemplateType.medium,
  }) {
    if (AppRemoteConfig.hideAds) return null;

    // if (_nativeAdLoaded && _nativeAd != null) {
    //   onLoaded?.call();
    //   return _nativeAd;
    // }

    return NativeAd(
      adUnitId: nativeAdUnit,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          log('$NativeAd loaded.');
          onLoaded?.call();
          // _resetNativeAd();
          // precacheNativeAd();
        },
        onAdFailedToLoad: (ad, error) {
          // _resetNativeAd();
          log('$NativeAd failed to load: $error');
        },
      ),
      request: const AdRequest(),
      // Styling
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: type,
      ),
    )..load();
  }

  // **************** Banner Ad*******************
  static void precacheBannerAd() {
    if (AppRemoteConfig.hideAds) return;

    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: bannerAdUnit,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          log('$NativeAd loaded.');
          _bannerAdLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          _resetBannerAd();
          log('$BannerAd failed to load: $error');
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  static void _resetBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _bannerAdLoaded = false;
  }

  static BannerAd? loadBannerAd({VoidCallback? onLoaded}) {
    if (AppRemoteConfig.hideAds) return null;

    // if (_bannerAdLoaded && _bannerAd != null) {
    //   onLoaded?.call();
    //   return _bannerAd;
    // }

    return BannerAd(
      size: AdSize.banner,
      adUnitId: bannerAdUnit,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          log('$BannerAd loaded.');
          onLoaded?.call();
          // _resetBannerAd();
          // precacheBannerAd();
        },
        onAdFailedToLoad: (ad, error) {
          // _resetBannerAd();
          log('$BannerAd failed to load: $error');
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  // ****************** Consent ****************************
  static showConsentUMP() {
    log("showConsentUMP called");
    if (AppRemoteConfig.hideAds) return;

    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          loadForm();
        }
      },
      (FormError error) {
        // Handle the error
      },
    );
  }

  static void loadForm() {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        var status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show(
            (FormError? formError) {
              loadForm();
            },
          );
        }
      },
      (formError) {
        // Handle the error
      },
    );
  }
}
