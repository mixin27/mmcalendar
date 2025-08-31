import 'base_ad_controller.dart';

abstract class RewardedAdController extends BaseAdController {
  Future<void> showRewarded(void Function(num, String) onUserEarnedReward);
}
