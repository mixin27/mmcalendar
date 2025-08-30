import 'dart:async';

import 'package:ads_manager/src/controllers/app_open_ad_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleAppOpenAdController implements AppOpenAdController {
  final String adUnitId;
  AppOpenAd? _ad;
  bool _isLoaded = false;

  /// Callback when ad finishes loading
  VoidCallback? onAdLoadedCallback;

  GoogleAppOpenAdController({required this.adUnitId});

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> load() {
    final completer = Completer<void>();
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoaded = true;
          completer.complete();
          onAdLoadedCallback?.call(); // 🔹 trigger callback

          // Attach FullScreenContentCallback to reload automatically
          _ad!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              _isLoaded = false;
              load(); // 🔄 reload automatically
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _ad = null;
              _isLoaded = false;
              load(); // 🔄 reload automatically
            },
          );
        },
        onAdFailedToLoad: (err) {
          _ad = null;
          _isLoaded = false;
          completer.completeError(err);
          // Optionally retry after a delay
          Future.delayed(const Duration(seconds: 5), load);
        },
      ),
    );
    return completer.future;
  }

  @override
  Future<void> show() async {
    if (_ad == null) return;
    await _ad!.show();
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
  }
}
