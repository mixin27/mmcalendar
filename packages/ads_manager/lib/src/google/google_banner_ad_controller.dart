import 'dart:async';

import 'package:ads_manager/src/config/ads_config.dart';
import 'package:ads_manager/src/controllers/banner_ad_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleBannerAdController implements BannerAdController {
  final String adUnitId;
  final AdSize size;
  final AdsConfig config;

  BannerAd? _ad;
  bool _isLoaded = false;

  GoogleBannerAdController({
    required this.adUnitId,
    required this.size,
    required this.config,
  });

  @override
  bool get isLoaded => _isLoaded;

  @override
  bool get isEnabled => config.enabled;

  @override
  Future<void> load() async {
    if (!isEnabled) {
      debugPrint("Ads are disabled, skipping banner ad load.");
      return;
    }

    final completer = Completer<void>();
    _ad = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isLoaded = true;
          completer.complete();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          completer.completeError(error);
        },
      ),
    );
    _ad!.load();
    return completer.future;
  }

  @override
  Future<void> show() async {
    if (!isEnabled) {
      debugPrint("Ads disabled: skipping show()");
      return;
    }
    // Banner is rendered by widget — nothing to do here.
  }

  @override
  Widget get widget {
    if (!isEnabled) return const SizedBox.shrink();
    if (_ad == null || !_isLoaded) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
  }
}
