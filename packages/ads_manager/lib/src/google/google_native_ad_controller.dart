import 'dart:async';

import 'package:ads_manager/src/config/ads_config.dart';
import 'package:ads_manager/src/controllers/native_ad_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleNativeAdController implements NativeAdController {
  final String adUnitId;
  final String? factoryId;
  final AdsConfig config;

  NativeAd? _ad;
  bool _isLoaded = false;

  GoogleNativeAdController({
    required this.adUnitId,
    this.factoryId,
    required this.config,
  });

  @override
  bool get isLoaded => _isLoaded;

  @override
  bool get isEnabled => config.enabled;

  @override
  Future<void> load() async {
    if (!isEnabled) {
      debugPrint("Ads are disabled, skipping native ad load.");
      return;
    }

    await loadWithTemplate(
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
    );
  }

  @override
  Future<void> loadWithTemplate({
    required NativeTemplateStyle nativeTemplateStyle,
  }) async {
    final completer = Completer<void>();
    _ad = NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      request: const AdRequest(),

      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isLoaded = true;
          completer.complete();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          completer.completeError(error);
        },
      ),
      nativeTemplateStyle: nativeTemplateStyle,
    );
    _ad!.load();
    return completer.future;
  }

  @override
  Widget get widget {
    if (!isEnabled) return const SizedBox.shrink();
    if (_ad == null || !_isLoaded) return const SizedBox.shrink();

    return SizedBox(
      height: 120, // size depends on your native layout
      child: AdWidget(ad: _ad!),
    );
  }

  @override
  Future<void> show() async {
    if (!isEnabled) {
      debugPrint("Ads disabled: skipping show()");
      return;
    }
    // Native ad is shown by embedding widget
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
  }
}
