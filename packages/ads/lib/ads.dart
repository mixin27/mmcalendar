import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppAdsManager {
  static Future<void> initialize() async {
    unawaited(MobileAds.instance.initialize());
  }
}
