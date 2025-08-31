import 'dart:async';
import 'dart:collection';

import 'package:ads_manager/src/ads_adapter.dart';
import 'package:ads_manager/src/config/ads_config.dart';
import 'package:ads_manager/src/controllers/app_open_ad_controller.dart';
import 'package:ads_manager/src/controllers/banner_ad_controller.dart';
import 'package:ads_manager/src/controllers/dummy/dummy_app_open_ad_controller.dart';
import 'package:ads_manager/src/controllers/dummy/dummy_banner_ad_controller.dart';
import 'package:ads_manager/src/controllers/dummy/dummy_interstitial_ad_controller.dart';
import 'package:ads_manager/src/controllers/dummy/dummy_native_ad_controller.dart';
import 'package:ads_manager/src/controllers/dummy/dummy_rewarded_ad_controller.dart';
import 'package:ads_manager/src/controllers/interstitial_ad_controller.dart';
import 'package:ads_manager/src/controllers/native_ad_controller.dart';
import 'package:ads_manager/src/controllers/rewarded_ad_controller.dart';

class AdsRepository {
  final IAdsAdapter _adapter;
  final AdsConfig _config;

  final Queue<Function> _queue = Queue();
  bool _initialized = false;
  bool _initStarted = false;

  AdsRepository(this._adapter, this._config) {
    // start initialization non-blocking
    initialize();
  }

  /// Start init but don't block caller (unawaited)
  void initialize() {
    if (_initStarted || !_config.enabled) return;
    _initStarted = true;
    unawaited(_initInternal());
  }

  Future<void> _initInternal() async {
    try {
      await _adapter.initialize(_config);
      _initialized = true;
      while (_queue.isNotEmpty) {
        final task = _queue.removeFirst();
        task();
      }
    } catch (e) {
      while (_queue.isNotEmpty) {
        final t = _queue.removeFirst();
        try {
          t();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<T> _enqueue<T>(
    Future<T> Function() action, {
    required T Function() disabledFactory,
  }) {
    final completer = Completer<T>();

    if (!_config.enabled) {
      // ads disabled → return dummy controller immediately
      completer.complete(disabledFactory());
      return completer.future;
    }

    void wrapped() {
      action().then(completer.complete).catchError(completer.completeError);
    }

    if (_initialized) {
      wrapped();
    } else {
      _queue.add(wrapped);
    }

    return completer.future;
  }

  // Public API
  Future<BannerAdController> loadBanner(
    String adUnitId, {
    required int width,
    required int height,
  }) {
    return _enqueue(
      () => _adapter.createBanner(adUnitId, width: width, height: height),
      disabledFactory: () => DummyBannerAdController(),
    );
  }

  Future<NativeAdController> loadNative(String adUnitId, {String? factoryId}) {
    return _enqueue(
      () => _adapter.createNative(adUnitId, factoryId: factoryId),
      disabledFactory: () => DummyNativeAdController(),
    );
  }

  Future<InterstitialAdController> loadInterstitial(String adUnitId) {
    return _enqueue(
      () => _adapter.createInterstitial(adUnitId),
      disabledFactory: () => DummyInterstitialAdController(),
    );
  }

  Future<RewardedAdController> loadRewarded(String adUnitId) {
    return _enqueue(
      () => _adapter.createRewarded(adUnitId),
      disabledFactory: () => DummyRewardedAdController(),
    );
  }

  Future<AppOpenAdController> loadAppOpen(String adUnitId) {
    return _enqueue(
      () => _adapter.createAppOpen(adUnitId),
      disabledFactory: () => DummyAppOpenAdController(),
    );
  }

  Future<void> showConsentFormIfRequired() {
    if (!_config.enabled) return Future.value();
    return _enqueue(
      () => _adapter.showConsentFormIfRequired(),
      disabledFactory: () => Future.value(),
    );
  }
}
