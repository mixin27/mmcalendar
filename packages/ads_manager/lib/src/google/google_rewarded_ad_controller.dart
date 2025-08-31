import 'dart:async';

import 'package:ads_manager/src/config/ads_config.dart';
import 'package:ads_manager/src/controllers/rewarded_ad_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleRewardedAdController implements RewardedAdController {
  final String adUnitId;
  final AdsConfig config;

  RewardedAd? _ad;
  bool _isLoaded = false;

  GoogleRewardedAdController({required this.adUnitId, required this.config});

  @override
  bool get isLoaded => _isLoaded;

  @override
  bool get isEnabled => config.enabled;

  @override
  Future<void> load() async {
    if (!isEnabled) {
      debugPrint("Ads are disabled, skipping rewarded ad load.");
      return;
    }

    final completer = Completer<void>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
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
  Future<void> showRewarded(
    void Function(num amount, String type) onUserEarnedReward,
  ) async {
    if (!isEnabled) {
      debugPrint("Ads disabled: skipping show()");
      return;
    }

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
    _ad!.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward(reward.amount.toInt(), reward.type);
      },
    );
    return completer.future;
  }

  @override
  Future<void> show() async {
    // fallback → just call showRewarded with a no-op callback
    if (_ad != null) {
      await showRewarded((_, __) {});
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
  }
}
