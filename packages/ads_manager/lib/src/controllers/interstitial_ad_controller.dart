import 'base_ad_controller.dart';

abstract class InterstitialAdController extends BaseAdController {
  @override
  Future<void> show(); // shows the full-screen ad
}
