import 'package:ads_manager/src/controllers/native_ad_controller.dart';
import 'package:ads_manager/src/repository/ads_repository.dart';
import 'package:flutter/material.dart';

class NativeAdViewWidget extends StatefulWidget {
  final String adUnitId;
  final String? factoryId;
  final AdsRepository adsRepo;
  final double height;

  const NativeAdViewWidget({
    super.key,
    required this.adUnitId,
    this.factoryId,
    required this.adsRepo,
    this.height = 120,
  });

  @override
  State<NativeAdViewWidget> createState() => _NativeAdViewWidgetState();
}

class _NativeAdViewWidgetState extends State<NativeAdViewWidget> {
  NativeAdController? controller;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  Future<void> _loadNativeAd() async {
    try {
      controller = await widget.adsRepo.loadNative(
        widget.adUnitId,
        factoryId: widget.factoryId,
      );
      await controller?.load();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('NativeAd load failed: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.isLoaded) {
      return const SizedBox.shrink();
    }

    return SizedBox(height: widget.height, child: controller!.widget);
  }
}
