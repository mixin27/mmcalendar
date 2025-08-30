import 'package:ads_manager/src/controllers/app_open_ad_controller.dart';
import 'package:flutter/widgets.dart';

/// Listens for app foreground events and shows app open ads.
class AppLifecycleReactor with WidgetsBindingObserver {
  final AppOpenAdController? appOpenAd;
  bool _firstLaunchShown = false;

  AppLifecycleReactor({this.appOpenAd}) {
    WidgetsBinding.instance.addObserver(this);

    // Immediately attempt to show if loaded and first launch
    (appOpenAd as dynamic).onAdLoadedCallback = () {
      if (!_firstLaunchShown &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _showAd();
        _firstLaunchShown = true;
      }
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showAd();
    }
  }

  void _showAd() async {
    if ((appOpenAd as dynamic).isLoaded) {
      try {
        await appOpenAd?.show();
      } catch (e) {
        debugPrint('Failed to show AppOpenAd: $e');
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
