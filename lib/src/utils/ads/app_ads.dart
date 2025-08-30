import 'package:flutter/foundation.dart';

class AppAds {
  static final _isDebug = kDebugMode || kProfileMode;

  static Future<void> init() async {}

  static String homeBannerAdUnitId = _isDebug
      ? "ca-app-pub-3940256099942544/9214589741"
      : 'ca-app-pub-7567997114394639/3249073381';

  static String homeInterAdUnitId = _isDebug
      ? "ca-app-pub-3940256099942544/1033173712"
      : 'ca-app-pub-7567997114394639/2865930008';

  static String homeNativeAdUnitId = _isDebug
      ? "ca-app-pub-3940256099942544/2247696110"
      : 'ca-app-pub-7567997114394639/4179011671';

  static String appOpenAdUnitId = _isDebug
      ? "ca-app-pub-3940256099942544/9257395921"
      : 'ca-app-pub-7567997114394639/3754944612';
}
