import 'package:ads_manager/src/controllers/banner_ad_controller.dart';
import 'package:flutter/widgets.dart';

class BannerAdView extends StatelessWidget {
  final Future<BannerAdController> bannerControllerFuture;
  final double height;

  const BannerAdView({
    super.key,
    required this.bannerControllerFuture,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BannerAdController>(
      future: bannerControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final controller = snapshot.data!;
        return SizedBox(height: height, child: controller.widget);
      },
    );
  }
}
