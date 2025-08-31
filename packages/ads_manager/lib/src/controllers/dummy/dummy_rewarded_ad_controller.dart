import 'package:ads_manager/src/controllers/rewarded_ad_controller.dart';

class DummyRewardedAdController implements RewardedAdController {
  @override
  void dispose() {}

  @override
  bool get isEnabled => false;

  @override
  bool get isLoaded => false;

  @override
  Future<void> load() async {}

  @override
  Future<void> show() async {}

  @override
  Future<void> showRewarded(
    void Function(num p1, String p2) onUserEarnedReward,
  ) async {}
}
