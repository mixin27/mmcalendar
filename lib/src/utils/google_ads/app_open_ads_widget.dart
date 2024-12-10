import 'package:flutter/material.dart';
import 'package:mmcalendar/src/utils/remote_config/app_remote_config.dart';

import 'ads_helper.dart';
import 'app_lifecycle_reactor.dart';
import 'app_open_ads_manager.dart';

class AppOpenAdsWidget extends StatefulWidget {
  const AppOpenAdsWidget({super.key, required this.child});

  final Widget child;

  @override
  State<AppOpenAdsWidget> createState() => _AppOpenAdsWidgetState();
}

class _AppOpenAdsWidgetState extends State<AppOpenAdsWidget> {
  late AppLifecycleReactor _appLifecycleReactor;
  final AppOpenAdsManager _appOpenAdManager = AppOpenAdsManager();

  @override
  void initState() {
    super.initState();

    AdsHelper.showConsentUMP();

    if (AppRemoteConfig.hideAds) return;

    _appOpenAdManager.loadAd(onAdLoaded: () {
      _appOpenAdManager.showAdIfAvailable();
    });

    _appLifecycleReactor = AppLifecycleReactor(
      appOpenAdManager: _appOpenAdManager,
    );
    _appLifecycleReactor.listenToAppStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
