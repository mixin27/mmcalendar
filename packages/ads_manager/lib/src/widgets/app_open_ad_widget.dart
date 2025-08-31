import 'package:ads_manager/ads_manager.dart';
import 'package:flutter/material.dart';

class AppOpenAdWidget extends StatefulWidget {
  final String adUnitId;
  final AdsRepository adsRepo;
  final Widget child;

  const AppOpenAdWidget({
    super.key,
    required this.adUnitId,
    required this.adsRepo,
    required this.child,
  });

  @override
  State<AppOpenAdWidget> createState() => _AppOpenAdWidgetState();
}

class _AppOpenAdWidgetState extends State<AppOpenAdWidget> {
  AppLifecycleReactor? lifecycleReactor;
  AppOpenAdController? appOpenAdController;

  @override
  void initState() {
    super.initState();
    _initAppOpen();
  }

  Future<void> _initAppOpen() async {
    try {
      appOpenAdController = await widget.adsRepo.loadAppOpen(widget.adUnitId);

      // Attach lifecycle observer to show ad on foreground
      lifecycleReactor = AppLifecycleReactor(appOpenAd: appOpenAdController!);
    } catch (e) {
      debugPrint('AppOpenAd load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    lifecycleReactor?.dispose();
    appOpenAdController?.dispose();
    super.dispose();
  }
}
