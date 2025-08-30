import 'dart:async';

import 'package:ads_manager/src/controllers/interstitial_ad_controller.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleInterstitialAdController implements InterstitialAdController {
  final String adUnitId;
  InterstitialAd? _ad;
  bool _isLoaded = false;

  GoogleInterstitialAdController({required this.adUnitId});

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> load() {
    final completer = Completer<void>();
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoaded = true;
          completer.complete();
        },
        onAdFailedToLoad: (err) => completer.completeError(err),
      ),
    );
    return completer.future;
  }

  @override
  Future<void> show() {
    if (_ad == null) return Future.value();
    final completer = Completer<void>();
    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _isLoaded = false;
        completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _ad = null;
        _isLoaded = false;
        completer.completeError(error);
      },
    );
    _ad!.show();
    return completer.future;
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
  }
}
